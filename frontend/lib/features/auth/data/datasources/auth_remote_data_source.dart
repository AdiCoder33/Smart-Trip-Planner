import 'package:dio/dio.dart';

import '../models/user_model.dart';

class AuthRemoteDataSource {
  final Dio dio;

  const AuthRemoteDataSource(this.dio);

  Future<Map<String, String>> login({required String email, required String password}) async {
    final response = await dio.post('/api/auth/login', data: {
      'email': email,
      'password': password,
    });

    return {
      'access': response.data['access'] as String,
      'refresh': response.data['refresh'] as String,
    };
  }

  Future<Map<String, String>> refresh({required String refreshToken}) async {
    final response = await dio.post('/api/auth/refresh', data: {
      'refresh': refreshToken,
    });

    return {
      'access': response.data['access'] as String,
    };
  }

  Future<UserModel> register({required String email, required String password, String? name}) async {
    final response = await dio.post('/api/auth/register', data: {
      'email': email,
      'password': password,
      'name': name,
    });

    return UserModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<UserModel> getMe() async {
    final response = await dio.get('/api/auth/me');
    return UserModel.fromJson(response.data as Map<String, dynamic>);
  }
}
