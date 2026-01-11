import '../entities/trip_invite.dart';
import '../repositories/collaborators_repository.dart';

class GetSentInvites {
  final CollaboratorsRepository repository;

  const GetSentInvites(this.repository);

  Future<List<TripInviteEntity>> call() {
    return repository.getSentInvites();
  }
}
