import 'package:equatable/equatable.dart';

class PollOptionEntity extends Equatable {
  final String id;
  final String text;
  final int voteCount;

  const PollOptionEntity({
    required this.id,
    required this.text,
    required this.voteCount,
  });

  @override
  List<Object?> get props => [id, text, voteCount];
}
