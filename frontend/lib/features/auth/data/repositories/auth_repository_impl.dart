import '../../../../core/errors/error_mapper.dart';
import '../../../../core/storage/token_storage.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final TokenStorage tokenStorage;

  const AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.tokenStorage,
  });

  @override
  Future<UserEntity> login({required String email, required String password}) async {
    try {
      final tokens = await remoteDataSource.login(email: email, password: password);
      await tokenStorage.saveTokens(
        accessToken: tokens['access']!,
        refreshToken: tokens['refresh']!,
      );
      return await remoteDataSource.getMe();
    } catch (error) {
      throw mapDioError(error);
    }
  }

  @override
  Future<UserEntity> register({required String email, required String password, String? name}) async {
    try {
      return await remoteDataSource.register(email: email, password: password, name: name);
    } catch (error) {
      throw mapDioError(error);
    }
  }

  @override
  Future<UserEntity> getMe() async {
    try {
      return await remoteDataSource.getMe();
    } catch (error) {
      throw mapDioError(error);
    }
  }

  @override
  Future<void> logout() async {
    await tokenStorage.clear();
  }

  @override
  Future<bool> hasTokens() async {
    final access = await tokenStorage.getAccessToken();
    final refresh = await tokenStorage.getRefreshToken();
    return access != null && refresh != null;
  }
}
