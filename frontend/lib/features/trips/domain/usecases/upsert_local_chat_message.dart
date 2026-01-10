import '../entities/chat_message.dart';
import '../repositories/chat_repository.dart';

class UpsertLocalChatMessage {
  final ChatRepository repository;

  const UpsertLocalChatMessage(this.repository);

  Future<void> call(ChatMessageEntity message) {
    return repository.upsertLocalMessage(message);
  }
}
