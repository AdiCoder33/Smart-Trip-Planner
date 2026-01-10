import 'package:equatable/equatable.dart';

class TripInviteEntity extends Equatable {
  final String id;
  final String email;
  final String role;
  final String status;
  final String invitedBy;
  final DateTime? createdAt;
  final DateTime? expiresAt;

  const TripInviteEntity({
    required this.id,
    required this.email,
    required this.role,
    required this.status,
    required this.invitedBy,
    this.createdAt,
    this.expiresAt,
  });

  @override
  List<Object?> get props => [id, email, role, status, invitedBy, createdAt, expiresAt];
}
