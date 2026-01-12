import '../entities/poll.dart';

abstract class PollsRepository {
  Future<List<PollEntity>> getCachedPolls(String tripId);
  Future<List<PollEntity>> getPolls(String tripId);
  Future<PollEntity> createPoll({
    required String tripId,
    required String question,
    required List<String> options,
  });
  Future<PollEntity> vote({
    required String pollId,
    required String optionId,
    required String tripId,
  });
  Future<PollEntity> updatePoll({
    required String pollId,
    required String tripId,
    required String question,
    required List<String> options,
  });
  Future<void> deletePoll({required String pollId});
  Future<void> cacheLocalPolls(String tripId, List<PollEntity> polls);
  Future<void> upsertLocalPoll(PollEntity poll);
  Future<void> deleteLocalPoll(String pollId);
}
