part of 'chat_bloc.dart';

abstract class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object?> get props => [];
}

class ChatStarted extends ChatEvent {
  final String tripId;

  const ChatStarted({required this.tripId});

  @override
  List<Object?> get props => [tripId];
}

class ChatSendRequested extends ChatEvent {
  final String content;
  final String senderId;
  final String? senderName;

  const ChatSendRequested({
    required this.content,
    required this.senderId,
    this.senderName,
  });

  @override
  List<Object?> get props => [content, senderId, senderName];
}

class ChatMessageReceived extends ChatEvent {
  final ChatMessageEntity message;

  const ChatMessageReceived({required this.message});

  @override
  List<Object?> get props => [message];
}

class ChatConnectionChanged extends ChatEvent {
  final ChatConnectionStatus status;
  final String? message;

  const ChatConnectionChanged({required this.status, this.message});

  @override
  List<Object?> get props => [status, message];
}

class ChatSyncRequested extends ChatEvent {
  final String tripId;

  const ChatSyncRequested({required this.tripId});

  @override
  List<Object?> get props => [tripId];
}
