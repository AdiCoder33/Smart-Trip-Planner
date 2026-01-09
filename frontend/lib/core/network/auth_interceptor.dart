import 'dart:async';

import 'package:dio/dio.dart';

import '../storage/token_storage.dart';

class AuthInterceptor extends Interceptor {
  final TokenStorage tokenStorage;
  final Dio refreshDio;
  Completer<String?>? _refreshCompleter;

  AuthInterceptor({required this.tokenStorage, required this.refreshDio});

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    if (options.extra['skipAuth'] == true) {
      handler.next(options);
      return;
    }

    final token = await tokenStorage.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final response = err.response;
    final isUnauthorized = response?.statusCode == 401;
    final alreadyRetried = err.requestOptions.extra['retry'] == true;

    if (!isUnauthorized || alreadyRetried) {
      handler.next(err);
      return;
    }

    final accessToken = await _refreshAccessToken();
    if (accessToken == null) {
      await tokenStorage.clear();
      handler.next(err);
      return;
    }

    final requestOptions = err.requestOptions;
    requestOptions.extra['retry'] = true;
    requestOptions.headers['Authorization'] = 'Bearer $accessToken';

    try {
      final response = await refreshDio.fetch(requestOptions);
      handler.resolve(response);
    } catch (error) {
      handler.next(err);
    }
  }

  Future<String?> _refreshAccessToken() async {
    if (_refreshCompleter != null) {
      return _refreshCompleter!.future;
    }

    _refreshCompleter = Completer<String?>();
    final completer = _refreshCompleter!;

    try {
      final refreshToken = await tokenStorage.getRefreshToken();
      if (refreshToken == null) {
        completer.complete(null);
        return completer.future;
      }

      final response = await refreshDio.post(
        '/api/auth/refresh',
        data: {'refresh': refreshToken},
        options: Options(extra: {'skipAuth': true}),
      );

      final accessToken = response.data['access'] as String?;
      if (accessToken != null) {
        await tokenStorage.saveTokens(accessToken: accessToken, refreshToken: refreshToken);
      }
      completer.complete(accessToken);
    } catch (_) {
      completer.complete(null);
    } finally {
      _refreshCompleter = null;
    }

    return completer.future;
  }
}
