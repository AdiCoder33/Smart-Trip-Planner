import 'package:equatable/equatable.dart';

import 'poll_option.dart';

class PollEntity extends Equatable {
  final String id;
  final String tripId;
  final String question;
  final bool isActive;
  final List<PollOptionEntity> options;
  final String? userVoteOptionId;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool isPending;

  const PollEntity({
    required this.id,
    required this.tripId,
    required this.question,
    required this.isActive,
    required this.options,
    this.userVoteOptionId,
    this.createdAt,
    this.updatedAt,
    this.isPending = false,
  });

  PollEntity copyWith({
    String? id,
    String? tripId,
    String? question,
    bool? isActive,
    List<PollOptionEntity>? options,
    String? userVoteOptionId,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isPending,
  }) {
    return PollEntity(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      question: question ?? this.question,
      isActive: isActive ?? this.isActive,
      options: options ?? this.options,
      userVoteOptionId: userVoteOptionId ?? this.userVoteOptionId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isPending: isPending ?? this.isPending,
    );
  }

  @override
  List<Object?> get props => [
        id,
        tripId,
        question,
        isActive,
        options,
        userVoteOptionId,
        createdAt,
        updatedAt,
        isPending,
      ];
}
