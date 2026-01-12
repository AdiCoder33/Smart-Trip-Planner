import '../entities/poll.dart';
import '../repositories/polls_repository.dart';

class UpdatePoll {
  final PollsRepository repository;

  const UpdatePoll(this.repository);

  Future<PollEntity> call({
    required String pollId,
    required String tripId,
    required String question,
    required List<String> options,
  }) {
    return repository.updatePoll(
      pollId: pollId,
      tripId: tripId,
      question: question,
      options: options,
    );
  }
}
