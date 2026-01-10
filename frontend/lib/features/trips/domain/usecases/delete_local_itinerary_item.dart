import '../repositories/itinerary_repository.dart';

class DeleteLocalItineraryItem {
  final ItineraryRepository repository;

  const DeleteLocalItineraryItem(this.repository);

  Future<void> call(String itemId) {
    return repository.deleteLocalItem(itemId);
  }
}
