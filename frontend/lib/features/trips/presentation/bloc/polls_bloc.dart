import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/connectivity/connectivity_service.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/sync/pending_action.dart';
import '../../../../core/sync/sync_queue.dart';
import '../../../../core/sync/sync_service.dart';
import '../../domain/entities/poll.dart';
import '../../domain/entities/poll_option.dart';
import '../../domain/usecases/cache_polls.dart';
import '../../domain/usecases/create_poll.dart';
import '../../domain/usecases/delete_poll.dart';
import '../../domain/usecases/delete_local_poll.dart';
import '../../domain/usecases/get_cached_polls.dart';
import '../../domain/usecases/get_polls.dart';
import '../../domain/usecases/update_poll.dart';
import '../../domain/usecases/upsert_local_poll.dart';
import '../../domain/usecases/vote_poll.dart';

part 'polls_event.dart';
part 'polls_state.dart';

class PollsBloc extends Bloc<PollsEvent, PollsState> {
  final GetPolls getPolls;
  final GetCachedPolls getCachedPolls;
  final CreatePoll createPoll;
  final VotePoll votePoll;
  final UpdatePoll updatePoll;
  final DeletePoll deletePoll;
  final CachePolls cachePolls;
  final UpsertLocalPoll upsertLocalPoll;
  final DeleteLocalPoll deleteLocalPoll;
  final ConnectivityService connectivityService;
  final SyncQueue syncQueue;
  final SyncService syncService;
  final Uuid _uuid = const Uuid();
  StreamSubscription<bool>? _subscription;

  PollsBloc({
    required this.getPolls,
    required this.getCachedPolls,
    required this.createPoll,
    required this.votePoll,
    required this.updatePoll,
    required this.deletePoll,
    required this.cachePolls,
    required this.upsertLocalPoll,
    required this.deleteLocalPoll,
    required this.connectivityService,
    required this.syncQueue,
    required this.syncService,
  }) : super(const PollsState()) {
    on<PollsStarted>(_onStarted);
    on<PollsRefreshed>(_onRefreshed);
    on<PollCreated>(_onCreated);
    on<PollVoted>(_onVoted);
    on<PollUpdated>(_onUpdated);
    on<PollDeleted>(_onDeleted);
    on<PollsSyncRequested>(_onSyncRequested);

    _subscription = connectivityService.onStatusChange.listen((online) {
      if (online && state.tripId != null) {
        add(PollsSyncRequested(tripId: state.tripId!));
      }
    });
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }

  Future<void> _onStarted(PollsStarted event, Emitter<PollsState> emit) async {
    emit(state.copyWith(status: PollsStatus.loading, tripId: event.tripId, message: null));
    final cached = await getCachedPolls(event.tripId);
    emit(state.copyWith(status: PollsStatus.loading, polls: cached, tripId: event.tripId));

    final online = await connectivityService.isOnline();
    if (!online) {
      emit(state.copyWith(status: PollsStatus.loaded));
      return;
    }

    final synced = await syncService.processQueue();
    if (!synced) {
      emit(state.copyWith(status: PollsStatus.loaded, message: 'Sync pending actions failed.'));
      return;
    }

    try {
      final remote = await getPolls(event.tripId);
      emit(state.copyWith(status: PollsStatus.loaded, polls: remote));
    } catch (error) {
      final message = error is AppException ? error.message : 'Failed to load polls';
      emit(state.copyWith(status: PollsStatus.error, message: message));
    }
  }

  Future<void> _onRefreshed(PollsRefreshed event, Emitter<PollsState> emit) async {
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
      final remote = await getPolls(event.tripId);
      emit(state.copyWith(status: PollsStatus.loaded, polls: remote, isRefreshing: false));
    } catch (error) {
      final message = error is AppException ? error.message : 'Failed to refresh polls';
      emit(state.copyWith(isRefreshing: false, message: message));
    }
  }

  Future<void> _onCreated(PollCreated event, Emitter<PollsState> emit) async {
    final online = await connectivityService.isOnline();
    final previous = state.polls;
    final tempId = 'temp-${_uuid.v4()}';
    final options = event.options
        .map(
          (text) => PollOptionEntity(
            id: 'temp-${_uuid.v4()}',
            text: text,
            voteCount: 0,
          ),
        )
        .toList();
    final tempPoll = PollEntity(
      id: tempId,
      tripId: event.tripId,
      question: event.question,
      isActive: true,
      options: options,
      createdAt: DateTime.now(),
      isPending: true,
    );

    final optimistic = [tempPoll, ...state.polls];
    emit(state.copyWith(polls: optimistic));
    await upsertLocalPoll(tempPoll);

    if (!online) {
      await syncQueue.enqueue(
        PendingAction.create(
          type: PendingActionType.createPoll,
          payload: {
            'trip_id': event.tripId,
            'temp_id': tempId,
            'question': event.question,
            'options': event.options,
          },
        ),
      );
      return;
    }

    try {
      final created = await createPoll(
        tripId: event.tripId,
        question: event.question,
        options: event.options,
      );
      final updated = optimistic.map((poll) => poll.id == tempId ? created : poll).toList();
      await deleteLocalPoll(tempId);
      await upsertLocalPoll(created);
      emit(state.copyWith(polls: updated));
    } catch (error) {
      final message = error is AppException ? error.message : 'Failed to create poll';
      await deleteLocalPoll(tempId);
      emit(state.copyWith(polls: previous, message: message));
    }
  }

  Future<void> _onVoted(PollVoted event, Emitter<PollsState> emit) async {
    if (event.pollId.startsWith('temp-')) {
      emit(state.copyWith(message: 'Poll is still syncing. Please wait.'));
      return;
    }
    final targetIndex = state.polls.indexWhere((poll) => poll.id == event.pollId);
    if (targetIndex == -1) {
      return;
    }
    final target = state.polls[targetIndex];
    if (target.isPending || target.id.startsWith('temp-')) {
      emit(state.copyWith(message: 'Poll is still syncing. Please wait.'));
      return;
    }

    final online = await connectivityService.isOnline();
    final previous = state.polls;
    final updatedPolls = state.polls.map((poll) {
      if (poll.id != event.pollId) return poll;
      return _applyVote(poll, event.optionId, markPending: !online);
    }).toList();
    emit(state.copyWith(polls: updatedPolls));
    await cachePolls(event.tripId, updatedPolls);

    if (!online) {
      await syncQueue.enqueue(
        PendingAction.create(
          type: PendingActionType.votePoll,
          payload: {
            'trip_id': event.tripId,
            'poll_id': event.pollId,
            'option_id': event.optionId,
          },
        ),
      );
      return;
    }

    try {
      final updated = await votePoll(
        pollId: event.pollId,
        optionId: event.optionId,
        tripId: event.tripId,
      );
      final merged = updatedPolls.map((poll) => poll.id == updated.id ? updated : poll).toList();
      await upsertLocalPoll(updated);
      emit(state.copyWith(polls: merged));
    } catch (error) {
      final message = error is AppException ? error.message : 'Failed to submit vote';
      await cachePolls(event.tripId, previous);
      emit(state.copyWith(polls: previous, message: message));
    }
  }

  Future<void> _onUpdated(PollUpdated event, Emitter<PollsState> emit) async {
    final online = await connectivityService.isOnline();
    if (!online) {
      emit(state.copyWith(message: 'You are offline. Editing polls is disabled.'));
      return;
    }

    try {
      final updated = await updatePoll(
        pollId: event.pollId,
        tripId: event.tripId,
        question: event.question,
        options: event.options,
      );
      final updatedPolls = state.polls.map((poll) {
        if (poll.id == updated.id) {
          return updated;
        }
        return poll;
      }).toList();
      await upsertLocalPoll(updated);
      emit(state.copyWith(polls: updatedPolls, message: 'Poll updated.'));
    } catch (error) {
      final message = error is AppException ? error.message : 'Failed to update poll';
      emit(state.copyWith(message: message));
    }
  }

  Future<void> _onDeleted(PollDeleted event, Emitter<PollsState> emit) async {
    final online = await connectivityService.isOnline();
    if (!online) {
      emit(state.copyWith(message: 'You are offline. Deleting polls is disabled.'));
      return;
    }

    final previous = state.polls;
    final updated = previous.where((poll) => poll.id != event.pollId).toList();
    emit(state.copyWith(polls: updated));

    try {
      await deletePoll(pollId: event.pollId);
      await deleteLocalPoll(event.pollId);
      emit(state.copyWith(message: 'Poll deleted.'));
    } catch (error) {
      final message = error is AppException ? error.message : 'Failed to delete poll';
      emit(state.copyWith(polls: previous, message: message));
    }
  }

  Future<void> _onSyncRequested(PollsSyncRequested event, Emitter<PollsState> emit) async {
    if (state.isSyncing) return;
    emit(state.copyWith(isSyncing: true));
    final synced = await syncService.processQueue();
    if (synced) {
      try {
        final remote = await getPolls(event.tripId);
        emit(state.copyWith(polls: remote, isSyncing: false));
      } catch (error) {
        final message = error is AppException ? error.message : 'Failed to sync polls';
        emit(state.copyWith(isSyncing: false, message: message));
      }
      return;
    }
    emit(state.copyWith(isSyncing: false, message: 'Sync pending actions failed.'));
  }

  PollEntity _applyVote(PollEntity poll, String optionId, {required bool markPending}) {
    final previousOptionId = poll.userVoteOptionId;
    final updatedOptions = poll.options.map((option) {
      var count = option.voteCount;
      if (option.id == previousOptionId && option.id != optionId) {
        count = count > 0 ? count - 1 : 0;
      }
      if (option.id == optionId && option.id != previousOptionId) {
        count = count + 1;
      }
      return PollOptionEntity(id: option.id, text: option.text, voteCount: count);
    }).toList();

    return poll.copyWith(
      options: updatedOptions,
      userVoteOptionId: optionId,
      isPending: markPending,
    );
  }
}
