import '../entities/poll.dart';
import '../repositories/polls_repository.dart';

class CachePolls {
  final PollsRepository repository;

  const CachePolls(this.repository);

  Future<void> call(String tripId, List<PollEntity> polls) {
    return repository.cacheLocalPolls(tripId, polls);
  }
}
