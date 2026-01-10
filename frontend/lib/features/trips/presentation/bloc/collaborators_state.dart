part of 'collaborators_bloc.dart';

enum CollaboratorsStatus { initial, loading, loaded, error }

class CollaboratorsState extends Equatable {
  final CollaboratorsStatus status;
  final List<TripMemberEntity> members;
  final List<TripInviteEntity> invites;
  final bool isRefreshing;
  final String? message;
  final String? tripId;

  const CollaboratorsState({
    this.status = CollaboratorsStatus.initial,
    this.members = const [],
    this.invites = const [],
    this.isRefreshing = false,
    this.message,
    this.tripId,
  });

  CollaboratorsState copyWith({
    CollaboratorsStatus? status,
    List<TripMemberEntity>? members,
    List<TripInviteEntity>? invites,
    bool? isRefreshing,
    String? message,
    String? tripId,
  }) {
    return CollaboratorsState(
      status: status ?? this.status,
      members: members ?? this.members,
      invites: invites ?? this.invites,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      message: message,
      tripId: tripId ?? this.tripId,
    );
  }

  @override
  List<Object?> get props => [status, members, invites, isRefreshing, message, tripId];
}
