import 'package:hive/hive.dart';

import '../../domain/entities/itinerary_item.dart';

class ItineraryItemModel extends ItineraryItemEntity {
  const ItineraryItemModel({
    required super.id,
    required super.tripId,
    required super.title,
    required super.sortOrder,
    super.notes,
    super.location,
    super.startTime,
    super.endTime,
    super.date,
    super.createdBy,
    super.createdAt,
    super.updatedAt,
    super.isPending = false,
  });

  factory ItineraryItemModel.fromJson(
    Map<String, dynamic> json, {
    required String tripId,
  }) {
    return ItineraryItemModel(
      id: json['id'] as String,
      tripId: tripId,
      title: json['title'] as String,
      notes: json['notes'] as String?,
      location: json['location'] as String?,
      startTime: json['start_time'] as String?,
      endTime: json['end_time'] as String?,
      date: json['date'] != null ? DateTime.parse(json['date']) : null,
      sortOrder: json['sort_order'] as int? ?? 0,
      createdBy: json['created_by'] as String?,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'notes': notes,
      'location': location,
      'start_time': startTime,
      'end_time': endTime,
      'date': date?.toIso8601String().split('T').first,
    };
  }

  @override
  ItineraryItemModel copyWith({
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
    return ItineraryItemModel(
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
}

class ItineraryItemModelAdapter extends TypeAdapter<ItineraryItemModel> {
  @override
  final int typeId = 2;

  @override
  ItineraryItemModel read(BinaryReader reader) {
    final id = reader.read() as String;
    final tripId = reader.read() as String;
    final title = reader.read() as String;
    final notes = reader.read() as String?;
    final location = reader.read() as String?;
    final startTime = reader.read() as String?;
    final endTime = reader.read() as String?;
    final date = reader.read() as DateTime?;
    final sortOrder = reader.read() as int;
    final createdBy = reader.read() as String?;
    final createdAt = reader.read() as DateTime?;
    final updatedAt = reader.read() as DateTime?;
    final isPending = reader.read() as bool;

    return ItineraryItemModel(
      id: id,
      tripId: tripId,
      title: title,
      notes: notes,
      location: location,
      startTime: startTime,
      endTime: endTime,
      date: date,
      sortOrder: sortOrder,
      createdBy: createdBy,
      createdAt: createdAt,
      updatedAt: updatedAt,
      isPending: isPending,
    );
  }

  @override
  void write(BinaryWriter writer, ItineraryItemModel obj) {
    writer
      ..write(obj.id)
      ..write(obj.tripId)
      ..write(obj.title)
      ..write(obj.notes)
      ..write(obj.location)
      ..write(obj.startTime)
      ..write(obj.endTime)
      ..write(obj.date)
      ..write(obj.sortOrder)
      ..write(obj.createdBy)
      ..write(obj.createdAt)
      ..write(obj.updatedAt)
      ..write(obj.isPending);
  }
}
