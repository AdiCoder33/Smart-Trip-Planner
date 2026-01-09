import 'package:hive/hive.dart';

import '../../domain/entities/trip.dart';

class TripModel extends TripEntity {
  const TripModel({
    required super.id,
    required super.title,
    super.destination,
    super.startDate,
    super.endDate,
    super.createdAt,
    super.updatedAt,
    super.isPending = false,
  });

  factory TripModel.fromJson(Map<String, dynamic> json) {
    return TripModel(
      id: json['id'] as String,
      title: json['title'] as String,
      destination: json['destination'] as String?,
      startDate: json['start_date'] != null ? DateTime.parse(json['start_date']) : null,
      endDate: json['end_date'] != null ? DateTime.parse(json['end_date']) : null,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'destination': destination,
      'start_date': startDate?.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  TripModel copyWith({
    String? id,
    String? title,
    String? destination,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isPending,
  }) {
    return TripModel(
      id: id ?? this.id,
      title: title ?? this.title,
      destination: destination ?? this.destination,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isPending: isPending ?? this.isPending,
    );
  }

  static TripModel fromEntity(TripEntity entity) {
    return TripModel(
      id: entity.id,
      title: entity.title,
      destination: entity.destination,
      startDate: entity.startDate,
      endDate: entity.endDate,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      isPending: entity.isPending,
    );
  }
}

class TripModelAdapter extends TypeAdapter<TripModel> {
  @override
  final int typeId = 1;

  @override
  TripModel read(BinaryReader reader) {
    final id = reader.read() as String;
    final title = reader.read() as String;
    final destination = reader.read() as String?;
    final startDate = reader.read() as DateTime?;
    final endDate = reader.read() as DateTime?;
    final createdAt = reader.read() as DateTime?;
    final updatedAt = reader.read() as DateTime?;

    return TripModel(
      id: id,
      title: title,
      destination: destination,
      startDate: startDate,
      endDate: endDate,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  @override
  void write(BinaryWriter writer, TripModel obj) {
    writer
      ..write(obj.id)
      ..write(obj.title)
      ..write(obj.destination)
      ..write(obj.startDate)
      ..write(obj.endDate)
      ..write(obj.createdAt)
      ..write(obj.updatedAt);
  }
}
