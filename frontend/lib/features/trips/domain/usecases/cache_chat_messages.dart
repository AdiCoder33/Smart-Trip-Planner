import '../entities/chat_message.dart';
import '../repositories/chat_repository.dart';

class CacheChatMessages {
  final ChatRepository repository;

  const CacheChatMessages(this.repository);

  Future<void> call(String tripId, List<ChatMessageEntity> messages) {
    return repository.cacheLocalMessages(tripId, messages);
  }
}
