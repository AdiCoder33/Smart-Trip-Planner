class AppException implements Exception {
  final String message;
  final String code;

  AppException(this.message, {this.code = 'ERROR'});

  @override
  String toString() => '$code: $message';
}
