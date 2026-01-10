import '../entities/trip_member.dart';
import '../repositories/collaborators_repository.dart';

class AcceptInvite {
  final CollaboratorsRepository repository;

  const AcceptInvite(this.repository);

  Future<TripMemberEntity> call({required String token}) {
    return repository.acceptInvite(token: token);
  }
}
