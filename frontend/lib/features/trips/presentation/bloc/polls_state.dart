part of 'polls_bloc.dart';

enum PollsStatus { initial, loading, loaded, error }

class PollsState extends Equatable {
  final PollsStatus status;
  final List<PollEntity> polls;
  final bool isRefreshing;
  final bool isSyncing;
  final String? message;
  final String? tripId;

  const PollsState({
    this.status = PollsStatus.initial,
    this.polls = const [],
    this.isRefreshing = false,
    this.isSyncing = false,
    this.message,
    this.tripId,
  });

  PollsState copyWith({
    PollsStatus? status,
    List<PollEntity>? polls,
    bool? isRefreshing,
    bool? isSyncing,
    String? message,
    String? tripId,
  }) {
    return PollsState(
      status: status ?? this.status,
      polls: polls ?? this.polls,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isSyncing: isSyncing ?? this.isSyncing,
      message: message,
      tripId: tripId ?? this.tripId,
    );
  }

  @override
  List<Object?> get props => [status, polls, isRefreshing, isSyncing, message, tripId];
}
