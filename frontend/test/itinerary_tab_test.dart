import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:smart_trip_planner/core/connectivity/connectivity_cubit.dart';
import 'package:smart_trip_planner/features/trips/domain/entities/itinerary_item.dart';
import 'package:smart_trip_planner/features/trips/domain/entities/trip.dart';
import 'package:smart_trip_planner/features/trips/presentation/bloc/itinerary_bloc.dart';
import 'package:smart_trip_planner/features/trips/presentation/screens/itinerary_tab.dart';

class MockItineraryBloc extends MockBloc<ItineraryEvent, ItineraryState>
    implements ItineraryBloc {}

class MockConnectivityCubit extends MockCubit<ConnectivityState>
    implements ConnectivityCubit {}

void main() {
  setUpAll(() {
    registerFallbackValue(const ItineraryState());
    registerFallbackValue(const ItineraryItemEntity(
      id: 'fallback',
      tripId: 'trip',
      title: 'Fallback',
      sortOrder: 0,
    ));
  });

  testWidgets('renders itinerary items', (tester) async {
    final itineraryBloc = MockItineraryBloc();
    final connectivityCubit = MockConnectivityCubit();
    const item = ItineraryItemEntity(
      id: 'item1',
      tripId: 'trip1',
      title: 'Museum Visit',
      sortOrder: 0,
    );

    const state = ItineraryState(
      status: ItineraryStatus.loaded,
      items: [item],
      tripId: 'trip1',
    );

    when(() => itineraryBloc.state).thenReturn(state);
    whenListen(itineraryBloc, Stream<ItineraryState>.value(state), initialState: state);

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
          BlocProvider<ItineraryBloc>.value(value: itineraryBloc),
          BlocProvider<ConnectivityCubit>.value(value: connectivityCubit),
        ],
        child: const MaterialApp(
          home: ItineraryTab(trip: TripEntity(id: 'trip1', title: 'Trip')),
        ),
      ),
    );

    await tester.pump();

    expect(find.text('Museum Visit'), findsOneWidget);
  });
}
