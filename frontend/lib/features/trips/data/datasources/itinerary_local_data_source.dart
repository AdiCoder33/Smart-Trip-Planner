import 'package:hive/hive.dart';

import '../models/itinerary_item_model.dart';

class ItineraryLocalDataSource {
  final Box<ItineraryItemModel> box;

  const ItineraryLocalDataSource(this.box);

  Future<List<ItineraryItemModel>> getItems(String tripId) async {
    final items = box.values.where((item) => item.tripId == tripId).toList();
    items.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return items;
  }

  Future<void> cacheItems(String tripId, List<ItineraryItemModel> items) async {
    final idsToRemove = box.values
        .where((item) => item.tripId == tripId)
        .map((item) => item.id)
        .toList();
    await box.deleteAll(idsToRemove);
    final map = {for (final item in items) item.id: item};
    await box.putAll(map);
  }

  Future<void> upsertItem(ItineraryItemModel item) async {
    await box.put(item.id, item);
  }

  Future<void> deleteItem(String id) async {
    await box.delete(id);
  }
}
