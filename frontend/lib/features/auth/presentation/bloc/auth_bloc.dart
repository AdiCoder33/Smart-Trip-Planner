import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/domain/entities/user.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../../auth/domain/usecases/get_me.dart';
import '../../../auth/domain/usecases/login_user.dart';
import '../../../auth/domain/usecases/register_user.dart';
import '../../../../core/errors/app_exception.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUser loginUser;
  final RegisterUser registerUser;
  final GetMe getMe;
  final AuthRepository authRepository;

  AuthBloc({
    required this.loginUser,
    required this.registerUser,
    required this.getMe,
    required this.authRepository,
  }) : super(const AuthState()) {
    on<AuthStarted>(_onStarted);
    on<LoginSubmitted>(_onLogin);
    on<RegisterSubmitted>(_onRegister);
    on<LogoutRequested>(_onLogout);
  }

  Future<void> _onStarted(AuthStarted event, Emitter<AuthState> emit) async {
    final hasTokens = await authRepository.hasTokens();
    if (!hasTokens) {
      emit(state.copyWith(status: AuthStatus.unauthenticated));
      return;
    }

    emit(state.copyWith(status: AuthStatus.loading));
    try {
      final user = await getMe();
      emit(state.copyWith(status: AuthStatus.authenticated, user: user));
    } catch (_) {
      emit(state.copyWith(status: AuthStatus.unauthenticated));
    }
  }

  Future<void> _onLogin(LoginSubmitted event, Emitter<AuthState> emit) async {
    emit(state.copyWith(status: AuthStatus.loading, message: null));
    try {
      final user = await loginUser(email: event.email, password: event.password);
      emit(state.copyWith(status: AuthStatus.authenticated, user: user));
    } catch (error) {
      final message = error is AppException ? error.message : 'Login failed';
      emit(state.copyWith(status: AuthStatus.error, message: message));
      emit(state.copyWith(status: AuthStatus.unauthenticated));
    }
  }

  Future<void> _onRegister(RegisterSubmitted event, Emitter<AuthState> emit) async {
    emit(state.copyWith(status: AuthStatus.loading, message: null));
    try {
      await registerUser(email: event.email, password: event.password, name: event.name);
      emit(state.copyWith(
        status: AuthStatus.registered,
        message: 'Account created. Please log in.',
      ));
      emit(state.copyWith(status: AuthStatus.unauthenticated));
    } catch (error) {
      final message = error is AppException ? error.message : 'Registration failed';
      emit(state.copyWith(status: AuthStatus.error, message: message));
      emit(state.copyWith(status: AuthStatus.unauthenticated));
    }
  }

  Future<void> _onLogout(LogoutRequested event, Emitter<AuthState> emit) async {
    await authRepository.logout();
    emit(state.copyWith(status: AuthStatus.unauthenticated, user: null));
  }
}
