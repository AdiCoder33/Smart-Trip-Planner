import '../entities/poll.dart';
import '../repositories/polls_repository.dart';

class GetCachedPolls {
  final PollsRepository repository;

  const GetCachedPolls(this.repository);

  Future<List<PollEntity>> call(String tripId) {
    return repository.getCachedPolls(tripId);
  }
}
