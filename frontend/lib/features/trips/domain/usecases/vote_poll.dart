import '../entities/poll.dart';
import '../repositories/polls_repository.dart';

class VotePoll {
  final PollsRepository repository;

  const VotePoll(this.repository);

  Future<PollEntity> call({
    required String pollId,
    required String optionId,
    required String tripId,
  }) {
    return repository.vote(pollId: pollId, optionId: optionId, tripId: tripId);
  }
}
