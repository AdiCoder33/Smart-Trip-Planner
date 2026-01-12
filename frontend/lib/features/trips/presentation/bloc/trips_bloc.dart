import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/connectivity/connectivity_service.dart';
import '../../../../core/errors/app_exception.dart';
import '../../domain/entities/trip.dart';
import '../../domain/usecases/create_trip.dart';
import '../../domain/usecases/delete_trip.dart';
import '../../domain/usecases/get_cached_trips.dart';
import '../../domain/usecases/get_trips.dart';
import '../../domain/usecases/update_trip.dart';

part 'trips_event.dart';
part 'trips_state.dart';

class TripsBloc extends Bloc<TripsEvent, TripsState> {
  final GetTrips getTrips;
  final GetCachedTrips getCachedTrips;
  final CreateTrip createTrip;
  final UpdateTrip updateTrip;
  final DeleteTrip deleteTrip;
  final ConnectivityService connectivityService;
  final Uuid _uuid = const Uuid();

  TripsBloc({
    required this.getTrips,
    required this.getCachedTrips,
    required this.createTrip,
    required this.updateTrip,
    required this.deleteTrip,
    required this.connectivityService,
  }) : super(const TripsState()) {
    on<TripsStarted>(_onStarted);
    on<TripsRefreshed>(_onRefreshed);
    on<TripCreated>(_onCreated);
    on<TripUpdated>(_onUpdated);
    on<TripDeleted>(_onDeleted);
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

  Future<void> _onUpdated(TripUpdated event, Emitter<TripsState> emit) async {
    final online = await connectivityService.isOnline();
    if (!online) {
      emit(state.copyWith(message: 'You are offline. Trip editing is disabled.'));
      return;
    }
    final previous = state.trips;
    final optimistic = previous.map((trip) {
      if (trip.id != event.tripId) return trip;
      return TripEntity(
        id: trip.id,
        title: event.title,
        destination: event.destination,
        startDate: event.startDate,
        endDate: event.endDate,
        createdAt: trip.createdAt,
        updatedAt: DateTime.now(),
        isPending: false,
      );
    }).toList();
    emit(state.copyWith(trips: optimistic));

    try {
      final updated = await updateTrip(
        tripId: event.tripId,
        title: event.title,
        destination: event.destination,
        startDate: event.startDate,
        endDate: event.endDate,
      );
      final updatedTrips = optimistic.map((trip) {
        if (trip.id == updated.id) {
          return updated;
        }
        return trip;
      }).toList();
      emit(state.copyWith(trips: updatedTrips));
    } catch (error) {
      final message = error is AppException ? error.message : 'Failed to update trip';
      emit(state.copyWith(trips: previous, message: message));
    }
  }

  Future<void> _onDeleted(TripDeleted event, Emitter<TripsState> emit) async {
    final online = await connectivityService.isOnline();
    if (!online) {
      emit(state.copyWith(message: 'You are offline. Trip deletion is disabled.'));
      return;
    }
    final previous = state.trips;
    final updated = previous.where((trip) => trip.id != event.tripId).toList();
    emit(state.copyWith(trips: updated));

    try {
      await deleteTrip(tripId: event.tripId);
    } catch (error) {
      final message = error is AppException ? error.message : 'Failed to delete trip';
      emit(state.copyWith(trips: previous, message: message));
    }
  }
}
