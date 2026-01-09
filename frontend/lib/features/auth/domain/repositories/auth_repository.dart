import '../entities/user.dart';

abstract class AuthRepository {
  Future<UserEntity> login({required String email, required String password});
  Future<UserEntity> register({required String email, required String password, String? name});
  Future<UserEntity> getMe();
  Future<void> logout();
  Future<bool> hasTokens();
}
