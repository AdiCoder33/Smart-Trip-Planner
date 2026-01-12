import 'package:hive/hive.dart';

import '../models/trip_model.dart';

class TripsLocalDataSource {
  final Box<TripModel> box;

  const TripsLocalDataSource(this.box);

  Future<List<TripModel>> getTrips() async {
    return box.values.toList();
  }

  Future<void> cacheTrips(List<TripModel> trips) async {
    final map = {for (final trip in trips) trip.id: trip};
    await box.clear();
    await box.putAll(map);
  }

  Future<void> upsertTrip(TripModel trip) async {
    await box.put(trip.id, trip);
  }

  Future<void> deleteTrip(String tripId) async {
    await box.delete(tripId);
  }
}
