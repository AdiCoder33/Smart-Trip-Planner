import '../entities/trip_invite.dart';
import '../repositories/collaborators_repository.dart';

class GetTripInvites {
  final CollaboratorsRepository repository;

  const GetTripInvites(this.repository);

  Future<List<TripInviteEntity>> call(String tripId) {
    return repository.getInvites(tripId);
  }
}
