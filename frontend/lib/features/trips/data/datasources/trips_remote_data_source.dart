import 'package:dio/dio.dart';

import '../models/trip_model.dart';

class TripsRemoteDataSource {
  final Dio dio;

  const TripsRemoteDataSource(this.dio);

  Future<List<TripModel>> fetchTrips() async {
    final response = await dio.get('/api/trips');
    final data = response.data as List;
    return data.map((item) => TripModel.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<TripModel> createTrip({
    required String title,
    String? destination,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final response = await dio.post('/api/trips', data: {
      'title': title,
      'destination': destination,
      'start_date': startDate?.toIso8601String().split('T').first,
      'end_date': endDate?.toIso8601String().split('T').first,
    });

    return TripModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<TripModel> updateTrip({
    required String tripId,
    required String title,
    String? destination,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final response = await dio.patch('/api/trips/$tripId', data: {
      'title': title,
      'destination': destination,
      'start_date': startDate?.toIso8601String().split('T').first,
      'end_date': endDate?.toIso8601String().split('T').first,
    });

    return TripModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteTrip(String tripId) async {
    await dio.delete('/api/trips/$tripId');
  }
}
