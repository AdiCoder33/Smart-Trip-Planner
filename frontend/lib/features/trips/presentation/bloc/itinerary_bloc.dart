import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/connectivity/connectivity_service.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/sync/pending_action.dart';
import '../../../../core/sync/sync_queue.dart';
import '../../../../core/sync/sync_service.dart';
import '../../domain/entities/itinerary_item.dart';
import '../../domain/usecases/create_itinerary_item.dart';
import '../../domain/usecases/delete_local_itinerary_item.dart';
import '../../domain/usecases/delete_itinerary_item.dart';
import '../../domain/usecases/cache_itinerary_items.dart';
import '../../domain/usecases/get_cached_itinerary_items.dart';
import '../../domain/usecases/get_itinerary_items.dart';
import '../../domain/usecases/reorder_itinerary_items.dart';
import '../../domain/usecases/upsert_local_itinerary_item.dart';
import '../../domain/usecases/update_itinerary_item.dart';

part 'itinerary_event.dart';
part 'itinerary_state.dart';

class ItineraryBloc extends Bloc<ItineraryEvent, ItineraryState> {
  final GetItineraryItems getItineraryItems;
  final GetCachedItineraryItems getCachedItineraryItems;
  final CreateItineraryItem createItineraryItem;
  final UpdateItineraryItem updateItineraryItem;
  final DeleteItineraryItem deleteItineraryItem;
  final ReorderItineraryItems reorderItineraryItems;
  final CacheItineraryItems cacheItineraryItems;
  final UpsertLocalItineraryItem upsertLocalItineraryItem;
  final DeleteLocalItineraryItem deleteLocalItineraryItem;
  final ConnectivityService connectivityService;
  final SyncQueue syncQueue;
  final SyncService syncService;
  final Uuid _uuid = const Uuid();
  StreamSubscription<bool>? _subscription;

  ItineraryBloc({
    required this.getItineraryItems,
    required this.getCachedItineraryItems,
    required this.createItineraryItem,
    required this.updateItineraryItem,
    required this.deleteItineraryItem,
    required this.reorderItineraryItems,
    required this.cacheItineraryItems,
    required this.upsertLocalItineraryItem,
    required this.deleteLocalItineraryItem,
    required this.connectivityService,
    required this.syncQueue,
    required this.syncService,
  }) : super(const ItineraryState()) {
    on<ItineraryStarted>(_onStarted);
    on<ItineraryRefreshed>(_onRefreshed);
    on<ItineraryItemCreated>(_onCreated);
    on<ItineraryItemUpdated>(_onUpdated);
    on<ItineraryItemDeleted>(_onDeleted);
    on<ItineraryReordered>(_onReordered);
    on<ItinerarySyncRequested>(_onSyncRequested);

    _subscription = connectivityService.onStatusChange.listen((online) {
      if (online && state.tripId != null) {
        add(ItinerarySyncRequested(tripId: state.tripId!));
      }
    });
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }

  Future<void> _onStarted(ItineraryStarted event, Emitter<ItineraryState> emit) async {
    emit(state.copyWith(status: ItineraryStatus.loading, tripId: event.tripId, message: null));
    final cached = await getCachedItineraryItems(event.tripId);
    emit(state.copyWith(status: ItineraryStatus.loading, items: cached, tripId: event.tripId));

    final online = await connectivityService.isOnline();
    if (!online) {
      emit(state.copyWith(status: ItineraryStatus.loaded));
      return;
    }

    final synced = await syncService.processQueue();
    if (!synced) {
      emit(state.copyWith(status: ItineraryStatus.loaded, message: 'Sync pending actions failed.'));
      return;
    }

    try {
      final remote = await getItineraryItems(event.tripId);
      emit(state.copyWith(status: ItineraryStatus.loaded, items: remote));
    } catch (error) {
      final message = error is AppException ? error.message : 'Failed to load itinerary';
      emit(state.copyWith(status: ItineraryStatus.error, message: message));
    }
  }

  Future<void> _onRefreshed(ItineraryRefreshed event, Emitter<ItineraryState> emit) async {
    final online = await connectivityService.isOnline();
    if (!online) {
      emit(state.copyWith(message: 'You are offline.'));
      return;
    }

    emit(state.copyWith(isRefreshing: true, message: null));
    final synced = await syncService.processQueue();
    if (!synced) {
      emit(state.copyWith(isRefreshing: false, message: 'Sync pending actions failed.'));
      return;
    }

    try {
      final remote = await getItineraryItems(event.tripId);
      emit(state.copyWith(status: ItineraryStatus.loaded, items: remote, isRefreshing: false));
    } catch (error) {
      final message = error is AppException ? error.message : 'Failed to refresh itinerary';
      emit(state.copyWith(isRefreshing: false, message: message));
    }
  }

  Future<void> _onCreated(ItineraryItemCreated event, Emitter<ItineraryState> emit) async {
    final online = await connectivityService.isOnline();
    final previous = state.items;
    final tempId = 'temp-${_uuid.v4()}';
    final tempItem = ItineraryItemEntity(
      id: tempId,
      tripId: event.tripId,
      title: event.title,
      notes: event.notes,
      location: event.location,
      startTime: event.startTime,
      endTime: event.endTime,
      date: event.date,
      sortOrder: state.items.length,
      createdAt: DateTime.now(),
      isPending: !online,
    );

    final optimistic = [...state.items, tempItem];
    emit(state.copyWith(items: optimistic));
    await upsertLocalItineraryItem(tempItem);

    if (!online) {
      await syncQueue.enqueue(
        PendingAction.create(
          type: PendingActionType.createItinerary,
          payload: {
            'trip_id': event.tripId,
            'temp_id': tempId,
            'data': {
              'title': event.title,
              'notes': event.notes,
              'location': event.location,
              'start_time': event.startTime,
              'end_time': event.endTime,
              'date': event.date?.toIso8601String().split('T').first,
            },
          },
        ),
      );
      return;
    }

    try {
      final created = await createItineraryItem(
        tripId: event.tripId,
        title: event.title,
        notes: event.notes,
        location: event.location,
        startTime: event.startTime,
        endTime: event.endTime,
        date: event.date,
      );

      final updated = optimistic.map((item) {
        if (item.id == tempId) {
          return created;
        }
        return item;
      }).toList();
      await deleteLocalItineraryItem(tempId);
      await upsertLocalItineraryItem(created);
      emit(state.copyWith(items: updated));
    } catch (error) {
      final message = error is AppException ? error.message : 'Failed to create item';
      await deleteLocalItineraryItem(tempId);
      emit(state.copyWith(items: previous, message: message));
    }
  }

  Future<void> _onUpdated(ItineraryItemUpdated event, Emitter<ItineraryState> emit) async {
    final online = await connectivityService.isOnline();
    final current = state.items;
    final updatedItems = current.map((item) {
      if (item.id != event.itemId) return item;
      return item.copyWith(
        title: event.title ?? item.title,
        notes: event.notes ?? item.notes,
        location: event.location ?? item.location,
        startTime: event.startTime ?? item.startTime,
        endTime: event.endTime ?? item.endTime,
        date: event.date ?? item.date,
        isPending: !online,
      );
    }).toList();
    emit(state.copyWith(items: updatedItems));
    await cacheItineraryItems(event.tripId, updatedItems);

    if (!online) {
      await syncQueue.enqueue(
        PendingAction.create(
          type: PendingActionType.updateItinerary,
          payload: {
            'trip_id': event.tripId,
            'item_id': event.itemId,
            'data': _buildItineraryPayload(event),
          },
        ),
      );
      return;
    }

    try {
      final updated = await updateItineraryItem(
        itemId: event.itemId,
        tripId: event.tripId,
        title: event.title,
        notes: event.notes,
        location: event.location,
        startTime: event.startTime,
        endTime: event.endTime,
        date: event.date,
      );
      final merged = updatedItems.map((item) => item.id == updated.id ? updated : item).toList();
      await upsertLocalItineraryItem(updated);
      emit(state.copyWith(items: merged));
    } catch (error) {
      final message = error is AppException ? error.message : 'Failed to update item';
      await cacheItineraryItems(event.tripId, current);
      emit(state.copyWith(items: current, message: message));
    }
  }

  Future<void> _onDeleted(ItineraryItemDeleted event, Emitter<ItineraryState> emit) async {
    final online = await connectivityService.isOnline();
    final current = state.items;
    final removedItem = current.firstWhere(
      (item) => item.id == event.itemId,
      orElse: () => const ItineraryItemEntity(
        id: '',
        tripId: '',
        title: '',
        sortOrder: 0,
      ),
    );
    final removed = current.where((item) => item.id != event.itemId).toList();
    emit(state.copyWith(items: removed));
    await deleteLocalItineraryItem(event.itemId);

    if (!online) {
      await syncQueue.enqueue(
        PendingAction.create(
          type: PendingActionType.deleteItinerary,
          payload: {'item_id': event.itemId, 'trip_id': event.tripId},
        ),
      );
      return;
    }

    try {
      await deleteItineraryItem(itemId: event.itemId, tripId: event.tripId);
    } catch (error) {
      final message = error is AppException ? error.message : 'Failed to delete item';
      if (removedItem.id.isNotEmpty) {
        await upsertLocalItineraryItem(removedItem);
      }
      emit(state.copyWith(items: current, message: message));
    }
  }

  Future<void> _onReordered(ItineraryReordered event, Emitter<ItineraryState> emit) async {
    final online = await connectivityService.isOnline();
    final previous = state.items;
    final optimisticItems = online
        ? event.items
        : event.items.map((item) => item.copyWith(isPending: true)).toList();
    emit(state.copyWith(items: optimisticItems));
    await cacheItineraryItems(event.tripId, optimisticItems);

    final payloadItems = event.items
        .map((item) => {'id': item.id, 'sort_order': item.sortOrder})
        .toList();

    if (!online) {
      await syncQueue.enqueue(
        PendingAction.create(
          type: PendingActionType.reorderItinerary,
          payload: {'trip_id': event.tripId, 'items': payloadItems},
        ),
      );
      return;
    }

    try {
      final updated = await reorderItineraryItems(tripId: event.tripId, items: payloadItems);
      await cacheItineraryItems(event.tripId, updated);
      emit(state.copyWith(items: updated));
    } catch (error) {
      final message = error is AppException ? error.message : 'Failed to reorder itinerary';
      await cacheItineraryItems(event.tripId, previous);
      emit(state.copyWith(items: previous, message: message));
    }
  }

  Future<void> _onSyncRequested(
    ItinerarySyncRequested event,
    Emitter<ItineraryState> emit,
  ) async {
    if (state.isSyncing) return;
    emit(state.copyWith(isSyncing: true));
    final synced = await syncService.processQueue();
    if (synced) {
      try {
        final remote = await getItineraryItems(event.tripId);
        emit(state.copyWith(items: remote, isSyncing: false));
      } catch (error) {
        final message = error is AppException ? error.message : 'Failed to sync itinerary';
        emit(state.copyWith(isSyncing: false, message: message));
      }
      return;
    }
    emit(state.copyWith(isSyncing: false, message: 'Sync pending actions failed.'));
  }

  Map<String, dynamic> _buildItineraryPayload(ItineraryItemUpdated event) {
    final payload = <String, dynamic>{};
    if (event.title != null) payload['title'] = event.title;
    if (event.notes != null) payload['notes'] = event.notes;
    if (event.location != null) payload['location'] = event.location;
    if (event.startTime != null) payload['start_time'] = event.startTime;
    if (event.endTime != null) payload['end_time'] = event.endTime;
    if (event.date != null) {
      payload['date'] = event.date!.toIso8601String().split('T').first;
    }
    return payload;
  }
}
