import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class GetMe {
  final AuthRepository repository;

  const GetMe(this.repository);

  Future<UserEntity> call() => repository.getMe();
}
