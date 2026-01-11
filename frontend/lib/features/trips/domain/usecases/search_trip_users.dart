import '../entities/user_lookup.dart';
import '../repositories/collaborators_repository.dart';

class SearchTripUsers {
  final CollaboratorsRepository repository;

  const SearchTripUsers(this.repository);

  Future<List<UserLookupEntity>> call({
    required String tripId,
    required String query,
  }) {
    return repository.searchUsers(tripId: tripId, query: query);
  }
}
