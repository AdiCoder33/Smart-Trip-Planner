import '../repositories/polls_repository.dart';

class DeleteLocalPoll {
  final PollsRepository repository;

  const DeleteLocalPoll(this.repository);

  Future<void> call(String pollId) {
    return repository.deleteLocalPoll(pollId);
  }
}
