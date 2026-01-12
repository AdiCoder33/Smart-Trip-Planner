import '../entities/itinerary_item.dart';

abstract class ItineraryRepository {
  Future<List<ItineraryItemEntity>> getCachedItems(String tripId);
  Future<List<ItineraryItemEntity>> getItems(String tripId);
  Future<ItineraryItemEntity> createItem({
    required String tripId,
    required String title,
    String? notes,
    String? location,
    String? startTime,
    String? endTime,
    DateTime? date,
  });
  Future<ItineraryItemEntity> updateItem({
    required String itemId,
    required String tripId,
    String? title,
    String? notes,
    String? location,
    String? startTime,
    String? endTime,
    DateTime? date,
  });
  Future<void> deleteItem({
    required String itemId,
    required String tripId,
  });
  Future<List<ItineraryItemEntity>> reorderItems({
    required String tripId,
    required List<Map<String, dynamic>> items,
  });
  Future<void> cacheLocalItems(String tripId, List<ItineraryItemEntity> items);
  Future<void> upsertLocalItem(ItineraryItemEntity item);
  Future<void> deleteLocalItem(String itemId);
}
