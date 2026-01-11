import '../entities/trip_invite.dart';
import '../repositories/collaborators_repository.dart';

class DeclineInvite {
  final CollaboratorsRepository repository;

  const DeclineInvite(this.repository);

  Future<TripInviteEntity> call({required String inviteId}) {
    return repository.declineInvite(inviteId: inviteId);
  }
}
