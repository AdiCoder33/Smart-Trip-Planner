import '../entities/trip_invite.dart';
import '../entities/trip_member.dart';

abstract class CollaboratorsRepository {
  Future<List<TripMemberEntity>> getMembers(String tripId);
  Future<List<TripInviteEntity>> getInvites(String tripId);
  Future<TripInviteEntity> sendInvite({
    required String tripId,
    required String email,
    required String role,
  });
  Future<TripMemberEntity> acceptInvite({required String token});
  Future<TripInviteEntity> revokeInvite({required String inviteId});
}
