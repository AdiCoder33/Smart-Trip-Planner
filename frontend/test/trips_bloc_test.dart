import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:smart_trip_planner/core/connectivity/connectivity_service.dart';
import 'package:smart_trip_planner/core/errors/app_exception.dart';
import 'package:smart_trip_planner/features/trips/domain/entities/trip.dart';
import 'package:smart_trip_planner/features/trips/domain/usecases/create_trip.dart';
import 'package:smart_trip_planner/features/trips/domain/usecases/get_cached_trips.dart';
import 'package:smart_trip_planner/features/trips/domain/usecases/get_trips.dart';
import 'package:smart_trip_planner/features/trips/presentation/bloc/trips_bloc.dart';

class MockGetTrips extends Mock implements GetTrips {}

class MockGetCachedTrips extends Mock implements GetCachedTrips {}

class MockCreateTrip extends Mock implements CreateTrip {}

class MockConnectivityService extends Mock implements ConnectivityService {}

void main() {
  late MockGetTrips getTrips;
  late MockGetCachedTrips getCachedTrips;
  late MockCreateTrip createTrip;
  late MockConnectivityService connectivityService;
  late TripsBloc tripsBloc;

  setUp(() {
    getTrips = MockGetTrips();
    getCachedTrips = MockGetCachedTrips();
    createTrip = MockCreateTrip();
    connectivityService = MockConnectivityService();
    tripsBloc = TripsBloc(
      getTrips: getTrips,
      getCachedTrips: getCachedTrips,
      createTrip: createTrip,
      connectivityService: connectivityService,
    );
  });

  tearDown(() {
    tripsBloc.close();
  });

  const cachedTrip = TripEntity(id: 'cached', title: 'Cached');
  const remoteTrip = TripEntity(id: 'remote', title: 'Remote');

  blocTest<TripsBloc, TripsState>(
    'loads cached trips then remote trips',
    build: () {
      when(() => getCachedTrips()).thenAnswer((_) async => [cachedTrip]);
      when(() => connectivityService.isOnline()).thenAnswer((_) async => true);
      when(() => getTrips()).thenAnswer((_) async => [remoteTrip]);
      return tripsBloc;
    },
    act: (bloc) => bloc.add(const TripsStarted()),
    expect: () => [
      const TripsState(status: TripsStatus.loading),
      const TripsState(status: TripsStatus.loading, trips: [cachedTrip]),
      const TripsState(status: TripsStatus.loaded, trips: [remoteTrip]),
    ],
  );

  blocTest<TripsBloc, TripsState>(
    'optimistically creates trip and replaces with server trip',
    build: () {
      when(() => connectivityService.isOnline()).thenAnswer((_) async => true);
      when(() => createTrip(
            title: any(named: 'title'),
            destination: any(named: 'destination'),
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
          )).thenAnswer((_) async => const TripEntity(id: 'server', title: 'Server Trip'));
      return tripsBloc;
    },
    act: (bloc) => bloc.add(const TripCreated(title: 'New Trip')),
    expect: () => [
      isA<TripsState>()
          .having((state) => state.trips.length, 'length', 1)
          .having((state) => state.trips.first.isPending, 'pending', true),
      isA<TripsState>()
          .having((state) => state.trips.first.id, 'id', 'server')
          .having((state) => state.trips.first.title, 'title', 'Server Trip'),
    ],
  );

  blocTest<TripsBloc, TripsState>(
    'emits error on refresh failure',
    build: () {
      when(() => connectivityService.isOnline()).thenAnswer((_) async => true);
      when(() => getTrips()).thenThrow(AppException('Failed'));
      return tripsBloc;
    },
    act: (bloc) => bloc.add(const TripsRefreshed()),
    expect: () => [
      const TripsState(isRefreshing: true),
      const TripsState(isRefreshing: false, message: 'Failed'),
    ],
  );
}
