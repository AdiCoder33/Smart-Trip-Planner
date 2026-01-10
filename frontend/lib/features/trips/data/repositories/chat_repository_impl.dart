import '../../../../core/errors/error_mapper.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/chat_socket_event.dart';
import '../../domain/repositories/chat_repository.dart';
import '../datasources/chat_local_data_source.dart';
import '../datasources/chat_remote_data_source.dart';
import '../models/chat_message_model.dart';

class ChatRepositoryImpl implements ChatRepository {
  final ChatRemoteDataSource remoteDataSource;
  final ChatLocalDataSource localDataSource;

  const ChatRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<List<ChatMessageEntity>> getCachedMessages(String tripId) async {
    return localDataSource.getMessages(tripId);
  }

  @override
  Future<List<ChatMessageEntity>> getMessages({
    required String tripId,
    int limit = 50,
    DateTime? before,
  }) async {
    try {
      final messages = await remoteDataSource.fetchMessages(
        tripId: tripId,
        limit: limit,
        before: before,
      );
      await localDataSource.cacheMessages(tripId, messages);
      return messages;
    } catch (error) {
      throw mapDioError(error);
    }
  }

  @override
  Future<ChatMessageEntity> sendMessageRest({
    required String tripId,
    required String content,
    required String clientId,
  }) async {
    try {
      final message = await remoteDataSource.sendMessageRest(
        tripId: tripId,
        content: content,
        clientId: clientId,
      );
      await localDataSource.upsertMessage(message);
      return message;
    } catch (error) {
      throw mapDioError(error);
    }
  }

  @override
  Future<void> cacheLocalMessages(String tripId, List<ChatMessageEntity> messages) async {
    final models = messages.map(ChatMessageModel.fromEntity).toList();
    await localDataSource.cacheMessages(tripId, models);
  }

  @override
  Future<void> upsertLocalMessage(ChatMessageEntity message) async {
    await localDataSource.upsertMessage(ChatMessageModel.fromEntity(message));
  }

  @override
  Future<Stream<ChatSocketEvent>> connect({required String tripId}) {
    return remoteDataSource.connect(tripId: tripId);
  }

  @override
  Future<void> sendMessageSocket({required String content, required String clientId}) {
    return remoteDataSource.sendMessageSocket(content: content, clientId: clientId);
  }

  @override
  Future<void> disconnect() async {
    await remoteDataSource.disconnect();
  }
}
