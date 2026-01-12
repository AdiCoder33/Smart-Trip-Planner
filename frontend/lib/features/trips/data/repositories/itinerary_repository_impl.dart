import '../../../../core/errors/error_mapper.dart';
import '../../domain/entities/itinerary_item.dart';
import '../../domain/repositories/itinerary_repository.dart';
import '../datasources/itinerary_local_data_source.dart';
import '../datasources/itinerary_remote_data_source.dart';
import '../models/itinerary_item_model.dart';

class ItineraryRepositoryImpl implements ItineraryRepository {
  final ItineraryRemoteDataSource remoteDataSource;
  final ItineraryLocalDataSource localDataSource;

  const ItineraryRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<List<ItineraryItemEntity>> getCachedItems(String tripId) async {
    return localDataSource.getItems(tripId);
  }

  @override
  Future<List<ItineraryItemEntity>> getItems(String tripId) async {
    try {
      final items = await remoteDataSource.fetchItems(tripId);
      await localDataSource.cacheItems(tripId, items);
      items.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      return items;
    } catch (error) {
      throw mapDioError(error);
    }
  }

  @override
  Future<ItineraryItemEntity> createItem({
    required String tripId,
    required String title,
    String? notes,
    String? location,
    String? startTime,
    String? endTime,
    DateTime? date,
  }) async {
    try {
      final item = await remoteDataSource.createItem(
        tripId: tripId,
        payload: {
          'title': title,
          'notes': notes,
          'location': location,
          'start_time': startTime,
          'end_time': endTime,
          'date': date?.toIso8601String().split('T').first,
        },
      );
      await localDataSource.upsertItem(item);
      return item;
    } catch (error) {
      throw mapDioError(error);
    }
  }

  @override
  Future<ItineraryItemEntity> updateItem({
    required String itemId,
    required String tripId,
    String? title,
    String? notes,
    String? location,
    String? startTime,
    String? endTime,
    DateTime? date,
  }) async {
    try {
      final payload = <String, dynamic>{};
      if (title != null) payload['title'] = title;
      if (notes != null) payload['notes'] = notes;
      if (location != null) payload['location'] = location;
      if (startTime != null) payload['start_time'] = startTime;
      if (endTime != null) payload['end_time'] = endTime;
      if (date != null) payload['date'] = date.toIso8601String().split('T').first;

      final item = await remoteDataSource.updateItem(
        itemId: itemId,
        tripId: tripId,
        payload: payload,
      );
      await localDataSource.upsertItem(item);
      return item;
    } catch (error) {
      throw mapDioError(error);
    }
  }

  @override
  Future<void> deleteItem({
    required String itemId,
    required String tripId,
  }) async {
    try {
      await remoteDataSource.deleteItem(itemId, tripId: tripId);
      await localDataSource.deleteItem(itemId);
    } catch (error) {
      throw mapDioError(error);
    }
  }

  @override
  Future<List<ItineraryItemEntity>> reorderItems({
    required String tripId,
    required List<Map<String, dynamic>> items,
  }) async {
    try {
      final updated = await remoteDataSource.reorderItems(tripId: tripId, items: items);
      await localDataSource.cacheItems(tripId, updated);
      return updated;
    } catch (error) {
      throw mapDioError(error);
    }
  }

  @override
  Future<void> cacheLocalItems(String tripId, List<ItineraryItemEntity> items) async {
    final models = items.map(_toModel).toList();
    await localDataSource.cacheItems(tripId, models);
  }

  @override
  Future<void> upsertLocalItem(ItineraryItemEntity item) async {
    await localDataSource.upsertItem(_toModel(item));
  }

  @override
  Future<void> deleteLocalItem(String itemId) async {
    await localDataSource.deleteItem(itemId);
  }

  ItineraryItemModel _toModel(ItineraryItemEntity item) {
    if (item is ItineraryItemModel) {
      return item;
    }
    return ItineraryItemModel(
      id: item.id,
      tripId: item.tripId,
      title: item.title,
      notes: item.notes,
      location: item.location,
      startTime: item.startTime,
      endTime: item.endTime,
      date: item.date,
      sortOrder: item.sortOrder,
      createdBy: item.createdBy,
      createdAt: item.createdAt,
      updatedAt: item.updatedAt,
      isPending: item.isPending,
    );
  }
}
