part of 'collaborators_bloc.dart';

abstract class CollaboratorsEvent extends Equatable {
  const CollaboratorsEvent();

  @override
  List<Object?> get props => [];
}

class CollaboratorsStarted extends CollaboratorsEvent {
  final String tripId;

  const CollaboratorsStarted({required this.tripId});

  @override
  List<Object?> get props => [tripId];
}

class CollaboratorsRefreshed extends CollaboratorsEvent {
  final String tripId;

  const CollaboratorsRefreshed({required this.tripId});

  @override
  List<Object?> get props => [tripId];
}

class InviteSent extends CollaboratorsEvent {
  final String tripId;
  final String email;
  final String role;

  const InviteSent({
    required this.tripId,
    required this.email,
    required this.role,
  });

  @override
  List<Object?> get props => [tripId, email, role];
}

class InviteRevoked extends CollaboratorsEvent {
  final String inviteId;

  const InviteRevoked({required this.inviteId});

  @override
  List<Object?> get props => [inviteId];
}

class CollaboratorsSearchRequested extends CollaboratorsEvent {
  final String tripId;
  final String query;

  const CollaboratorsSearchRequested({
    required this.tripId,
    required this.query,
  });

  @override
  List<Object?> get props => [tripId, query];
}
