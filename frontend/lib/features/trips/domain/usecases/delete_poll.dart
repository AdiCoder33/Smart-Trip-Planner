import '../repositories/polls_repository.dart';

class DeletePoll {
  final PollsRepository repository;

  const DeletePoll(this.repository);

  Future<void> call({required String pollId}) {
    return repository.deletePoll(pollId: pollId);
  }
}
