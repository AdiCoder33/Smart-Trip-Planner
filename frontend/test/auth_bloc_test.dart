import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:smart_trip_planner/features/auth/domain/entities/user.dart';
import 'package:smart_trip_planner/features/auth/domain/repositories/auth_repository.dart';
import 'package:smart_trip_planner/features/auth/domain/usecases/get_me.dart';
import 'package:smart_trip_planner/features/auth/domain/usecases/login_user.dart';
import 'package:smart_trip_planner/features/auth/domain/usecases/register_user.dart';
import 'package:smart_trip_planner/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:smart_trip_planner/core/errors/app_exception.dart';

class MockLoginUser extends Mock implements LoginUser {}

class MockRegisterUser extends Mock implements RegisterUser {}

class MockGetMe extends Mock implements GetMe {}

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockLoginUser loginUser;
  late MockRegisterUser registerUser;
  late MockGetMe getMe;
  late MockAuthRepository authRepository;
  late AuthBloc authBloc;

  setUp(() {
    loginUser = MockLoginUser();
    registerUser = MockRegisterUser();
    getMe = MockGetMe();
    authRepository = MockAuthRepository();
    authBloc = AuthBloc(
      loginUser: loginUser,
      registerUser: registerUser,
      getMe: getMe,
      authRepository: authRepository,
    );
  });

  tearDown(() {
    authBloc.close();
  });

  const user = UserEntity(id: '1', email: 'user@example.com');

  blocTest<AuthBloc, AuthState>(
    'emits authenticated when login succeeds',
    build: () {
      when(() => loginUser(email: any(named: 'email'), password: any(named: 'password')))
          .thenAnswer((_) async => user);
      return authBloc;
    },
    act: (bloc) => bloc.add(const LoginSubmitted(email: 'user@example.com', password: 'password123')),
    expect: () => [
      const AuthState(status: AuthStatus.loading),
      const AuthState(status: AuthStatus.authenticated, user: user),
    ],
  );

  blocTest<AuthBloc, AuthState>(
    'emits error when login fails',
    build: () {
      when(() => loginUser(email: any(named: 'email'), password: any(named: 'password')))
          .thenThrow(AppException('Invalid credentials'));
      return authBloc;
    },
    act: (bloc) => bloc.add(const LoginSubmitted(email: 'user@example.com', password: 'bad')),
    expect: () => [
      const AuthState(status: AuthStatus.loading),
      const AuthState(status: AuthStatus.error, message: 'Invalid credentials'),
      const AuthState(status: AuthStatus.unauthenticated),
    ],
  );
}
