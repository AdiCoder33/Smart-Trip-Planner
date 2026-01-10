import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../../../core/config.dart';
import '../../../../core/crypto/chat_crypto.dart';
import '../../../../core/storage/chat_key_storage.dart';
import '../../../../core/storage/token_storage.dart';
import '../../domain/entities/chat_socket_event.dart';
import '../models/chat_message_model.dart';

class ChatRemoteDataSource {
  final Dio dio;
  final TokenStorage tokenStorage;
  final ChatKeyStorage keyStorage;
  final ChatCrypto chatCrypto;
  WebSocketChannel? _channel;
  StreamController<ChatSocketEvent>? _controller;
  String? _chatKey;
  int _chatKeyVersion = 1;
  String? _chatKeyTripId;

  ChatRemoteDataSource(
    this.dio,
    this.tokenStorage,
    this.keyStorage,
    this.chatCrypto,
  );

  Future<List<ChatMessageModel>> fetchMessages({
    required String tripId,
    int limit = 50,
    DateTime? before,
  }) async {
    await _ensureKey(tripId);
    final params = <String, dynamic>{'limit': limit};
    if (before != null) {
      params['before'] = before.toIso8601String();
    }
    final response = await dio.get(
      '/api/trips/$tripId/chat/messages',
      queryParameters: params,
    );
    final data = response.data as List;
    final messages = await Future.wait(
      data.map((item) => _decodeMessage(item as Map<String, dynamic>)),
    );
    return messages;
  }

  Future<ChatMessageModel> sendMessageRest({
    required String tripId,
    required String content,
    required String clientId,
  }) async {
    await _ensureKey(tripId);
    final encrypted = await _encryptContent(content);
    final response = await dio.post(
      '/api/trips/$tripId/chat/messages',
      data: {
        if (encrypted != null) 'encrypted_content': encrypted,
        if (encrypted != null) 'encryption_version': _chatKeyVersion,
        if (encrypted == null) 'content': content,
        'client_id': clientId,
      },
    );
    return _decodeMessage(response.data as Map<String, dynamic>);
  }

  Future<Stream<ChatSocketEvent>> connect({required String tripId}) async {
    await disconnect();
    await _ensureKey(tripId);
    final token = await tokenStorage.getAccessToken();
    if (token == null || token.isEmpty) {
      throw Exception('Missing access token');
    }
    final base = Uri.parse(ApiConfig.baseUrl);
    final wsScheme = base.scheme == 'https' ? 'wss' : 'ws';
    final uri = Uri(
      scheme: wsScheme,
      host: base.host,
      port: base.hasPort ? base.port : null,
      path: '/ws/trips/$tripId/chat/',
      queryParameters: {'token': token},
    );
    _channel = IOWebSocketChannel.connect(
      uri,
      headers: {'Origin': ApiConfig.baseUrl},
    );
    _controller = StreamController<ChatSocketEvent>.broadcast();

    _channel!.stream.listen(
      (event) async {
        try {
          final payload = jsonDecode(event as String) as Map<String, dynamic>;
          final type = payload['type'] as String?;
          if (type == 'message') {
            final message = await _decodeMessage(
              payload['message'] as Map<String, dynamic>,
            );
            _controller?.add(ChatSocketEvent.message(message));
          } else if (type == 'error') {
            final error = payload['error'] as Map<String, dynamic>?;
            _controller?.add(
              ChatSocketEvent.error(error?['message'] as String? ?? 'Unknown error'),
            );
          }
        } catch (_) {
          _controller?.add(const ChatSocketEvent.error('Malformed message'));
        }
      },
      onError: (error) {
        _controller?.add(ChatSocketEvent.error(error.toString()));
      },
      onDone: () {
        _controller?.close();
      },
    );

    try {
      await _channel!.ready;
    } catch (error) {
      await _channel?.sink.close();
      await _controller?.close();
      _channel = null;
      _controller = null;
      rethrow;
    }

    return _controller!.stream;
  }

  Future<void> sendMessageSocket({required String content, required String clientId}) async {
    if (_channel == null) {
      throw Exception('Socket not connected');
    }
    final encrypted = await _encryptContent(content);
    final payload = jsonEncode({
      'type': 'message',
      if (encrypted != null) 'encrypted_content': encrypted,
      if (encrypted != null) 'encryption_version': _chatKeyVersion,
      if (encrypted == null) 'content': content,
      'client_id': clientId,
    });
    _channel!.sink.add(payload);
  }

  Future<void> disconnect() async {
    await _channel?.sink.close();
    _channel = null;
    await _controller?.close();
    _controller = null;
  }

  Future<void> _ensureKey(String tripId) async {
    if (_chatKeyTripId != tripId) {
      _chatKey = null;
      _chatKeyTripId = null;
      _chatKeyVersion = 1;
    }
    if (_chatKey != null) {
      return;
    }
    final cached = await keyStorage.getKey(tripId);
    if (cached != null) {
      _chatKey = cached.key;
      _chatKeyVersion = cached.version;
      _chatKeyTripId = tripId;
      return;
    }
    final response = await dio.get('/api/trips/$tripId/chat/key');
    final data = response.data as Map<String, dynamic>;
    final key = data['key'] as String;
    final version = data['version'] as int? ?? 1;
    await keyStorage.saveKey(tripId, key, version);
    _chatKey = key;
    _chatKeyVersion = version;
    _chatKeyTripId = tripId;
  }

  Future<ChatMessageModel> _decodeMessage(Map<String, dynamic> json) async {
    String content = (json['content'] as String?) ?? '';
    final encrypted = json['encrypted_content'] as String?;
    if (encrypted != null && encrypted.isNotEmpty && _chatKey != null) {
      try {
        content = await chatCrypto.decrypt(encrypted, _chatKey!);
      } catch (_) {
        content = '[Encrypted message]';
      }
    }
    final sender = json['sender'] as Map<String, dynamic>;
    return ChatMessageModel(
      id: json['id'] as String,
      tripId: json['trip_id'] as String,
      senderId: sender['id'] as String,
      senderName: sender['name'] as String?,
      content: content,
      createdAt: DateTime.parse(json['created_at'] as String),
      clientId: json['client_id'] as String?,
    );
  }

  Future<String?> _encryptContent(String content) async {
    if (_chatKey == null) {
      return null;
    }
    return chatCrypto.encrypt(content, _chatKey!);
  }
}
