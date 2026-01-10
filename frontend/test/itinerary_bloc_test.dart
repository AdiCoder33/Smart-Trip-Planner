import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:smart_trip_planner/core/connectivity/connectivity_service.dart';
import 'package:smart_trip_planner/core/sync/sync_queue.dart';
import 'package:smart_trip_planner/core/sync/sync_service.dart';
import 'package:smart_trip_planner/features/trips/domain/entities/itinerary_item.dart';
import 'package:smart_trip_planner/features/trips/domain/usecases/cache_itinerary_items.dart';
import 'package:smart_trip_planner/features/trips/domain/usecases/create_itinerary_item.dart';
import 'package:smart_trip_planner/features/trips/domain/usecases/delete_itinerary_item.dart';
import 'package:smart_trip_planner/features/trips/domain/usecases/delete_local_itinerary_item.dart';
import 'package:smart_trip_planner/features/trips/domain/usecases/get_cached_itinerary_items.dart';
import 'package:smart_trip_planner/features/trips/domain/usecases/get_itinerary_items.dart';
import 'package:smart_trip_planner/features/trips/domain/usecases/reorder_itinerary_items.dart';
import 'package:smart_trip_planner/features/trips/domain/usecases/update_itinerary_item.dart';
import 'package:smart_trip_planner/features/trips/domain/usecases/upsert_local_itinerary_item.dart';
import 'package:smart_trip_planner/features/trips/presentation/bloc/itinerary_bloc.dart';

class MockGetItineraryItems extends Mock implements GetItineraryItems {}

class MockGetCachedItineraryItems extends Mock implements GetCachedItineraryItems {}

class MockCreateItineraryItem extends Mock implements CreateItineraryItem {}

class MockUpdateItineraryItem extends Mock implements UpdateItineraryItem {}

class MockDeleteItineraryItem extends Mock implements DeleteItineraryItem {}

class MockReorderItineraryItems extends Mock implements ReorderItineraryItems {}

class MockCacheItineraryItems extends Mock implements CacheItineraryItems {}

class MockUpsertLocalItineraryItem extends Mock implements UpsertLocalItineraryItem {}

class MockDeleteLocalItineraryItem extends Mock implements DeleteLocalItineraryItem {}

class MockConnectivityService extends Mock implements ConnectivityService {}

class MockSyncQueue extends Mock implements SyncQueue {}

class MockSyncService extends Mock implements SyncService {}

void main() {
  setUpAll(() {
    registerFallbackValue(const ItineraryItemEntity(
      id: 'fallback',
      tripId: 'trip',
      title: 'Fallback',
      sortOrder: 0,
    ));
    registerFallbackValue(<ItineraryItemEntity>[]);
    registerFallbackValue(<Map<String, dynamic>>[]);
  });

  late MockGetItineraryItems getItineraryItems;
  late MockGetCachedItineraryItems getCachedItineraryItems;
  late MockCreateItineraryItem createItineraryItem;
  late MockUpdateItineraryItem updateItineraryItem;
  late MockDeleteItineraryItem deleteItineraryItem;
  late MockReorderItineraryItems reorderItineraryItems;
  late MockCacheItineraryItems cacheItineraryItems;
  late MockUpsertLocalItineraryItem upsertLocalItineraryItem;
  late MockDeleteLocalItineraryItem deleteLocalItineraryItem;
  late MockConnectivityService connectivityService;
  late MockSyncQueue syncQueue;
  late MockSyncService syncService;

  ItineraryBloc buildBloc() {
    return ItineraryBloc(
      getItineraryItems: getItineraryItems,
      getCachedItineraryItems: getCachedItineraryItems,
      createItineraryItem: createItineraryItem,
      updateItineraryItem: updateItineraryItem,
      deleteItineraryItem: deleteItineraryItem,
      reorderItineraryItems: reorderItineraryItems,
      cacheItineraryItems: cacheItineraryItems,
      upsertLocalItineraryItem: upsertLocalItineraryItem,
      deleteLocalItineraryItem: deleteLocalItineraryItem,
      connectivityService: connectivityService,
      syncQueue: syncQueue,
      syncService: syncService,
    );
  }

  setUp(() {
    getItineraryItems = MockGetItineraryItems();
    getCachedItineraryItems = MockGetCachedItineraryItems();
    createItineraryItem = MockCreateItineraryItem();
    updateItineraryItem = MockUpdateItineraryItem();
    deleteItineraryItem = MockDeleteItineraryItem();
    reorderItineraryItems = MockReorderItineraryItems();
    cacheItineraryItems = MockCacheItineraryItems();
    upsertLocalItineraryItem = MockUpsertLocalItineraryItem();
    deleteLocalItineraryItem = MockDeleteLocalItineraryItem();
    connectivityService = MockConnectivityService();
    syncQueue = MockSyncQueue();
    syncService = MockSyncService();
    when(() => connectivityService.onStatusChange).thenAnswer((_) => const Stream.empty());
  });

  const itemA = ItineraryItemEntity(
    id: 'a',
    tripId: 'trip',
    title: 'A',
    sortOrder: 0,
  );
  const itemB = ItineraryItemEntity(
    id: 'b',
    tripId: 'trip',
    title: 'B',
    sortOrder: 1,
  );

  blocTest<ItineraryBloc, ItineraryState>(
    'reorders itinerary optimistically and confirms with server',
    build: () {
      when(() => connectivityService.isOnline()).thenAnswer((_) async => true);
      when(() => cacheItineraryItems.call(any(), any())).thenAnswer((_) async {});
      when(() => reorderItineraryItems(tripId: 'trip', items: any(named: 'items')))
          .thenAnswer((_) async => const [
                ItineraryItemEntity(
                  id: 'b',
                  tripId: 'trip',
                  title: 'B',
                  sortOrder: 0,
                ),
                ItineraryItemEntity(
                  id: 'a',
                  tripId: 'trip',
                  title: 'A',
                  sortOrder: 1,
                ),
              ]);
      return buildBloc();
    },
    seed: () => const ItineraryState(
      status: ItineraryStatus.loaded,
      items: [itemA, itemB],
      tripId: 'trip',
    ),
    act: (bloc) {
      final reordered = [
        itemB.copyWith(sortOrder: 0),
        itemA.copyWith(sortOrder: 1),
      ];
      bloc.add(ItineraryReordered(tripId: 'trip', items: reordered));
    },
    expect: () => [
      isA<ItineraryState>().having((state) => state.items.first.id, 'first', 'b'),
    ],
  );
}
