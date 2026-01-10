import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../../../core/config.dart';
import '../../../../core/storage/token_storage.dart';
import '../../domain/entities/chat_socket_event.dart';
import '../models/chat_message_model.dart';

class ChatRemoteDataSource {
  final Dio dio;
  final TokenStorage tokenStorage;
  WebSocketChannel? _channel;
  StreamController<ChatSocketEvent>? _controller;

  ChatRemoteDataSource(this.dio, this.tokenStorage);

  Future<List<ChatMessageModel>> fetchMessages({
    required String tripId,
    int limit = 50,
    DateTime? before,
  }) async {
    final params = <String, dynamic>{'limit': limit};
    if (before != null) {
      params['before'] = before.toIso8601String();
    }
    final response = await dio.get(
      '/api/trips/$tripId/chat/messages',
      queryParameters: params,
    );
    final data = response.data as List;
    return data.map((item) => ChatMessageModel.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<ChatMessageModel> sendMessageRest({
    required String tripId,
    required String content,
    required String clientId,
  }) async {
    final response = await dio.post(
      '/api/trips/$tripId/chat/messages',
      data: {'content': content, 'client_id': clientId},
    );
    return ChatMessageModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Stream<ChatSocketEvent>> connect({required String tripId}) async {
    await disconnect();
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
      (event) {
        try {
          final payload = jsonDecode(event as String) as Map<String, dynamic>;
          final type = payload['type'] as String?;
          if (type == 'message') {
            final message = ChatMessageModel.fromJson(
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

  void sendMessageSocket({required String content, required String clientId}) {
    if (_channel == null) {
      throw Exception('Socket not connected');
    }
    final payload = jsonEncode(
      {'type': 'message', 'content': content, 'client_id': clientId},
    );
    _channel!.sink.add(payload);
  }

  Future<void> disconnect() async {
    await _channel?.sink.close();
    _channel = null;
    await _controller?.close();
    _controller = null;
  }
}
