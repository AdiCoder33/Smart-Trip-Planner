import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class RegisterUser {
  final AuthRepository repository;

  const RegisterUser(this.repository);

  Future<UserEntity> call({
    required String email,
    required String password,
    String? name,
  }) {
    return repository.register(email: email, password: password, name: name);
  }
}
