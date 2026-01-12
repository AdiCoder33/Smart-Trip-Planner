import '../../../../core/errors/error_mapper.dart';
import '../../domain/entities/trip.dart';
import '../../domain/repositories/trips_repository.dart';
import '../datasources/trips_local_data_source.dart';
import '../datasources/trips_remote_data_source.dart';

class TripsRepositoryImpl implements TripsRepository {
  final TripsRemoteDataSource remoteDataSource;
  final TripsLocalDataSource localDataSource;

  const TripsRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<List<TripEntity>> getCachedTrips() async {
    final trips = await localDataSource.getTrips();
    trips.sort((a, b) => (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
    return trips;
  }

  @override
  Future<List<TripEntity>> getTrips() async {
    try {
      final trips = await remoteDataSource.fetchTrips();
      await localDataSource.cacheTrips(trips);
      trips.sort((a, b) => (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
      return trips;
    } catch (error) {
      throw mapDioError(error);
    }
  }

  @override
  Future<TripEntity> createTrip({
    required String title,
    String? destination,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final trip = await remoteDataSource.createTrip(
        title: title,
        destination: destination,
        startDate: startDate,
        endDate: endDate,
      );
      await localDataSource.upsertTrip(trip);
      return trip;
    } catch (error) {
      throw mapDioError(error);
    }
  }

  @override
  Future<TripEntity> updateTrip({
    required String tripId,
    required String title,
    String? destination,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final trip = await remoteDataSource.updateTrip(
        tripId: tripId,
        title: title,
        destination: destination,
        startDate: startDate,
        endDate: endDate,
      );
      await localDataSource.upsertTrip(trip);
      return trip;
    } catch (error) {
      throw mapDioError(error);
    }
  }

  @override
  Future<void> deleteTrip({required String tripId}) async {
    try {
      await remoteDataSource.deleteTrip(tripId);
      await localDataSource.deleteTrip(tripId);
    } catch (error) {
      throw mapDioError(error);
    }
  }
}
