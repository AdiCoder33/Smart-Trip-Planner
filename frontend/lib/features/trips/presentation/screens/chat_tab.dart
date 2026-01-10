import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/connectivity/connectivity_cubit.dart';
import '../../../../core/widgets/offline_banner.dart';
import '../../../../core/widgets/skeleton_loader.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/trip.dart';
import '../bloc/chat_bloc.dart';

class ChatTab extends StatefulWidget {
  final TripEntity trip;

  const ChatTab({super.key, required this.trip});

  @override
  State<ChatTab> createState() => _ChatTabState();
}

class _ChatTabState extends State<ChatTab> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthBloc>().state.user;

    return MultiBlocListener(
      listeners: [
        BlocListener<ChatBloc, ChatState>(
          listenWhen: (prev, next) => prev.message != next.message && next.message != null,
          listener: (context, state) {
            if (state.message != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message!)),
              );
            }
          },
        ),
        BlocListener<ChatBloc, ChatState>(
          listenWhen: (prev, next) => prev.messages.length != next.messages.length,
          listener: (context, state) => _scrollToBottom(),
        ),
      ],
      child: Column(
        children: [
          BlocBuilder<ConnectivityCubit, ConnectivityState>(
            builder: (context, connectivityState) {
              return OfflineBanner(
                isOnline: connectivityState.isOnline,
                message: 'Offline mode: messages will sync later',
              );
            },
          ),
          BlocBuilder<ChatBloc, ChatState>(
            builder: (context, state) {
              return _ConnectionStatusChip(status: state.connectionStatus);
            },
          ),
          Expanded(
            child: BlocBuilder<ChatBloc, ChatState>(
              builder: (context, state) {
                if (state.status == ChatStatus.loading && state.messages.isEmpty) {
                  return const SkeletonLoader();
                }

                if (state.messages.isEmpty) {
                  return Center(
                    child: Text(
                      'No messages yet.',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: state.messages.length,
                  itemBuilder: (context, index) {
                    final message = state.messages[index];
                    final isMine = user != null && message.senderId == user.id;
                    return _MessageBubble(message: message, isMine: isMine);
                  },
                );
              },
            ),
          ),
          _MessageInput(
            controller: _messageController,
            onSend: () => _sendMessage(context, user?.id, user?.name),
          ),
        ],
      ),
    );
  }

  void _sendMessage(BuildContext context, String? senderId, String? senderName) {
    final content = _messageController.text.trim();
    if (content.isEmpty || senderId == null) {
      return;
    }
    context.read<ChatBloc>().add(
          ChatSendRequested(
            content: content,
            senderId: senderId,
            senderName: senderName,
          ),
        );
    _messageController.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }
}

class _ConnectionStatusChip extends StatelessWidget {
  final ChatConnectionStatus status;

  const _ConnectionStatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    switch (status) {
      case ChatConnectionStatus.connected:
        color = Colors.green;
        label = 'Connected';
        break;
      case ChatConnectionStatus.connecting:
        color = Colors.orange;
        label = 'Connecting';
        break;
      case ChatConnectionStatus.offline:
        color = Colors.grey;
        label = 'Offline';
        break;
      case ChatConnectionStatus.error:
        color = Colors.red;
        label = 'Error';
        break;
      case ChatConnectionStatus.disconnected:
        color = Colors.grey;
        label = 'Disconnected';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: color.withValues(alpha: 0.1),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessageEntity message;
  final bool isMine;

  const _MessageBubble({required this.message, required this.isMine});

  @override
  Widget build(BuildContext context) {
    final alignment = isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final bubbleColor = isMine ? Colors.teal.shade100 : Colors.grey.shade200;
    final time = TimeOfDay.fromDateTime(message.createdAt).format(context);

    return Column(
      crossAxisAlignment: alignment,
      children: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: alignment,
            children: [
              if (!isMine)
                Text(
                  message.senderName?.isNotEmpty == true ? message.senderName! : 'Guest',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              Text(message.content),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    time,
                    style: const TextStyle(fontSize: 10, color: Colors.black54),
                  ),
                  if (message.isPending)
                    const Padding(
                      padding: EdgeInsets.only(left: 8),
                      child: Text(
                        'Pending',
                        style: TextStyle(fontSize: 10, color: Colors.orange),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MessageInput extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;

  const _MessageInput({required this.controller, required this.onSend});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, -2)),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                decoration: const InputDecoration(
                  hintText: 'Type a message',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                minLines: 1,
                maxLines: 4,
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: onSend,
              icon: const Icon(Icons.send),
            ),
          ],
        ),
      ),
    );
  }
}
