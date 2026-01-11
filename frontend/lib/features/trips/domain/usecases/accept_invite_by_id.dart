import '../entities/trip_invite.dart';
import '../repositories/collaborators_repository.dart';

class AcceptInviteById {
  final CollaboratorsRepository repository;

  const AcceptInviteById(this.repository);

  Future<TripInviteEntity> call({required String inviteId}) {
    return repository.acceptInviteById(inviteId: inviteId);
  }
}
