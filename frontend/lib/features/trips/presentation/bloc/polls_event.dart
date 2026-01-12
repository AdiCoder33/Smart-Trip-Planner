part of 'polls_bloc.dart';

abstract class PollsEvent extends Equatable {
  const PollsEvent();

  @override
  List<Object?> get props => [];
}

class PollsStarted extends PollsEvent {
  final String tripId;

  const PollsStarted({required this.tripId});

  @override
  List<Object?> get props => [tripId];
}

class PollsRefreshed extends PollsEvent {
  final String tripId;

  const PollsRefreshed({required this.tripId});

  @override
  List<Object?> get props => [tripId];
}

class PollCreated extends PollsEvent {
  final String tripId;
  final String question;
  final List<String> options;

  const PollCreated({
    required this.tripId,
    required this.question,
    required this.options,
  });

  @override
  List<Object?> get props => [tripId, question, options];
}

class PollVoted extends PollsEvent {
  final String tripId;
  final String pollId;
  final String optionId;

  const PollVoted({
    required this.tripId,
    required this.pollId,
    required this.optionId,
  });

  @override
  List<Object?> get props => [tripId, pollId, optionId];
}

class PollUpdated extends PollsEvent {
  final String tripId;
  final String pollId;
  final String question;
  final List<String> options;

  const PollUpdated({
    required this.tripId,
    required this.pollId,
    required this.question,
    required this.options,
  });

  @override
  List<Object?> get props => [tripId, pollId, question, options];
}

class PollDeleted extends PollsEvent {
  final String tripId;
  final String pollId;

  const PollDeleted({required this.tripId, required this.pollId});

  @override
  List<Object?> get props => [tripId, pollId];
}

class PollsSyncRequested extends PollsEvent {
  final String tripId;

  const PollsSyncRequested({required this.tripId});

  @override
  List<Object?> get props => [tripId];
}
