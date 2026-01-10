import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:smart_trip_planner/core/connectivity/connectivity_service.dart';
import 'package:smart_trip_planner/core/sync/sync_queue.dart';
import 'package:smart_trip_planner/core/sync/sync_service.dart';
import 'package:smart_trip_planner/features/trips/domain/entities/poll.dart';
import 'package:smart_trip_planner/features/trips/domain/entities/poll_option.dart';
import 'package:smart_trip_planner/features/trips/domain/usecases/cache_polls.dart';
import 'package:smart_trip_planner/features/trips/domain/usecases/create_poll.dart';
import 'package:smart_trip_planner/features/trips/domain/usecases/delete_local_poll.dart';
import 'package:smart_trip_planner/features/trips/domain/usecases/get_cached_polls.dart';
import 'package:smart_trip_planner/features/trips/domain/usecases/get_polls.dart';
import 'package:smart_trip_planner/features/trips/domain/usecases/upsert_local_poll.dart';
import 'package:smart_trip_planner/features/trips/domain/usecases/vote_poll.dart';
import 'package:smart_trip_planner/features/trips/presentation/bloc/polls_bloc.dart';

class MockGetPolls extends Mock implements GetPolls {}

class MockGetCachedPolls extends Mock implements GetCachedPolls {}

class MockCreatePoll extends Mock implements CreatePoll {}

class MockVotePoll extends Mock implements VotePoll {}

class MockCachePolls extends Mock implements CachePolls {}

class MockUpsertLocalPoll extends Mock implements UpsertLocalPoll {}

class MockDeleteLocalPoll extends Mock implements DeleteLocalPoll {}

class MockConnectivityService extends Mock implements ConnectivityService {}

class MockSyncQueue extends Mock implements SyncQueue {}

class MockSyncService extends Mock implements SyncService {}

void main() {
  setUpAll(() {
    registerFallbackValue(const PollEntity(
      id: 'fallback',
      tripId: 'trip',
      question: 'Fallback',
      isActive: true,
      options: [],
    ));
    registerFallbackValue(<PollEntity>[]);
  });

  late MockGetPolls getPolls;
  late MockGetCachedPolls getCachedPolls;
  late MockCreatePoll createPoll;
  late MockVotePoll votePoll;
  late MockCachePolls cachePolls;
  late MockUpsertLocalPoll upsertLocalPoll;
  late MockDeleteLocalPoll deleteLocalPoll;
  late MockConnectivityService connectivityService;
  late MockSyncQueue syncQueue;
  late MockSyncService syncService;

  PollsBloc buildBloc() {
    return PollsBloc(
      getPolls: getPolls,
      getCachedPolls: getCachedPolls,
      createPoll: createPoll,
      votePoll: votePoll,
      cachePolls: cachePolls,
      upsertLocalPoll: upsertLocalPoll,
      deleteLocalPoll: deleteLocalPoll,
      connectivityService: connectivityService,
      syncQueue: syncQueue,
      syncService: syncService,
    );
  }

  setUp(() {
    getPolls = MockGetPolls();
    getCachedPolls = MockGetCachedPolls();
    createPoll = MockCreatePoll();
    votePoll = MockVotePoll();
    cachePolls = MockCachePolls();
    upsertLocalPoll = MockUpsertLocalPoll();
    deleteLocalPoll = MockDeleteLocalPoll();
    connectivityService = MockConnectivityService();
    syncQueue = MockSyncQueue();
    syncService = MockSyncService();
    when(() => connectivityService.onStatusChange).thenAnswer((_) => const Stream.empty());
  });

  final poll = PollEntity(
    id: 'poll1',
    tripId: 'trip',
    question: 'Dinner?',
    isActive: true,
    options: const [
      PollOptionEntity(id: 'opt1', text: 'Pizza', voteCount: 1),
      PollOptionEntity(id: 'opt2', text: 'Sushi', voteCount: 0),
    ],
    userVoteOptionId: 'opt1',
  );

  blocTest<PollsBloc, PollsState>(
    'votes optimistically and applies server response',
    build: () {
      when(() => connectivityService.isOnline()).thenAnswer((_) async => true);
      when(() => cachePolls.call(any(), any())).thenAnswer((_) async {});
      when(() => upsertLocalPoll.call(any())).thenAnswer((_) async {});
      when(() => votePoll(pollId: 'poll1', optionId: 'opt2', tripId: 'trip'))
          .thenAnswer(
        (_) async => PollEntity(
          id: 'poll1',
          tripId: 'trip',
          question: 'Dinner?',
          isActive: true,
          options: const [
            PollOptionEntity(id: 'opt1', text: 'Pizza', voteCount: 0),
            PollOptionEntity(id: 'opt2', text: 'Sushi', voteCount: 1),
          ],
          userVoteOptionId: 'opt2',
        ),
      );
      return buildBloc();
    },
    seed: () => PollsState(status: PollsStatus.loaded, polls: [poll], tripId: 'trip'),
    act: (bloc) {
      bloc.add(const PollVoted(tripId: 'trip', pollId: 'poll1', optionId: 'opt2'));
    },
    expect: () => [
      isA<PollsState>().having((state) => state.polls.first.userVoteOptionId, 'vote', 'opt2'),
    ],
  );
}
