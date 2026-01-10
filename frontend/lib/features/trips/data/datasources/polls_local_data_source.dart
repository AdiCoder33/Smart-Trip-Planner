import 'package:hive/hive.dart';

import '../models/poll_model.dart';

class PollsLocalDataSource {
  final Box<PollModel> box;

  const PollsLocalDataSource(this.box);

  Future<List<PollModel>> getPolls(String tripId) async {
    final polls = box.values.where((poll) => poll.tripId == tripId).toList();
    polls.sort((a, b) => (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
    return polls;
  }

  Future<void> cachePolls(String tripId, List<PollModel> polls) async {
    final idsToRemove = box.values
        .where((poll) => poll.tripId == tripId)
        .map((poll) => poll.id)
        .toList();
    await box.deleteAll(idsToRemove);
    final map = {for (final poll in polls) poll.id: poll};
    await box.putAll(map);
  }

  Future<void> upsertPoll(PollModel poll) async {
    await box.put(poll.id, poll);
  }

  Future<void> deletePoll(String pollId) async {
    await box.delete(pollId);
  }
}
