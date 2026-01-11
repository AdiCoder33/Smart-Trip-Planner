import 'package:equatable/equatable.dart';

class UserLookupEntity extends Equatable {
  final String id;
  final String email;
  final String? name;

  const UserLookupEntity({
    required this.id,
    required this.email,
    this.name,
  });

  @override
  List<Object?> get props => [id, email, name];
}
