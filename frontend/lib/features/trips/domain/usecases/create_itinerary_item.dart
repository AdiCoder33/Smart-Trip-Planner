import '../entities/itinerary_item.dart';
import '../repositories/itinerary_repository.dart';

class CreateItineraryItem {
  final ItineraryRepository repository;

  const CreateItineraryItem(this.repository);

  Future<ItineraryItemEntity> call({
    required String tripId,
    required String title,
    String? notes,
    String? location,
    String? startTime,
    String? endTime,
    DateTime? date,
  }) {
    return repository.createItem(
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
