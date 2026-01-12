import 'dart:async';

import '../../features/trips/data/datasources/itinerary_local_data_source.dart';
import '../../features/trips/data/datasources/itinerary_remote_data_source.dart';
import '../../features/trips/data/datasources/polls_local_data_source.dart';
import '../../features/trips/data/datasources/polls_remote_data_source.dart';
import 'pending_action.dart';
import 'sync_queue.dart';

class SyncService {
  final SyncQueue queue;
  final ItineraryRemoteDataSource itineraryRemote;
  final ItineraryLocalDataSource itineraryLocal;
  final PollsRemoteDataSource pollsRemote;
  final PollsLocalDataSource pollsLocal;
  Future<bool>? _processing;

  SyncService({
    required this.queue,
    required this.itineraryRemote,
    required this.itineraryLocal,
    required this.pollsRemote,
    required this.pollsLocal,
  });

  Future<bool> processQueue() async {
    if (_processing != null) {
      return _processing!;
    }

    final completer = Completer<bool>();
    _processing = completer.future;

    final actions = await queue.getAll();
    for (final action in actions) {
      if (action.type == PendingActionType.sendChatMessage) {
        continue;
      }
      try {
        await _handleAction(action);
        await queue.remove(action.id);
      } catch (_) {
        completer.complete(false);
        _processing = null;
        return completer.future;
      }
    }
    completer.complete(true);
    _processing = null;
    return completer.future;
  }

  Future<void> _handleAction(PendingAction action) async {
    switch (action.type) {
      case PendingActionType.createItinerary:
        await _handleCreateItinerary(action);
        return;
      case PendingActionType.updateItinerary:
        await _handleUpdateItinerary(action);
        return;
      case PendingActionType.deleteItinerary:
        await _handleDeleteItinerary(action);
        return;
      case PendingActionType.reorderItinerary:
        await _handleReorderItinerary(action);
        return;
      case PendingActionType.createPoll:
        await _handleCreatePoll(action);
        return;
      case PendingActionType.votePoll:
        await _handleVotePoll(action);
        return;
    }
  }

  Future<void> _handleCreateItinerary(PendingAction action) async {
    final payload = action.payload;
    final tripId = payload['trip_id'] as String;
    final tempId = payload['temp_id'] as String;
    final data = Map<String, dynamic>.from(payload['data'] as Map);
    final item = await itineraryRemote.createItem(tripId: tripId, payload: data);
    await itineraryLocal.deleteItem(tempId);
    await itineraryLocal.upsertItem(item);
  }

  Future<void> _handleUpdateItinerary(PendingAction action) async {
    final payload = action.payload;
    final tripId = payload['trip_id'] as String;
    final itemId = payload['item_id'] as String;
    final data = Map<String, dynamic>.from(payload['data'] as Map);
    final item = await itineraryRemote.updateItem(
      itemId: itemId,
      tripId: tripId,
      payload: data,
    );
    await itineraryLocal.upsertItem(item);
  }

  Future<void> _handleDeleteItinerary(PendingAction action) async {
    final payload = action.payload;
    final itemId = payload['item_id'] as String;
    final tripId = payload['trip_id'] as String?;
    await itineraryRemote.deleteItem(itemId, tripId: tripId);
    await itineraryLocal.deleteItem(itemId);
  }

  Future<void> _handleReorderItinerary(PendingAction action) async {
    final payload = action.payload;
    final tripId = payload['trip_id'] as String;
    final items = (payload['items'] as List)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
    final updated = await itineraryRemote.reorderItems(tripId: tripId, items: items);
    await itineraryLocal.cacheItems(tripId, updated);
  }

  Future<void> _handleCreatePoll(PendingAction action) async {
    final payload = action.payload;
    final tripId = payload['trip_id'] as String;
    final tempId = payload['temp_id'] as String;
    final poll = await pollsRemote.createPoll(
      tripId: tripId,
      question: payload['question'] as String,
      options: (payload['options'] as List).cast<String>(),
    );
    await queue.remapPollVote(tempId, poll.id);
    await pollsLocal.deletePoll(tempId);
    await pollsLocal.upsertPoll(poll);
  }

  Future<void> _handleVotePoll(PendingAction action) async {
    final payload = action.payload;
    final pollId = payload['poll_id'] as String;
    final optionId = payload['option_id'] as String;
    final tripId = payload['trip_id'] as String;
    if (pollId.startsWith('temp-')) {
      return;
    }
    final poll = await pollsRemote.vote(pollId: pollId, optionId: optionId, tripId: tripId);
    await pollsLocal.upsertPoll(poll);
  }
}
