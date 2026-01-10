import '../entities/chat_message.dart';
import '../entities/chat_socket_event.dart';

abstract class ChatRepository {
  Future<List<ChatMessageEntity>> getCachedMessages(String tripId);
  Future<List<ChatMessageEntity>> getMessages({
    required String tripId,
    int limit,
    DateTime? before,
  });
  Future<ChatMessageEntity> sendMessageRest({
    required String tripId,
    required String content,
    required String clientId,
  });
  Future<void> cacheLocalMessages(String tripId, List<ChatMessageEntity> messages);
  Future<void> upsertLocalMessage(ChatMessageEntity message);
  Future<Stream<ChatSocketEvent>> connect({required String tripId});
  Future<void> sendMessageSocket({required String content, required String clientId});
  Future<void> disconnect();
}
