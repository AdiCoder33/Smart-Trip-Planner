import '../entities/itinerary_item.dart';
import '../repositories/itinerary_repository.dart';

class GetItineraryItems {
  final ItineraryRepository repository;

  const GetItineraryItems(this.repository);

  Future<List<ItineraryItemEntity>> call(String tripId) {
    return repository.getItems(tripId);
  }
}
