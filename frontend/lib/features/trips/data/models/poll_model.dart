import 'package:hive/hive.dart';

import '../../domain/entities/poll.dart';
import 'poll_option_model.dart';

class PollModel extends PollEntity {
  const PollModel({
    required super.id,
    required super.tripId,
    required super.question,
    required super.isActive,
    required super.options,
    super.userVoteOptionId,
    super.createdAt,
    super.updatedAt,
    super.isPending = false,
  });

  factory PollModel.fromJson(
    Map<String, dynamic> json, {
    required String tripId,
  }) {
    final options = (json['options'] as List? ?? [])
        .map((item) => PollOptionModel.fromJson(item as Map<String, dynamic>))
        .toList();

    return PollModel(
      id: json['id'] as String,
      tripId: tripId,
      question: json['question'] as String,
      isActive: json['is_active'] as bool? ?? true,
      options: options,
      userVoteOptionId: json['user_vote_option_id'] as String?,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    );
  }
}

class PollModelAdapter extends TypeAdapter<PollModel> {
  @override
  final int typeId = 4;

  @override
  PollModel read(BinaryReader reader) {
    final id = reader.read() as String;
    final tripId = reader.read() as String;
    final question = reader.read() as String;
    final isActive = reader.read() as bool;
    final options = (reader.read() as List).cast<PollOptionModel>();
    final userVoteOptionId = reader.read() as String?;
    final createdAt = reader.read() as DateTime?;
    final updatedAt = reader.read() as DateTime?;
    final isPending = reader.read() as bool;

    return PollModel(
      id: id,
      tripId: tripId,
      question: question,
      isActive: isActive,
      options: options,
      userVoteOptionId: userVoteOptionId,
      createdAt: createdAt,
      updatedAt: updatedAt,
      isPending: isPending,
    );
  }

  @override
  void write(BinaryWriter writer, PollModel obj) {
    writer
      ..write(obj.id)
      ..write(obj.tripId)
      ..write(obj.question)
      ..write(obj.isActive)
      ..write(obj.options)
      ..write(obj.userVoteOptionId)
      ..write(obj.createdAt)
      ..write(obj.updatedAt)
      ..write(obj.isPending);
  }
}
