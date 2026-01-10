import 'chat_message.dart';

enum ChatSocketEventType { message, error }

class ChatSocketEvent {
  final ChatSocketEventType type;
  final ChatMessageEntity? message;
  final String? errorMessage;

  const ChatSocketEvent.message(this.message)
      : type = ChatSocketEventType.message,
        errorMessage = null;

  const ChatSocketEvent.error(this.errorMessage)
      : type = ChatSocketEventType.error,
        message = null;
}
