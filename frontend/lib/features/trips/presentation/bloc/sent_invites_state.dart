part of 'sent_invites_cubit.dart';

enum SentInvitesStatus { initial, loading, loaded, error }

class SentInvitesState extends Equatable {
  final SentInvitesStatus status;
  final List<TripInviteEntity> invites;
  final String? message;

  const SentInvitesState({
    this.status = SentInvitesStatus.initial,
    this.invites = const [],
    this.message,
  });

  SentInvitesState copyWith({
    SentInvitesStatus? status,
    List<TripInviteEntity>? invites,
    String? message,
  }) {
    return SentInvitesState(
      status: status ?? this.status,
      invites: invites ?? this.invites,
      message: message,
    );
  }

  @override
  List<Object?> get props => [status, invites, message];
}
