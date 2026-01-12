import '../repositories/itinerary_repository.dart';

class DeleteItineraryItem {
  final ItineraryRepository repository;

  const DeleteItineraryItem(this.repository);

  Future<void> call({
    required String itemId,
    required String tripId,
  }) {
    return repository.deleteItem(itemId: itemId, tripId: tripId);
  }
}
