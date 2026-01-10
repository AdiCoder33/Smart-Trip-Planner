import '../entities/trip_invite.dart';
import '../repositories/collaborators_repository.dart';

class SendTripInvite {
  final CollaboratorsRepository repository;

  const SendTripInvite(this.repository);

  Future<TripInviteEntity> call({
    required String tripId,
    required String email,
    required String role,
  }) {
    return repository.sendInvite(tripId: tripId, email: email, role: role);
  }
}
