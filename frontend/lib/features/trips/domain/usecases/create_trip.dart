import '../entities/trip.dart';
import '../repositories/trips_repository.dart';

class CreateTrip {
  final TripsRepository repository;

  const CreateTrip(this.repository);

  Future<TripEntity> call({
    required String title,
    String? destination,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return repository.createTrip(
      title: title,
      destination: destination,
      startDate: startDate,
      endDate: endDate,
    );
  }
}
