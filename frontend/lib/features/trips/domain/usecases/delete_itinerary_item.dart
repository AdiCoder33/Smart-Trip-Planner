import '../repositories/itinerary_repository.dart';

class DeleteItineraryItem {
  final ItineraryRepository repository;

  const DeleteItineraryItem(this.repository);

  Future<void> call(String itemId) {
    return repository.deleteItem(itemId);
  }
}
