import 'package:hive/hive.dart';

import '../../domain/entities/poll_option.dart';

class PollOptionModel extends PollOptionEntity {
  const PollOptionModel({
    required super.id,
    required super.text,
    required super.voteCount,
  });

  factory PollOptionModel.fromJson(Map<String, dynamic> json) {
    return PollOptionModel(
      id: json['id'] as String,
      text: json['text'] as String,
      voteCount: json['vote_count'] as int? ?? 0,
    );
  }
}

class PollOptionModelAdapter extends TypeAdapter<PollOptionModel> {
  @override
  final int typeId = 3;

  @override
  PollOptionModel read(BinaryReader reader) {
    final id = reader.read() as String;
    final text = reader.read() as String;
    final voteCount = reader.read() as int;
    return PollOptionModel(id: id, text: text, voteCount: voteCount);
  }

  @override
  void write(BinaryWriter writer, PollOptionModel obj) {
    writer
      ..write(obj.id)
      ..write(obj.text)
      ..write(obj.voteCount);
  }
}
