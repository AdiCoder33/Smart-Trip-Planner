import '../../domain/entities/trip_invite.dart';

class TripInviteModel extends TripInviteEntity {
  const TripInviteModel({
    required super.id,
    required super.email,
    required super.role,
    required super.status,
    required super.invitedBy,
    super.tripId,
    super.tripTitle,
    super.createdAt,
    super.expiresAt,
  });

  factory TripInviteModel.fromJson(Map<String, dynamic> json) {
    final trip = json['trip'] as Map<String, dynamic>?;
    return TripInviteModel(
      id: json['id'] as String,
      email: json['email'] as String,
      role: json['role'] as String,
      status: json['status'] as String,
      invitedBy: json['invited_by'] as String,
      tripId: trip?['id'] as String?,
      tripTitle: trip?['title'] as String?,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      expiresAt: json['expires_at'] != null ? DateTime.parse(json['expires_at']) : null,
    );
  }
}
