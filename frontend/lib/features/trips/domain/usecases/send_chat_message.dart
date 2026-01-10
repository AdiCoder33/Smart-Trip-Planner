import '../entities/chat_message.dart';
import '../repositories/chat_repository.dart';

class SendChatMessage {
  final ChatRepository repository;

  const SendChatMessage(this.repository);

  Future<ChatMessageEntity> call({
    required String tripId,
    required String content,
    required String clientId,
  }) {
    return repository.sendMessageRest(
      tripId: tripId,
      content: content,
      clientId: clientId,
    );
  }
}
