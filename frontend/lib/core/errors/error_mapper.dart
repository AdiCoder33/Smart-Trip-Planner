import 'package:dio/dio.dart';

import 'app_exception.dart';

AppException mapDioError(Object error) {
  if (error is DioException) {
    final responseData = error.response?.data;
    if (responseData is Map && responseData['error'] is Map) {
      final errorMap = responseData['error'] as Map;
      final message = errorMap['message']?.toString() ?? 'Request failed';
      final code = errorMap['code']?.toString() ?? 'ERROR';
      return AppException(message, code: code);
    }

    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.connectionError) {
      return AppException('Network error. Please check your connection.', code: 'NETWORK');
    }

    if (error.response?.statusCode == 401) {
      return AppException('Session expired. Please log in again.', code: 'UNAUTHORIZED');
    }

    return AppException('Request failed. Please try again.', code: 'REQUEST_FAILED');
  }

  return AppException('Unexpected error. Please try again.', code: 'UNKNOWN');
}
