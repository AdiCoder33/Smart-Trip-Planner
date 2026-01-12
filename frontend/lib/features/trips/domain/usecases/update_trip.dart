import '../entities/trip.dart';
import '../repositories/trips_repository.dart';

class UpdateTrip {
  final TripsRepository repository;

  const UpdateTrip(this.repository);

  Future<TripEntity> call({
    required String tripId,
    required String title,
    String? destination,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return repository.updateTrip(
      tripId: tripId,
      title: title,
      destination: destination,
      startDate: startDate,
      endDate: endDate,
    );
  }
}
