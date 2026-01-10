part of 'chat_bloc.dart';

enum ChatStatus { initial, loading, loaded, error }

enum ChatConnectionStatus { disconnected, connecting, connected, offline, error }

class ChatState extends Equatable {
  final ChatStatus status;
  final ChatConnectionStatus connectionStatus;
  final List<ChatMessageEntity> messages;
  final String? tripId;
  final String? message;
  final bool isSyncing;

  const ChatState({
    this.status = ChatStatus.initial,
    this.connectionStatus = ChatConnectionStatus.disconnected,
    this.messages = const [],
    this.tripId,
    this.message,
    this.isSyncing = false,
  });

  ChatState copyWith({
    ChatStatus? status,
    ChatConnectionStatus? connectionStatus,
    List<ChatMessageEntity>? messages,
    String? tripId,
    String? message,
    bool? isSyncing,
  }) {
    return ChatState(
      status: status ?? this.status,
      connectionStatus: connectionStatus ?? this.connectionStatus,
      messages: messages ?? this.messages,
      tripId: tripId ?? this.tripId,
      message: message,
      isSyncing: isSyncing ?? this.isSyncing,
    );
  }

  @override
  List<Object?> get props => [
        status,
        connectionStatus,
        messages,
        tripId,
        message,
        isSyncing,
      ];
}
