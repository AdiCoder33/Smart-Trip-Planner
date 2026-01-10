import '../entities/itinerary_item.dart';
import '../repositories/itinerary_repository.dart';

class UpsertLocalItineraryItem {
  final ItineraryRepository repository;

  const UpsertLocalItineraryItem(this.repository);

  Future<void> call(ItineraryItemEntity item) {
    return repository.upsertLocalItem(item);
  }
}
