import 'package:dio/dio.dart';

import '../models/itinerary_item_model.dart';

class ItineraryRemoteDataSource {
  final Dio dio;

  const ItineraryRemoteDataSource(this.dio);

  Future<List<ItineraryItemModel>> fetchItems(String tripId) async {
    final response = await dio.get('/api/trips/$tripId/itinerary');
    final data = response.data as List;
    return data
        .map(
          (item) => ItineraryItemModel.fromJson(
            item as Map<String, dynamic>,
            tripId: tripId,
          ),
        )
        .toList();
  }

  Future<ItineraryItemModel> createItem({
    required String tripId,
    required Map<String, dynamic> payload,
  }) async {
    final response = await dio.post('/api/trips/$tripId/itinerary', data: payload);
    return ItineraryItemModel.fromJson(response.data as Map<String, dynamic>, tripId: tripId);
  }

  Future<ItineraryItemModel> updateItem({
    required String itemId,
    required Map<String, dynamic> payload,
    required String tripId,
  }) async {
    final response = await dio.patch('/api/itinerary/$itemId', data: payload);
    return ItineraryItemModel.fromJson(response.data as Map<String, dynamic>, tripId: tripId);
  }

  Future<void> deleteItem(String itemId) async {
    await dio.delete('/api/itinerary/$itemId');
  }

  Future<List<ItineraryItemModel>> reorderItems({
    required String tripId,
    required List<Map<String, dynamic>> items,
  }) async {
    final response = await dio.post(
      '/api/trips/$tripId/itinerary/reorder',
      data: {'items': items},
    );
    final data = response.data as List;
    return data
        .map(
          (item) => ItineraryItemModel.fromJson(
            item as Map<String, dynamic>,
            tripId: tripId,
          ),
        )
        .toList();
  }
}
