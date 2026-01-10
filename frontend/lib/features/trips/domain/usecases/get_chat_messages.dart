import '../entities/chat_message.dart';
import '../repositories/chat_repository.dart';

class GetChatMessages {
  final ChatRepository repository;

  const GetChatMessages(this.repository);

  Future<List<ChatMessageEntity>> call({
    required String tripId,
    int limit = 50,
    DateTime? before,
  }) {
    return repository.getMessages(tripId: tripId, limit: limit, before: before);
  }
}
