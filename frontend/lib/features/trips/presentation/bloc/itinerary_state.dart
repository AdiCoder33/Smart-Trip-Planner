part of 'itinerary_bloc.dart';

enum ItineraryStatus { initial, loading, loaded, error }

class ItineraryState extends Equatable {
  final ItineraryStatus status;
  final List<ItineraryItemEntity> items;
  final bool isRefreshing;
  final bool isSyncing;
  final String? message;
  final String? tripId;

  const ItineraryState({
    this.status = ItineraryStatus.initial,
    this.items = const [],
    this.isRefreshing = false,
    this.isSyncing = false,
    this.message,
    this.tripId,
  });

  ItineraryState copyWith({
    ItineraryStatus? status,
    List<ItineraryItemEntity>? items,
    bool? isRefreshing,
    bool? isSyncing,
    String? message,
    String? tripId,
  }) {
    return ItineraryState(
      status: status ?? this.status,
      items: items ?? this.items,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isSyncing: isSyncing ?? this.isSyncing,
      message: message,
      tripId: tripId ?? this.tripId,
    );
  }

  @override
  List<Object?> get props => [status, items, isRefreshing, isSyncing, message, tripId];
}
