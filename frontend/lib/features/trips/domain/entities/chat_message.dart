import 'package:equatable/equatable.dart';

class ChatMessageEntity extends Equatable {
  final String id;
  final String tripId;
  final String senderId;
  final String? senderName;
  final String content;
  final DateTime createdAt;
  final String? clientId;
  final bool isPending;

  const ChatMessageEntity({
    required this.id,
    required this.tripId,
    required this.senderId,
    required this.content,
    required this.createdAt,
    this.senderName,
    this.clientId,
    this.isPending = false,
  });

  ChatMessageEntity copyWith({
    String? id,
    String? tripId,
    String? senderId,
    String? senderName,
    String? content,
    DateTime? createdAt,
    String? clientId,
    bool? isPending,
  }) {
    return ChatMessageEntity(
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

  @override
  List<Object?> get props => [
        id,
        tripId,
        senderId,
        senderName,
        content,
        createdAt,
        clientId,
        isPending,
      ];
}
