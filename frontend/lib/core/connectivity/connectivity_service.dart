import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  final Connectivity connectivity;

  ConnectivityService({Connectivity? connectivity})
      : connectivity = connectivity ?? Connectivity();

  Stream<bool> get onStatusChange =>
      (connectivity.onConnectivityChanged as Stream<dynamic>).map(_isOnlineDynamic);

  Future<bool> isOnline() async {
    final result = await connectivity.checkConnectivity();
    return _isOnlineDynamic(result);
  }

  bool _isOnlineDynamic(dynamic result) {
    if (result is List<ConnectivityResult>) {
      return result.any((item) => item != ConnectivityResult.none);
    }
    if (result is ConnectivityResult) {
      return result != ConnectivityResult.none;
    }
    return false;
  }
}
