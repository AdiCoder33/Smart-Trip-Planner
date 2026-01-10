import '../entities/poll.dart';
import '../repositories/polls_repository.dart';

class CreatePoll {
  final PollsRepository repository;

  const CreatePoll(this.repository);

  Future<PollEntity> call({
    required String tripId,
    required String question,
    required List<String> options,
  }) {
    return repository.createPoll(tripId: tripId, question: question, options: options);
  }
}
