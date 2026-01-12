import '../repositories/trips_repository.dart';

class DeleteTrip {
  final TripsRepository repository;

  const DeleteTrip(this.repository);

  Future<void> call({required String tripId}) {
    return repository.deleteTrip(tripId: tripId);
  }
}
