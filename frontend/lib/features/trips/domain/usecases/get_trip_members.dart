import '../entities/trip_member.dart';
import '../repositories/collaborators_repository.dart';

class GetTripMembers {
  final CollaboratorsRepository repository;

  const GetTripMembers(this.repository);

  Future<List<TripMemberEntity>> call(String tripId) {
    return repository.getMembers(tripId);
  }
}
