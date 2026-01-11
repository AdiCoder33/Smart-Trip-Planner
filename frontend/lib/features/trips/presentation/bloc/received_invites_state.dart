part of 'received_invites_cubit.dart';

enum ReceivedInvitesStatus { initial, loading, loaded, error }

class ReceivedInvitesState extends Equatable {
  final ReceivedInvitesStatus status;
  final List<TripInviteEntity> invites;
  final String? message;

  const ReceivedInvitesState({
    this.status = ReceivedInvitesStatus.initial,
    this.invites = const [],
    this.message,
  });

  ReceivedInvitesState copyWith({
    ReceivedInvitesStatus? status,
    List<TripInviteEntity>? invites,
    String? message,
  }) {
    return ReceivedInvitesState(
      status: status ?? this.status,
      invites: invites ?? this.invites,
      message: message,
    );
  }

  @override
  List<Object?> get props => [status, invites, message];
}
