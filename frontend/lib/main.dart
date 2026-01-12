import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/config.dart';
import 'core/connectivity/connectivity_cubit.dart';
import 'core/connectivity/connectivity_service.dart';
import 'core/crypto/chat_crypto.dart';
import 'core/network/dio_client.dart';
import 'core/notifications/local_notifications_service.dart';
import 'core/storage/chat_key_storage.dart';
import 'core/storage/token_storage.dart';
import 'core/sync/pending_action.dart';
import 'core/sync/sync_queue.dart';
import 'core/sync/sync_service.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/data/datasources/auth_remote_data_source.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/usecases/get_me.dart';
import 'features/auth/domain/usecases/login_user.dart';
import 'features/auth/domain/usecases/register_user.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/trips/data/datasources/chat_local_data_source.dart';
import 'features/trips/data/datasources/chat_remote_data_source.dart';
import 'features/trips/data/datasources/collaborators_remote_data_source.dart';
import 'features/trips/data/datasources/expenses_local_data_source.dart';
import 'features/trips/data/datasources/expenses_remote_data_source.dart';
import 'features/trips/data/datasources/itinerary_local_data_source.dart';
import 'features/trips/data/datasources/itinerary_remote_data_source.dart';
import 'features/trips/data/datasources/polls_local_data_source.dart';
import 'features/trips/data/datasources/polls_remote_data_source.dart';
import 'features/trips/data/datasources/trips_local_data_source.dart';
import 'features/trips/data/datasources/trips_remote_data_source.dart';
import 'features/trips/data/models/chat_message_model.dart';
import 'features/trips/data/models/expense_model.dart';
import 'features/trips/data/models/expense_split_model.dart';
import 'features/trips/data/models/itinerary_item_model.dart';
import 'features/trips/data/models/poll_model.dart';
import 'features/trips/data/models/poll_option_model.dart';
import 'features/trips/data/models/trip_model.dart';
import 'features/trips/data/repositories/chat_repository_impl.dart';
import 'features/trips/data/repositories/collaborators_repository_impl.dart';
import 'features/trips/data/repositories/expenses_repository_impl.dart';
import 'features/trips/data/repositories/itinerary_repository_impl.dart';
import 'features/trips/data/repositories/polls_repository_impl.dart';
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
  Hive.registerAdapter(ItineraryItemModelAdapter());
  Hive.registerAdapter(PollOptionModelAdapter());
  Hive.registerAdapter(PollModelAdapter());
  Hive.registerAdapter(PendingActionAdapter());
  Hive.registerAdapter(ChatMessageModelAdapter());
  Hive.registerAdapter(ExpenseSplitModelAdapter());
  Hive.registerAdapter(ExpenseModelAdapter());
  await Hive.openBox<TripModel>('trips');
  await Hive.openBox<ItineraryItemModel>('itinerary_items');
  await Hive.openBox<PollModel>('polls');
  await Hive.openBox<PendingAction>('sync_queue');
  await Hive.openBox<ChatMessageModel>('chat_messages');
  await Hive.openBox<ExpenseModel>('expenses');

  const secureStorage = FlutterSecureStorage();
  final connectivityService = ConnectivityService();
  final notificationsService = LocalNotificationsService();
  final tokenStorage = TokenStorage(secureStorage);
  final chatKeyStorage = ChatKeyStorage(secureStorage);
  final chatCrypto = ChatCrypto();
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

  final itineraryLocal = ItineraryLocalDataSource(Hive.box<ItineraryItemModel>('itinerary_items'));
  final itineraryRemote = ItineraryRemoteDataSource(dioClient.dio);
  final itineraryRepository = ItineraryRepositoryImpl(
    remoteDataSource: itineraryRemote,
    localDataSource: itineraryLocal,
  );

  final pollsLocal = PollsLocalDataSource(Hive.box<PollModel>('polls'));
  final pollsRemote = PollsRemoteDataSource(dioClient.dio);
  final pollsRepository = PollsRepositoryImpl(
    remoteDataSource: pollsRemote,
    localDataSource: pollsLocal,
  );

  final collaboratorsRemote = CollaboratorsRemoteDataSource(dioClient.dio);
  final collaboratorsRepository = CollaboratorsRepositoryImpl(remoteDataSource: collaboratorsRemote);

  final expensesLocal = ExpensesLocalDataSource(Hive.box<ExpenseModel>('expenses'));
  final expensesRemote = ExpensesRemoteDataSource(dioClient.dio);
  final expensesRepository = ExpensesRepositoryImpl(
    remoteDataSource: expensesRemote,
    localDataSource: expensesLocal,
  );

  final chatLocal = ChatLocalDataSource(Hive.box<ChatMessageModel>('chat_messages'));
  final chatRemote = ChatRemoteDataSource(dioClient.dio, tokenStorage, chatKeyStorage, chatCrypto);
  final chatRepository = ChatRepositoryImpl(
    remoteDataSource: chatRemote,
    localDataSource: chatLocal,
  );

  final syncQueue = SyncQueue(Hive.box<PendingAction>('sync_queue'));
  final syncService = SyncService(
    queue: syncQueue,
    itineraryRemote: itineraryRemote,
    itineraryLocal: itineraryLocal,
    pollsRemote: pollsRemote,
    pollsLocal: pollsLocal,
  );

  await notificationsService.init();

  runApp(SmartTripPlannerApp(
    tokenStorage: tokenStorage,
    authRepository: authRepository,
    tripsRepository: tripsRepository,
    itineraryRepository: itineraryRepository,
    pollsRepository: pollsRepository,
    collaboratorsRepository: collaboratorsRepository,
    expensesRepository: expensesRepository,
    chatRepository: chatRepository,
    connectivityService: connectivityService,
    notificationsService: notificationsService,
    syncQueue: syncQueue,
    syncService: syncService,
  ));
}

class SmartTripPlannerApp extends StatelessWidget {
  final TokenStorage tokenStorage;
  final AuthRepositoryImpl authRepository;
  final TripsRepositoryImpl tripsRepository;
  final ItineraryRepositoryImpl itineraryRepository;
  final PollsRepositoryImpl pollsRepository;
  final CollaboratorsRepositoryImpl collaboratorsRepository;
  final ExpensesRepositoryImpl expensesRepository;
  final ChatRepositoryImpl chatRepository;
  final ConnectivityService connectivityService;
  final LocalNotificationsService notificationsService;
  final SyncQueue syncQueue;
  final SyncService syncService;

  const SmartTripPlannerApp({
    super.key,
    required this.tokenStorage,
    required this.authRepository,
    required this.tripsRepository,
    required this.itineraryRepository,
    required this.pollsRepository,
    required this.collaboratorsRepository,
    required this.expensesRepository,
    required this.chatRepository,
    required this.connectivityService,
    required this.notificationsService,
    required this.syncQueue,
    required this.syncService,
  });

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: authRepository),
        RepositoryProvider.value(value: tokenStorage),
        RepositoryProvider.value(value: tripsRepository),
        RepositoryProvider.value(value: itineraryRepository),
        RepositoryProvider.value(value: pollsRepository),
        RepositoryProvider.value(value: collaboratorsRepository),
        RepositoryProvider.value(value: expensesRepository),
        RepositoryProvider.value(value: chatRepository),
        RepositoryProvider.value(value: connectivityService),
        RepositoryProvider.value(value: notificationsService),
        RepositoryProvider.value(value: syncQueue),
        RepositoryProvider.value(value: syncService),
      ],
      child: MultiBlocProvider(
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
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          home: const AuthGate(),
        ),
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
