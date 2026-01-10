import '../entities/itinerary_item.dart';
import '../repositories/itinerary_repository.dart';

class GetCachedItineraryItems {
  final ItineraryRepository repository;

  const GetCachedItineraryItems(this.repository);

  Future<List<ItineraryItemEntity>> call(String tripId) {
    return repository.getCachedItems(tripId);
  }
}
