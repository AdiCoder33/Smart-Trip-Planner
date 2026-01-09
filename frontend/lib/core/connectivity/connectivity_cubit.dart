import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'connectivity_service.dart';

class ConnectivityState extends Equatable {
  final bool isOnline;

  const ConnectivityState({required this.isOnline});

  factory ConnectivityState.initial() => const ConnectivityState(isOnline: true);

  @override
  List<Object?> get props => [isOnline];
}

class ConnectivityCubit extends Cubit<ConnectivityState> {
  final ConnectivityService service;
  StreamSubscription<bool>? _subscription;

  ConnectivityCubit(this.service) : super(ConnectivityState.initial()) {
    _subscription = service.onStatusChange.listen((status) {
      emit(ConnectivityState(isOnline: status));
    });
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
