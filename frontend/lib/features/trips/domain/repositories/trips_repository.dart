import '../entities/trip.dart';

abstract class TripsRepository {
  Future<List<TripEntity>> getCachedTrips();
  Future<List<TripEntity>> getTrips();
  Future<TripEntity> createTrip({
    required String title,
    String? destination,
    DateTime? startDate,
    DateTime? endDate,
  });
  Future<TripEntity> updateTrip({
    required String tripId,
    required String title,
    String? destination,
    DateTime? startDate,
    DateTime? endDate,
  });
  Future<void> deleteTrip({required String tripId});
}
