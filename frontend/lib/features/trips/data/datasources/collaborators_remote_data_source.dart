import 'package:dio/dio.dart';

import '../models/trip_invite_model.dart';
import '../models/trip_member_model.dart';
import '../models/user_lookup_model.dart';

class CollaboratorsRemoteDataSource {
  final Dio dio;

  const CollaboratorsRemoteDataSource(this.dio);

  Future<List<TripMemberModel>> fetchMembers(String tripId) async {
    final response = await dio.get('/api/trips/$tripId/members');
    final data = response.data as List;
    return data.map((item) => TripMemberModel.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<List<TripInviteModel>> fetchInvites(String tripId) async {
    final response = await dio.get('/api/trips/$tripId/invites');
    final data = response.data as List;
    return data.map((item) => TripInviteModel.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<TripInviteModel> sendInvite({
    required String tripId,
    required String email,
    required String role,
  }) async {
    final response = await dio.post('/api/trips/$tripId/invites', data: {
      'email': email,
      'role': role,
    });
    return TripInviteModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<TripMemberModel> acceptInvite({required String token}) async {
    final response = await dio.post('/api/invites/accept', data: {'token': token});
    return TripMemberModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<TripInviteModel> revokeInvite({required String inviteId}) async {
    final response = await dio.post('/api/invites/revoke', data: {'invite_id': inviteId});
    return TripInviteModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<TripInviteModel> acceptInviteById({required String inviteId}) async {
    final response = await dio.post('/api/invites/accept-by-id', data: {'invite_id': inviteId});
    return TripInviteModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<TripInviteModel> declineInvite({required String inviteId}) async {
    final response = await dio.post('/api/invites/decline', data: {'invite_id': inviteId});
    return TripInviteModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<TripInviteModel>> fetchSentInvites() async {
    final response = await dio.get('/api/invites/sent');
    final data = response.data as List;
    return data.map((item) => TripInviteModel.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<List<TripInviteModel>> fetchReceivedInvites() async {
    final response = await dio.get('/api/invites/received');
    final data = response.data as List;
    return data.map((item) => TripInviteModel.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<List<UserLookupModel>> searchUsers({
    required String tripId,
    required String query,
  }) async {
    final response = await dio.get('/api/trips/$tripId/user-search', queryParameters: {
      'q': query,
    });
    final data = response.data as List;
    return data.map((item) => UserLookupModel.fromJson(item as Map<String, dynamic>)).toList();
  }
}
