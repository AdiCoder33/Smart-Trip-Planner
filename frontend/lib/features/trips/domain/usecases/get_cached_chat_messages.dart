import '../entities/chat_message.dart';
import '../repositories/chat_repository.dart';

class GetCachedChatMessages {
  final ChatRepository repository;

  const GetCachedChatMessages(this.repository);

  Future<List<ChatMessageEntity>> call(String tripId) {
    return repository.getCachedMessages(tripId);
  }
}
