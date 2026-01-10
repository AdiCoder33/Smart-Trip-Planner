part of 'itinerary_bloc.dart';

abstract class ItineraryEvent extends Equatable {
  const ItineraryEvent();

  @override
  List<Object?> get props => [];
}

class ItineraryStarted extends ItineraryEvent {
  final String tripId;

  const ItineraryStarted({required this.tripId});

  @override
  List<Object?> get props => [tripId];
}

class ItineraryRefreshed extends ItineraryEvent {
  final String tripId;

  const ItineraryRefreshed({required this.tripId});

  @override
  List<Object?> get props => [tripId];
}

class ItineraryItemCreated extends ItineraryEvent {
  final String tripId;
  final String title;
  final String? notes;
  final String? location;
  final String? startTime;
  final String? endTime;
  final DateTime? date;

  const ItineraryItemCreated({
    required this.tripId,
    required this.title,
    this.notes,
    this.location,
    this.startTime,
    this.endTime,
    this.date,
  });

  @override
  List<Object?> get props => [tripId, title, notes, location, startTime, endTime, date];
}

class ItineraryItemUpdated extends ItineraryEvent {
  final String tripId;
  final String itemId;
  final String? title;
  final String? notes;
  final String? location;
  final String? startTime;
  final String? endTime;
  final DateTime? date;

  const ItineraryItemUpdated({
    required this.tripId,
    required this.itemId,
    this.title,
    this.notes,
    this.location,
    this.startTime,
    this.endTime,
    this.date,
  });

  @override
  List<Object?> get props => [tripId, itemId, title, notes, location, startTime, endTime, date];
}

class ItineraryItemDeleted extends ItineraryEvent {
  final String itemId;

  const ItineraryItemDeleted({required this.itemId});

  @override
  List<Object?> get props => [itemId];
}

class ItineraryReordered extends ItineraryEvent {
  final String tripId;
  final List<ItineraryItemEntity> items;

  const ItineraryReordered({required this.tripId, required this.items});

  @override
  List<Object?> get props => [tripId, items];
}

class ItinerarySyncRequested extends ItineraryEvent {
  final String tripId;

  const ItinerarySyncRequested({required this.tripId});

  @override
  List<Object?> get props => [tripId];
}
