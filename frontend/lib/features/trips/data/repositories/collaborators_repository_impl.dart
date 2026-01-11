import '../../../../core/errors/error_mapper.dart';
import '../../domain/entities/trip_invite.dart';
import '../../domain/entities/trip_member.dart';
import '../../domain/entities/user_lookup.dart';
import '../../domain/repositories/collaborators_repository.dart';
import '../datasources/collaborators_remote_data_source.dart';

class CollaboratorsRepositoryImpl implements CollaboratorsRepository {
  final CollaboratorsRemoteDataSource remoteDataSource;

  const CollaboratorsRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<TripMemberEntity>> getMembers(String tripId) async {
    try {
      return await remoteDataSource.fetchMembers(tripId);
    } catch (error) {
      throw mapDioError(error);
    }
  }

  @override
  Future<List<TripInviteEntity>> getInvites(String tripId) async {
    try {
      return await remoteDataSource.fetchInvites(tripId);
    } catch (error) {
      throw mapDioError(error);
    }
  }

  @override
  Future<TripInviteEntity> sendInvite({
    required String tripId,
    required String email,
    required String role,
  }) async {
    try {
      return await remoteDataSource.sendInvite(tripId: tripId, email: email, role: role);
    } catch (error) {
      throw mapDioError(error);
    }
  }

  @override
  Future<TripMemberEntity> acceptInvite({required String token}) async {
    try {
      return await remoteDataSource.acceptInvite(token: token);
    } catch (error) {
      throw mapDioError(error);
    }
  }

  @override
  Future<TripInviteEntity> revokeInvite({required String inviteId}) async {
    try {
      return await remoteDataSource.revokeInvite(inviteId: inviteId);
    } catch (error) {
      throw mapDioError(error);
    }
  }

  @override
  Future<List<TripInviteEntity>> getSentInvites() async {
    try {
      return await remoteDataSource.fetchSentInvites();
    } catch (error) {
      throw mapDioError(error);
    }
  }

  @override
  Future<List<UserLookupEntity>> searchUsers({
    required String tripId,
    required String query,
  }) async {
    try {
      return await remoteDataSource.searchUsers(tripId: tripId, query: query);
    } catch (error) {
      throw mapDioError(error);
    }
  }
}
