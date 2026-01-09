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

  Future<void> clear() async {
    await box.clear();
  }
}
