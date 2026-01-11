import '../../domain/entities/user_lookup.dart';

class UserLookupModel extends UserLookupEntity {
  const UserLookupModel({
    required super.id,
    required super.email,
    super.name,
  });

  factory UserLookupModel.fromJson(Map<String, dynamic> json) {
    return UserLookupModel(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String?,
    );
  }
}
