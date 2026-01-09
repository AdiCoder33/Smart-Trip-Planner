import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/connectivity/connectivity_service.dart';
import '../../../../core/errors/app_exception.dart';
import '../../domain/entities/trip.dart';
import '../../domain/usecases/create_trip.dart';
import '../../domain/usecases/get_cached_trips.dart';
import '../../domain/usecases/get_trips.dart';

part 'trips_event.dart';
part 'trips_state.dart';

class TripsBloc extends Bloc<TripsEvent, TripsState> {
  final GetTrips getTrips;
  final GetCachedTrips getCachedTrips;
  final CreateTrip createTrip;
  final ConnectivityService connectivityService;
  final Uuid _uuid = const Uuid();

  TripsBloc({
    required this.getTrips,
    required this.getCachedTrips,
    required this.createTrip,
    required this.connectivityService,
  }) : super(const TripsState()) {
    on<TripsStarted>(_onStarted);
    on<TripsRefreshed>(_onRefreshed);
    on<TripCreated>(_onCreated);
  }

  Future<void> _onStarted(TripsStarted event, Emitter<TripsState> emit) async {
    emit(state.copyWith(status: TripsStatus.loading, message: null));
    final cached = await getCachedTrips();
    emit(state.copyWith(status: TripsStatus.loading, trips: cached));

    final online = await connectivityService.isOnline();
    if (!online) {
      emit(state.copyWith(status: TripsStatus.loaded));
      return;
    }

    try {
      final remote = await getTrips();
      emit(state.copyWith(status: TripsStatus.loaded, trips: remote));
    } catch (error) {
      final message = error is AppException ? error.message : 'Failed to load trips';
      emit(state.copyWith(status: TripsStatus.error, message: message));
    }
  }

  Future<void> _onRefreshed(TripsRefreshed event, Emitter<TripsState> emit) async {
    final online = await connectivityService.isOnline();
    if (!online) {
      emit(state.copyWith(message: 'You are offline.'));
      return;
    }

    emit(state.copyWith(isRefreshing: true, message: null));
    try {
      final remote = await getTrips();
      emit(state.copyWith(status: TripsStatus.loaded, trips: remote, isRefreshing: false));
    } catch (error) {
      final message = error is AppException ? error.message : 'Failed to refresh trips';
      emit(state.copyWith(isRefreshing: false, message: message));
    }
  }

  Future<void> _onCreated(TripCreated event, Emitter<TripsState> emit) async {
    final online = await connectivityService.isOnline();
    if (!online) {
      emit(state.copyWith(message: 'You are offline. Trip creation is disabled.'));
      return;
    }

    final tempId = 'temp-${_uuid.v4()}';
    final tempTrip = TripEntity(
      id: tempId,
      title: event.title,
      destination: event.destination,
      startDate: event.startDate,
      endDate: event.endDate,
      createdAt: DateTime.now(),
      isPending: true,
    );

    final optimisticTrips = [tempTrip, ...state.trips];
    emit(state.copyWith(trips: optimisticTrips));

    try {
      final created = await createTrip(
        title: event.title,
        destination: event.destination,
        startDate: event.startDate,
        endDate: event.endDate,
      );

      final updatedTrips = optimisticTrips.map((trip) {
        if (trip.id == tempId) {
          return created;
        }
        return trip;
      }).toList();

      emit(state.copyWith(trips: updatedTrips));
    } catch (error) {
      final message = error is AppException ? error.message : 'Failed to create trip';
      final rolledBack = optimisticTrips.where((trip) => trip.id != tempId).toList();
      emit(state.copyWith(trips: rolledBack, message: message));
    }
  }
}
