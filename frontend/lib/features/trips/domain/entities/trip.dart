import 'package:equatable/equatable.dart';

class TripEntity extends Equatable {
  final String id;
  final String title;
  final String? destination;
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool isPending;

  const TripEntity({
    required this.id,
    required this.title,
    this.destination,
    this.startDate,
    this.endDate,
    this.createdAt,
    this.updatedAt,
    this.isPending = false,
  });

  @override
  List<Object?> get props => [
        id,
        title,
        destination,
        startDate,
        endDate,
        createdAt,
        updatedAt,
        isPending,
      ];
}
