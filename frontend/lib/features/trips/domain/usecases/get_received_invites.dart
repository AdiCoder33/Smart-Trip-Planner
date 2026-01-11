import '../entities/trip_invite.dart';
import '../repositories/collaborators_repository.dart';

class GetReceivedInvites {
  final CollaboratorsRepository repository;

  const GetReceivedInvites(this.repository);

  Future<List<TripInviteEntity>> call() {
    return repository.getReceivedInvites();
  }
}
