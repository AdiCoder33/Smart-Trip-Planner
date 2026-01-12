import 'package:hive/hive.dart';

import 'pending_action.dart';

class SyncQueue {
  final Box<PendingAction> box;

  const SyncQueue(this.box);

  Future<void> enqueue(PendingAction action) async {
    await box.put(action.id, action);
  }

  Future<List<PendingAction>> getAll() async {
    final actions = box.values.toList();
    actions.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return actions;
  }

  Future<void> remove(String id) async {
    await box.delete(id);
  }

  Future<void> remapPollVote(String tempPollId, String pollId) async {
    final entries = box.toMap();
    for (final entry in entries.entries) {
      final action = entry.value;
      if (action.type == PendingActionType.votePoll &&
          action.payload['poll_id'] == tempPollId) {
        final updatedPayload = Map<String, dynamic>.from(action.payload);
        updatedPayload['poll_id'] = pollId;
        final updated = PendingAction(
          id: action.id,
          type: action.type,
          payload: updatedPayload,
          createdAt: action.createdAt,
        );
        await box.put(action.id, updated);
      }
    }
  }

  Future<void> clear() async {
    await box.clear();
  }
}
