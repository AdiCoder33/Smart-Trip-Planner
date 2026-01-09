import '../entities/trip.dart';
import '../repositories/trips_repository.dart';

class GetCachedTrips {
  final TripsRepository repository;

  const GetCachedTrips(this.repository);

  Future<List<TripEntity>> call() => repository.getCachedTrips();
}
