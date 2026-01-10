import '../entities/poll.dart';
import '../repositories/polls_repository.dart';

class UpsertLocalPoll {
  final PollsRepository repository;

  const UpsertLocalPoll(this.repository);

  Future<void> call(PollEntity poll) {
    return repository.upsertLocalPoll(poll);
  }
}
