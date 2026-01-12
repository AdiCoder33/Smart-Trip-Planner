import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/connectivity/connectivity_service.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/notifications/local_notifications_service.dart';
import '../../../../core/sync/pending_action.dart';
import '../../../../core/sync/sync_queue.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/chat_socket_event.dart';
import '../../domain/repositories/chat_repository.dart';
import '../../domain/usecases/cache_chat_messages.dart';
import '../../domain/usecases/get_cached_chat_messages.dart';
import '../../domain/usecases/get_chat_messages.dart';
import '../../domain/usecases/send_chat_message.dart';
import '../../domain/usecases/upsert_local_chat_message.dart';

part 'chat_event.dart';
part 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final GetChatMessages getChatMessages;
  final GetCachedChatMessages getCachedChatMessages;
  final SendChatMessage sendChatMessage;
  final CacheChatMessages cacheChatMessages;
  final UpsertLocalChatMessage upsertLocalChatMessage;
  final ChatRepository chatRepository;
  final ConnectivityService connectivityService;
  final LocalNotificationsService notificationsService;
  final String? currentUserId;
  final String? tripTitle;
  final SyncQueue syncQueue;
  final Uuid _uuid;
  StreamSubscription<ChatSocketEvent>? _socketSubscription;
  StreamSubscription<bool>? _connectivitySubscription;

  ChatBloc({
    required this.getChatMessages,
    required this.getCachedChatMessages,
    required this.sendChatMessage,
    required this.cacheChatMessages,
    required this.upsertLocalChatMessage,
    required this.chatRepository,
    required this.connectivityService,
    required this.notificationsService,
    this.currentUserId,
    this.tripTitle,
    required this.syncQueue,
    Uuid? uuid,
  })  : _uuid = uuid ?? const Uuid(),
        super(const ChatState()) {
    on<ChatStarted>(_onStarted);
    on<ChatSendRequested>(_onSendRequested);
    on<ChatMessageReceived>(_onMessageReceived);
    on<ChatConnectionChanged>(_onConnectionChanged);
    on<ChatSyncRequested>(_onSyncRequested);

    _connectivitySubscription = connectivityService.onStatusChange.listen((online) {
      if (online && state.tripId != null) {
        add(ChatSyncRequested(tripId: state.tripId!));
      } else if (!online) {
        add(const ChatConnectionChanged(status: ChatConnectionStatus.offline));
      }
    });
  }

  @override
  Future<void> close() async {
    await _socketSubscription?.cancel();
    await _connectivitySubscription?.cancel();
    await chatRepository.disconnect();
    return super.close();
  }

  Future<void> _onStarted(ChatStarted event, Emitter<ChatState> emit) async {
    emit(state.copyWith(status: ChatStatus.loading, tripId: event.tripId, message: null));
    final cached = await getCachedChatMessages(event.tripId);
    emit(state.copyWith(status: ChatStatus.loading, messages: cached, tripId: event.tripId));

    final online = await connectivityService.isOnline();
    if (!online) {
      emit(state.copyWith(status: ChatStatus.loaded, connectionStatus: ChatConnectionStatus.offline));
      return;
    }

    await _connectSocket(event.tripId, emit);
    await _processQueue(event.tripId, emit);

    try {
      final remote = await getChatMessages(tripId: event.tripId);
      final merged = _mergeLists(cached, remote);
      emit(state.copyWith(status: ChatStatus.loaded, messages: merged));
      await cacheChatMessages(event.tripId, merged);
    } catch (error) {
      final message = error is AppException ? error.message : 'Failed to load chat';
      emit(state.copyWith(status: ChatStatus.error, message: message));
    }
  }

  Future<void> _onSendRequested(ChatSendRequested event, Emitter<ChatState> emit) async {
    final tripId = state.tripId;
    if (tripId == null) return;

    final clientId = _uuid.v4();
    final tempId = 'temp-$clientId';
    final optimistic = ChatMessageEntity(
      id: tempId,
      tripId: tripId,
      senderId: event.senderId,
      senderName: event.senderName,
      content: event.content,
      createdAt: DateTime.now(),
      clientId: clientId,
      isPending: true,
    );

    final updated = [...state.messages, optimistic]..sort(_compareMessages);
    emit(state.copyWith(messages: updated));
    await upsertLocalChatMessage(optimistic);

    final online = await connectivityService.isOnline();
    if (!online || state.connectionStatus != ChatConnectionStatus.connected) {
      await syncQueue.enqueue(
        PendingAction.create(
          type: PendingActionType.sendChatMessage,
          payload: {
            'trip_id': tripId,
            'client_id': clientId,
            'content': event.content,
          },
        ),
      );
      return;
    }

    try {
      await chatRepository.sendMessageSocket(content: event.content, clientId: clientId);
    } catch (_) {
      await syncQueue.enqueue(
        PendingAction.create(
          type: PendingActionType.sendChatMessage,
          payload: {
            'trip_id': tripId,
            'client_id': clientId,
            'content': event.content,
          },
        ),
      );
    }
  }

  Future<void> _onMessageReceived(ChatMessageReceived event, Emitter<ChatState> emit) async {
    final merged = _mergeIncoming(state.messages, event.message);
    emit(state.copyWith(messages: merged));
    await cacheChatMessages(event.message.tripId, merged);
    if (currentUserId != null && event.message.senderId != currentUserId) {
      final sender = event.message.senderName?.trim();
      final title = tripTitle?.trim().isNotEmpty == true ? tripTitle!.trim() : 'Trip message';
      final content = event.message.content.trim();
      final body = content.isNotEmpty
          ? (sender?.isNotEmpty == true ? '$sender: $content' : content)
          : 'New message received';
      await notificationsService.showChatNotification(title: title, body: body);
    }
  }

  Future<void> _onConnectionChanged(
    ChatConnectionChanged event,
    Emitter<ChatState> emit,
  ) async {
    emit(state.copyWith(connectionStatus: event.status, message: event.message));
  }

  Future<void> _onSyncRequested(ChatSyncRequested event, Emitter<ChatState> emit) async {
    if (state.isSyncing) return;
    emit(state.copyWith(isSyncing: true));
    await _connectSocket(event.tripId, emit);
    await _processQueue(event.tripId, emit);
    emit(state.copyWith(isSyncing: false));
  }

  Future<void> _connectSocket(String tripId, Emitter<ChatState> emit) async {
    if (state.connectionStatus == ChatConnectionStatus.connected) {
      return;
    }
    emit(state.copyWith(connectionStatus: ChatConnectionStatus.connecting));
    await _socketSubscription?.cancel();
    try {
      final stream = await chatRepository.connect(tripId: tripId);
      _socketSubscription = stream.listen(
        (event) {
          if (event.type == ChatSocketEventType.message && event.message != null) {
            add(ChatMessageReceived(message: event.message!));
          } else if (event.type == ChatSocketEventType.error) {
            add(
              ChatConnectionChanged(
                status: ChatConnectionStatus.error,
                message: event.errorMessage ?? 'Chat connection error',
              ),
            );
          }
        },
        onDone: () {
          add(const ChatConnectionChanged(status: ChatConnectionStatus.disconnected));
        },
        onError: (_) {
          add(const ChatConnectionChanged(status: ChatConnectionStatus.error));
        },
      );
      emit(state.copyWith(connectionStatus: ChatConnectionStatus.connected));
    } catch (error) {
      final message = error is AppException ? error.message : 'Failed to connect';
      emit(state.copyWith(connectionStatus: ChatConnectionStatus.error, message: message));
    }
  }

  Future<void> _processQueue(String tripId, Emitter<ChatState> emit) async {
    final actions = await syncQueue.getAll();
    final chatActions = actions.where(
      (action) =>
          action.type == PendingActionType.sendChatMessage &&
          action.payload['trip_id'] == tripId,
    );

    for (final action in chatActions) {
      final content = action.payload['content'] as String?;
      final clientId = action.payload['client_id'] as String?;
      if (content == null || clientId == null) {
        await syncQueue.remove(action.id);
        continue;
      }
      try {
        final message = await sendChatMessage(
          tripId: tripId,
          content: content,
          clientId: clientId,
        );
        await syncQueue.remove(action.id);
        final merged = _mergeIncoming(state.messages, message);
        emit(state.copyWith(messages: merged));
        await cacheChatMessages(tripId, merged);
      } catch (error) {
        final message = error is AppException ? error.message : 'Failed to sync chat';
        emit(state.copyWith(message: message));
        break;
      }
    }
  }

  List<ChatMessageEntity> _mergeIncoming(
    List<ChatMessageEntity> current,
    ChatMessageEntity incoming,
  ) {
    final byId = current.indexWhere((item) => item.id == incoming.id);
    if (byId != -1) {
      return current;
    }

    if (incoming.clientId != null) {
      final byClient = current.indexWhere(
        (item) => item.clientId != null && item.clientId == incoming.clientId,
      );
      if (byClient != -1) {
        final updated = List<ChatMessageEntity>.from(current);
        updated[byClient] = incoming.copyWith(isPending: false);
        updated.sort(_compareMessages);
        return updated;
      }
    }

    final updated = List<ChatMessageEntity>.from(current)..add(incoming);
    updated.sort(_compareMessages);
    return updated;
  }

  List<ChatMessageEntity> _mergeLists(
    List<ChatMessageEntity> cached,
    List<ChatMessageEntity> remote,
  ) {
    final merged = <ChatMessageEntity>[];
    final byClient = <String, int>{};
    final byId = <String, int>{};

    for (final message in cached) {
      final index = merged.length;
      merged.add(message);
      if (message.clientId != null) {
        byClient[message.clientId!] = index;
      }
      byId[message.id] = index;
    }

    for (final message in remote) {
      if (message.clientId != null && byClient.containsKey(message.clientId)) {
        merged[byClient[message.clientId!]!] = message;
        continue;
      }
      if (byId.containsKey(message.id)) {
        merged[byId[message.id]!] = message;
        continue;
      }
      final index = merged.length;
      merged.add(message);
      if (message.clientId != null) {
        byClient[message.clientId!] = index;
      }
      byId[message.id] = index;
    }

    merged.sort(_compareMessages);
    return merged;
  }

  int _compareMessages(ChatMessageEntity a, ChatMessageEntity b) {
    return a.createdAt.compareTo(b.createdAt);
  }
}
