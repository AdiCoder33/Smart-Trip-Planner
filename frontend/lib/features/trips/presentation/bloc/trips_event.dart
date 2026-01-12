part of 'trips_bloc.dart';

abstract class TripsEvent extends Equatable {
  const TripsEvent();

  @override
  List<Object?> get props => [];
}

class TripsStarted extends TripsEvent {
  const TripsStarted();
}

class TripsRefreshed extends TripsEvent {
  const TripsRefreshed();
}

class TripCreated extends TripsEvent {
  final String title;
  final String? destination;
  final DateTime? startDate;
  final DateTime? endDate;

  const TripCreated({
    required this.title,
    this.destination,
    this.startDate,
    this.endDate,
  });

  @override
  List<Object?> get props => [title, destination, startDate, endDate];
}

class TripUpdated extends TripsEvent {
  final String tripId;
  final String title;
  final String? destination;
  final DateTime? startDate;
  final DateTime? endDate;

  const TripUpdated({
    required this.tripId,
    required this.title,
    this.destination,
    this.startDate,
    this.endDate,
  });

  @override
  List<Object?> get props => [tripId, title, destination, startDate, endDate];
}

class TripDeleted extends TripsEvent {
  final String tripId;

  const TripDeleted({required this.tripId});

  @override
  List<Object?> get props => [tripId];
}
