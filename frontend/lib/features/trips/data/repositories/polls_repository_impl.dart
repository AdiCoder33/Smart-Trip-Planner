import '../../../../core/errors/error_mapper.dart';
import '../../domain/entities/poll.dart';
import '../../domain/repositories/polls_repository.dart';
import '../datasources/polls_local_data_source.dart';
import '../datasources/polls_remote_data_source.dart';
import '../models/poll_model.dart';
import '../models/poll_option_model.dart';

class PollsRepositoryImpl implements PollsRepository {
  final PollsRemoteDataSource remoteDataSource;
  final PollsLocalDataSource localDataSource;

  const PollsRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<List<PollEntity>> getCachedPolls(String tripId) async {
    return localDataSource.getPolls(tripId);
  }

  @override
  Future<List<PollEntity>> getPolls(String tripId) async {
    try {
      final polls = await remoteDataSource.fetchPolls(tripId);
      await localDataSource.cachePolls(tripId, polls);
      return polls;
    } catch (error) {
      throw mapDioError(error);
    }
  }

  @override
  Future<PollEntity> createPoll({
    required String tripId,
    required String question,
    required List<String> options,
  }) async {
    try {
      final poll = await remoteDataSource.createPoll(
        tripId: tripId,
        question: question,
        options: options,
      );
      await localDataSource.upsertPoll(poll);
      return poll;
    } catch (error) {
      throw mapDioError(error);
    }
  }

  @override
  Future<PollEntity> vote({
    required String pollId,
    required String optionId,
    required String tripId,
  }) async {
    try {
      final poll = await remoteDataSource.vote(
        pollId: pollId,
        optionId: optionId,
        tripId: tripId,
      );
      await localDataSource.upsertPoll(poll);
      return poll;
    } catch (error) {
      throw mapDioError(error);
    }
  }

  @override
  Future<PollEntity> updatePoll({
    required String pollId,
    required String tripId,
    required String question,
    required List<String> options,
  }) async {
    try {
      final poll = await remoteDataSource.updatePoll(
        pollId: pollId,
        tripId: tripId,
        question: question,
        options: options,
      );
      await localDataSource.upsertPoll(poll);
      return poll;
    } catch (error) {
      throw mapDioError(error);
    }
  }

  @override
  Future<void> deletePoll({required String pollId}) async {
    try {
      await remoteDataSource.deletePoll(pollId: pollId);
      await localDataSource.deletePoll(pollId);
    } catch (error) {
      throw mapDioError(error);
    }
  }

  @override
  Future<void> cacheLocalPolls(String tripId, List<PollEntity> polls) async {
    final models = polls.map(_toModel).toList();
    await localDataSource.cachePolls(tripId, models);
  }

  @override
  Future<void> upsertLocalPoll(PollEntity poll) async {
    await localDataSource.upsertPoll(_toModel(poll));
  }

  @override
  Future<void> deleteLocalPoll(String pollId) async {
    await localDataSource.deletePoll(pollId);
  }

  PollModel _toModel(PollEntity poll) {
    if (poll is PollModel) {
      return poll;
    }
    final options = poll.options
        .map((option) => option is PollOptionModel
            ? option
            : PollOptionModel(
                id: option.id,
                text: option.text,
                voteCount: option.voteCount,
              ))
        .toList();
    return PollModel(
      id: poll.id,
      tripId: poll.tripId,
      question: poll.question,
      isActive: poll.isActive,
      options: options,
      userVoteOptionId: poll.userVoteOptionId,
      createdAt: poll.createdAt,
      updatedAt: poll.updatedAt,
      isPending: poll.isPending,
    );
  }
}
