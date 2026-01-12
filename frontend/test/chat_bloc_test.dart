import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:smart_trip_planner/core/connectivity/connectivity_service.dart';
import 'package:smart_trip_planner/core/notifications/local_notifications_service.dart';
import 'package:smart_trip_planner/core/sync/pending_action.dart';
import 'package:smart_trip_planner/core/sync/sync_queue.dart';
import 'package:smart_trip_planner/features/trips/domain/entities/chat_message.dart';
import 'package:smart_trip_planner/features/trips/domain/entities/chat_socket_event.dart';
import 'package:smart_trip_planner/features/trips/domain/repositories/chat_repository.dart';
import 'package:smart_trip_planner/features/trips/domain/usecases/cache_chat_messages.dart';
import 'package:smart_trip_planner/features/trips/domain/usecases/get_cached_chat_messages.dart';
import 'package:smart_trip_planner/features/trips/domain/usecases/get_chat_messages.dart';
import 'package:smart_trip_planner/features/trips/domain/usecases/send_chat_message.dart';
import 'package:smart_trip_planner/features/trips/domain/usecases/upsert_local_chat_message.dart';
import 'package:smart_trip_planner/features/trips/presentation/bloc/chat_bloc.dart';

class MockGetChatMessages extends Mock implements GetChatMessages {}

class MockGetCachedChatMessages extends Mock implements GetCachedChatMessages {}

class MockSendChatMessage extends Mock implements SendChatMessage {}

class MockCacheChatMessages extends Mock implements CacheChatMessages {}

class MockUpsertLocalChatMessage extends Mock implements UpsertLocalChatMessage {}

class MockChatRepository extends Mock implements ChatRepository {}

class MockConnectivityService extends Mock implements ConnectivityService {}

class MockSyncQueue extends Mock implements SyncQueue {}

class MockLocalNotificationsService extends Mock implements LocalNotificationsService {}

void main() {
  setUpAll(() {
    registerFallbackValue(ChatMessageEntity(
      id: 'fallback',
      tripId: 'trip',
      senderId: 'user',
      content: 'Fallback',
      createdAt: DateTime(2024, 1, 1),
    ));
    registerFallbackValue(const ChatSocketEvent.message(null));
    registerFallbackValue(
      PendingAction(
        id: 'action',
        type: PendingActionType.sendChatMessage,
        payload: const {},
        createdAt: DateTime(2024, 1, 1),
      ),
    );
  });

  late MockGetChatMessages getChatMessages;
  late MockGetCachedChatMessages getCachedChatMessages;
  late MockSendChatMessage sendChatMessage;
  late MockCacheChatMessages cacheChatMessages;
  late MockUpsertLocalChatMessage upsertLocalChatMessage;
  late MockChatRepository chatRepository;
  late MockConnectivityService connectivityService;
  late MockSyncQueue syncQueue;
  late MockLocalNotificationsService notificationsService;

  ChatBloc buildBloc() {
    return ChatBloc(
      getChatMessages: getChatMessages,
      getCachedChatMessages: getCachedChatMessages,
      sendChatMessage: sendChatMessage,
      cacheChatMessages: cacheChatMessages,
      upsertLocalChatMessage: upsertLocalChatMessage,
      chatRepository: chatRepository,
      connectivityService: connectivityService,
      notificationsService: notificationsService,
      currentUserId: 'user',
      tripTitle: 'Trip',
      syncQueue: syncQueue,
    );
  }

  setUp(() {
    getChatMessages = MockGetChatMessages();
    getCachedChatMessages = MockGetCachedChatMessages();
    sendChatMessage = MockSendChatMessage();
    cacheChatMessages = MockCacheChatMessages();
    upsertLocalChatMessage = MockUpsertLocalChatMessage();
    chatRepository = MockChatRepository();
    connectivityService = MockConnectivityService();
    syncQueue = MockSyncQueue();
    notificationsService = MockLocalNotificationsService();
    when(() => connectivityService.onStatusChange).thenAnswer((_) => const Stream.empty());
    when(() => chatRepository.disconnect()).thenAnswer((_) async {});
    when(() => notificationsService.showChatNotification(
          title: any(named: 'title'),
          body: any(named: 'body'),
        )).thenAnswer((_) async {});
  });

  final cachedMessage = ChatMessageEntity(
    id: 'cached',
    tripId: 'trip',
    senderId: 'user',
    content: 'Cached',
    createdAt: DateTime(2024, 1, 1, 10),
  );

  final remoteMessage = ChatMessageEntity(
    id: 'remote',
    tripId: 'trip',
    senderId: 'user2',
    content: 'Remote',
    createdAt: DateTime(2024, 1, 1, 11),
  );

  blocTest<ChatBloc, ChatState>(
    'loads cached then remote history',
    build: () {
      when(() => connectivityService.isOnline()).thenAnswer((_) async => true);
      when(() => getCachedChatMessages('trip')).thenAnswer((_) async => [cachedMessage]);
      when(() => getChatMessages(tripId: 'trip', limit: any(named: 'limit'), before: any(named: 'before')))
          .thenAnswer((_) async => [remoteMessage]);
      when(() => chatRepository.connect(tripId: 'trip'))
          .thenAnswer((_) async => Stream<ChatSocketEvent>.empty());
      when(() => cacheChatMessages.call(any(), any())).thenAnswer((_) async {});
      when(() => syncQueue.getAll()).thenAnswer((_) async => []);
      return buildBloc();
    },
    act: (bloc) => bloc.add(const ChatStarted(tripId: 'trip')),
    expect: () => [
      isA<ChatState>(),
      isA<ChatState>().having((state) => state.messages, 'cached', [cachedMessage]),
      isA<ChatState>().having(
        (state) => state.connectionStatus,
        'connecting',
        ChatConnectionStatus.connecting,
      ),
      isA<ChatState>().having(
        (state) => state.connectionStatus,
        'connected',
        ChatConnectionStatus.connected,
      ),
      isA<ChatState>().having(
        (state) => state.connectionStatus,
        'disconnected',
        ChatConnectionStatus.disconnected,
      ),
      isA<ChatState>().having((state) => state.messages.length, 'merged', 2),
    ],
  );

  blocTest<ChatBloc, ChatState>(
    'optimistic send while online updates on received message',
    build: () {
      when(() => connectivityService.isOnline()).thenAnswer((_) async => true);
      when(() => upsertLocalChatMessage.call(any())).thenAnswer((_) async {});
      when(() => cacheChatMessages.call(any(), any())).thenAnswer((_) async {});
      when(() => chatRepository.sendMessageSocket(content: any(named: 'content'), clientId: any(named: 'clientId')))
          .thenAnswer((_) async {});
      return buildBloc();
    },
    seed: () => const ChatState(
      status: ChatStatus.loaded,
      connectionStatus: ChatConnectionStatus.connected,
      tripId: 'trip',
    ),
    act: (bloc) async {
      bloc.add(const ChatSendRequested(content: 'Hi', senderId: 'user'));
      await Future<void>.delayed(Duration.zero);
      final clientId = bloc.state.messages.first.clientId!;
      bloc.add(
        ChatMessageReceived(
          message: ChatMessageEntity(
            id: 'server',
            tripId: 'trip',
            senderId: 'user',
            content: 'Hi',
            createdAt: DateTime(2024, 1, 1, 12),
            clientId: clientId,
          ),
        ),
      );
    },
    expect: () => [
      isA<ChatState>().having(
        (state) => state.messages.first.isPending,
        'pending',
        true,
      ),
      isA<ChatState>().having(
        (state) => state.messages.first.isPending,
        'pending',
        false,
      ),
    ],
  );

  blocTest<ChatBloc, ChatState>(
    'send while offline queues message',
    build: () {
      when(() => connectivityService.isOnline()).thenAnswer((_) async => false);
      when(() => upsertLocalChatMessage.call(any())).thenAnswer((_) async {});
      when(() => syncQueue.enqueue(any())).thenAnswer((_) async {});
      return buildBloc();
    },
    seed: () => const ChatState(tripId: 'trip'),
    act: (bloc) => bloc.add(const ChatSendRequested(content: 'Offline', senderId: 'user')),
    expect: () => [
      isA<ChatState>().having(
        (state) => state.messages.first.isPending,
        'pending',
        true,
      ),
    ],
  );
}
