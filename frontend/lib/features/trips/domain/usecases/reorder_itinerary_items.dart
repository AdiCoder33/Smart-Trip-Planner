import '../entities/itinerary_item.dart';
import '../repositories/itinerary_repository.dart';

class ReorderItineraryItems {
  final ItineraryRepository repository;

  const ReorderItineraryItems(this.repository);

  Future<List<ItineraryItemEntity>> call({
    required String tripId,
    required List<Map<String, dynamic>> items,
  }) {
    return repository.reorderItems(tripId: tripId, items: items);
  }
}
