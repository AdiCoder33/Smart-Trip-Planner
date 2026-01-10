import 'package:equatable/equatable.dart';

class TripMemberEntity extends Equatable {
  final String id;
  final String userId;
  final String email;
  final String? name;
  final String role;
  final String status;
  final DateTime? createdAt;

  const TripMemberEntity({
    required this.id,
    required this.userId,
    required this.email,
    this.name,
    required this.role,
    required this.status,
    this.createdAt,
  });

  @override
  List<Object?> get props => [id, userId, email, name, role, status, createdAt];
}
