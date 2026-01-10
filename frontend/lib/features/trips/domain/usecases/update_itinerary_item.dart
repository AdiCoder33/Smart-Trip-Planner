import '../entities/itinerary_item.dart';
import '../repositories/itinerary_repository.dart';

class UpdateItineraryItem {
  final ItineraryRepository repository;

  const UpdateItineraryItem(this.repository);

  Future<ItineraryItemEntity> call({
    required String itemId,
    required String tripId,
    String? title,
    String? notes,
    String? location,
    String? startTime,
    String? endTime,
    DateTime? date,
  }) {
    return repository.updateItem(
      itemId: itemId,
      tripId: tripId,
      title: title,
      notes: notes,
      location: location,
      startTime: startTime,
      endTime: endTime,
      date: date,
    );
  }
}
