import '../entities/itinerary_item.dart';
import '../repositories/itinerary_repository.dart';

class CacheItineraryItems {
  final ItineraryRepository repository;

  const CacheItineraryItems(this.repository);

  Future<void> call(String tripId, List<ItineraryItemEntity> items) {
    return repository.cacheLocalItems(tripId, items);
  }
}
