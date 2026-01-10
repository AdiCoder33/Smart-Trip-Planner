import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:smart_trip_planner/core/connectivity/connectivity_cubit.dart';
import 'package:smart_trip_planner/features/trips/domain/entities/trip.dart';
import 'package:smart_trip_planner/features/trips/presentation/bloc/trips_bloc.dart';
import 'package:smart_trip_planner/features/trips/presentation/screens/trips_list_screen.dart';

class MockTripsBloc extends MockBloc<TripsEvent, TripsState> implements TripsBloc {}

class FakeTripsEvent extends Fake implements TripsEvent {}

class MockConnectivityCubit extends MockCubit<ConnectivityState>
    implements ConnectivityCubit {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeTripsEvent());
  });

  testWidgets('TripsListScreen renders trips list', (tester) async {
    final tripsBloc = MockTripsBloc();
    const trip = TripEntity(id: '1', title: 'Paris');
    const state = TripsState(status: TripsStatus.loaded, trips: [trip]);

    when(() => tripsBloc.state).thenReturn(state);
    whenListen(tripsBloc, Stream.value(state), initialState: state);

    final connectivityCubit = MockConnectivityCubit();
    const connectivityState = ConnectivityState(isOnline: true);
    when(() => connectivityCubit.state).thenReturn(connectivityState);
    whenListen(
      connectivityCubit,
      Stream<ConnectivityState>.value(connectivityState),
      initialState: connectivityState,
    );

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<TripsBloc>.value(value: tripsBloc),
          BlocProvider<ConnectivityCubit>.value(value: connectivityCubit),
        ],
        child: const MaterialApp(home: TripsListScreen()),
      ),
    );

    await tester.pump();

    expect(find.text('My Trips'), findsOneWidget);
    expect(find.text('Paris'), findsOneWidget);
  });
}
