import '../entities/poll.dart';
import '../repositories/polls_repository.dart';

class GetPolls {
  final PollsRepository repository;

  const GetPolls(this.repository);

  Future<List<PollEntity>> call(String tripId) {
    return repository.getPolls(tripId);
  }
}
