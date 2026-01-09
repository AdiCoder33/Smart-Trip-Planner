import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/config.dart';
import 'core/connectivity/connectivity_cubit.dart';
import 'core/connectivity/connectivity_service.dart';
import 'core/network/dio_client.dart';
import 'core/storage/token_storage.dart';
import 'features/auth/data/datasources/auth_remote_data_source.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/usecases/get_me.dart';
import 'features/auth/domain/usecases/login_user.dart';
import 'features/auth/domain/usecases/register_user.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/trips/data/datasources/trips_local_data_source.dart';
import 'features/trips/data/datasources/trips_remote_data_source.dart';
import 'features/trips/data/models/trip_model.dart';
import 'features/trips/data/repositories/trips_repository_impl.dart';
import 'features/trips/domain/usecases/create_trip.dart';
import 'features/trips/domain/usecases/get_cached_trips.dart';
import 'features/trips/domain/usecases/get_trips.dart';
import 'features/trips/presentation/bloc/trips_bloc.dart';
import 'features/trips/presentation/screens/trips_list_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(TripModelAdapter());
  await Hive.openBox<TripModel>('trips');

  const secureStorage = FlutterSecureStorage();
  final tokenStorage = TokenStorage(secureStorage);
  final dioClient = DioClient(baseUrl: ApiConfig.baseUrl, tokenStorage: tokenStorage);

  final authRemote = AuthRemoteDataSource(dioClient.dio);
  final authRepository = AuthRepositoryImpl(
    remoteDataSource: authRemote,
    tokenStorage: tokenStorage,
  );

  final tripsLocal = TripsLocalDataSource(Hive.box<TripModel>('trips'));
  final tripsRemote = TripsRemoteDataSource(dioClient.dio);
  final tripsRepository = TripsRepositoryImpl(
    remoteDataSource: tripsRemote,
    localDataSource: tripsLocal,
  );

  runApp(SmartTripPlannerApp(
    authRepository: authRepository,
    tripsRepository: tripsRepository,
  ));
}

class SmartTripPlannerApp extends StatelessWidget {
  final AuthRepositoryImpl authRepository;
  final TripsRepositoryImpl tripsRepository;

  const SmartTripPlannerApp({
    super.key,
    required this.authRepository,
    required this.tripsRepository,
  });

  @override
  Widget build(BuildContext context) {
    final connectivityService = ConnectivityService();

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => AuthBloc(
            loginUser: LoginUser(authRepository),
            registerUser: RegisterUser(authRepository),
            getMe: GetMe(authRepository),
            authRepository: authRepository,
          )..add(const AuthStarted()),
        ),
        BlocProvider(
          create: (_) => TripsBloc(
            getTrips: GetTrips(tripsRepository),
            getCachedTrips: GetCachedTrips(tripsRepository),
            createTrip: CreateTrip(tripsRepository),
            connectivityService: connectivityService,
          ),
        ),
        BlocProvider(
          create: (_) => ConnectivityCubit(connectivityService),
        ),
      ],
      child: MaterialApp(
        title: 'Smart Trip Planner',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
          useMaterial3: true,
        ),
        home: const AuthGate(),
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state.status == AuthStatus.authenticated) {
          return const TripsListScreen();
        }
        return const LoginScreen();
      },
    );
  }
}
