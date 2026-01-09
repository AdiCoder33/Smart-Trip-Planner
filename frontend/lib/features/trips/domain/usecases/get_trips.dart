import '../entities/trip.dart';
import '../repositories/trips_repository.dart';

class GetTrips {
  final TripsRepository repository;

  const GetTrips(this.repository);

  Future<List<TripEntity>> call() => repository.getTrips();
}
