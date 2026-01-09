part of 'trips_bloc.dart';

enum TripsStatus { initial, loading, loaded, error }

class TripsState extends Equatable {
  final TripsStatus status;
  final List<TripEntity> trips;
  final String? message;
  final bool isRefreshing;

  const TripsState({
    this.status = TripsStatus.initial,
    this.trips = const [],
    this.message,
    this.isRefreshing = false,
  });

  TripsState copyWith({
    TripsStatus? status,
    List<TripEntity>? trips,
    String? message,
    bool? isRefreshing,
  }) {
    return TripsState(
      status: status ?? this.status,
      trips: trips ?? this.trips,
      message: message,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }

  @override
  List<Object?> get props => [status, trips, message, isRefreshing];
}
