import '../../domain/entities/trip_member.dart';

class TripMemberModel extends TripMemberEntity {
  const TripMemberModel({
    required super.id,
    required super.userId,
    required super.email,
    super.name,
    required super.role,
    required super.status,
    super.createdAt,
  });

  factory TripMemberModel.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>;
    return TripMemberModel(
      id: json['id'] as String,
      userId: user['id'] as String,
      email: user['email'] as String,
      name: user['name'] as String?,
      role: json['role'] as String,
      status: json['status'] as String,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
    );
  }
}
