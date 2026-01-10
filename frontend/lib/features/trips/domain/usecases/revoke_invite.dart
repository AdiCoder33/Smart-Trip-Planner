import '../entities/trip_invite.dart';
import '../repositories/collaborators_repository.dart';

class RevokeInvite {
  final CollaboratorsRepository repository;

  const RevokeInvite(this.repository);

  Future<TripInviteEntity> call({required String inviteId}) {
    return repository.revokeInvite(inviteId: inviteId);
  }
}
