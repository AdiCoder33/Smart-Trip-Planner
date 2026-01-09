import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String id;
  final String email;
  final String? name;
  final DateTime? dateJoined;

  const UserEntity({
    required this.id,
    required this.email,
    this.name,
    this.dateJoined,
  });

  @override
  List<Object?> get props => [id, email, name, dateJoined];
}
