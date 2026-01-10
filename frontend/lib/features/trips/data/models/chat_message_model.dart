import 'package:hive/hive.dart';

import '../../domain/entities/chat_message.dart';

class ChatMessageModel extends ChatMessageEntity {
  const ChatMessageModel({
    required super.id,
    required super.tripId,
    required super.senderId,
    required super.content,
    required super.createdAt,
    super.senderName,
    super.clientId,
    super.isPending = false,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    final sender = json['sender'] as Map<String, dynamic>;
    return ChatMessageModel(
      id: json['id'] as String,
      tripId: json['trip_id'] as String,
      senderId: sender['id'] as String,
      senderName: sender['name'] as String?,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      clientId: json['client_id'] as String?,
    );
  }

  @override
  ChatMessageModel copyWith({
    String? id,
    String? tripId,
    String? senderId,
    String? senderName,
    String? content,
    DateTime? createdAt,
    String? clientId,
    bool? isPending,
  }) {
    return ChatMessageModel(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      clientId: clientId ?? this.clientId,
      isPending: isPending ?? this.isPending,
    );
  }

  static ChatMessageModel fromEntity(ChatMessageEntity entity) {
    if (entity is ChatMessageModel) {
      return entity;
    }
    return ChatMessageModel(
      id: entity.id,
      tripId: entity.tripId,
      senderId: entity.senderId,
      senderName: entity.senderName,
      content: entity.content,
      createdAt: entity.createdAt,
      clientId: entity.clientId,
      isPending: entity.isPending,
    );
  }
}

class ChatMessageModelAdapter extends TypeAdapter<ChatMessageModel> {
  @override
  final int typeId = 6;

  @override
  ChatMessageModel read(BinaryReader reader) {
    final id = reader.read() as String;
    final tripId = reader.read() as String;
    final senderId = reader.read() as String;
    final senderName = reader.read() as String?;
    final content = reader.read() as String;
    final createdAt = reader.read() as DateTime;
    final clientId = reader.read() as String?;
    final isPending = reader.read() as bool;
    return ChatMessageModel(
      id: id,
      tripId: tripId,
      senderId: senderId,
      senderName: senderName,
      content: content,
      createdAt: createdAt,
      clientId: clientId,
      isPending: isPending,
    );
  }

  @override
  void write(BinaryWriter writer, ChatMessageModel obj) {
    writer
      ..write(obj.id)
      ..write(obj.tripId)
      ..write(obj.senderId)
      ..write(obj.senderName)
      ..write(obj.content)
      ..write(obj.createdAt)
      ..write(obj.clientId)
      ..write(obj.isPending);
  }
}
