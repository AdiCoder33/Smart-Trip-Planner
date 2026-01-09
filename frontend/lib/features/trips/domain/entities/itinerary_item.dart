import 'package:equatable/equatable.dart';

class ItineraryItemEntity extends Equatable {
  final String id;
  final String tripId;
  final String title;
  final String? notes;
  final String? location;
  final String? startTime;
  final String? endTime;
  final DateTime? date;
  final int sortOrder;
  final String? createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool isPending;

  const ItineraryItemEntity({
    required this.id,
    required this.tripId,
    required this.title,
    required this.sortOrder,
    this.notes,
    this.location,
    this.startTime,
    this.endTime,
    this.date,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
    this.isPending = false,
  });

  ItineraryItemEntity copyWith({
    String? id,
    String? tripId,
    String? title,
    String? notes,
    String? location,
    String? startTime,
    String? endTime,
    DateTime? date,
    int? sortOrder,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isPending,
  }) {
    return ItineraryItemEntity(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      title: title ?? this.title,
      notes: notes ?? this.notes,
      location: location ?? this.location,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      date: date ?? this.date,
      sortOrder: sortOrder ?? this.sortOrder,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isPending: isPending ?? this.isPending,
    );
  }

  @override
  List<Object?> get props => [
        id,
        tripId,
        title,
        notes,
        location,
        startTime,
        endTime,
        date,
        sortOrder,
        createdBy,
        createdAt,
        updatedAt,
        isPending,
      ];
}
