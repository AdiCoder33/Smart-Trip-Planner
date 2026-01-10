import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/connectivity/connectivity_service.dart';
import '../../../../core/sync/sync_queue.dart';
import '../../../../core/sync/sync_service.dart';
import '../../data/repositories/collaborators_repository_impl.dart';
import '../../data/repositories/chat_repository_impl.dart';
import '../../data/repositories/expenses_repository_impl.dart';
import '../../data/repositories/itinerary_repository_impl.dart';
import '../../data/repositories/polls_repository_impl.dart';
import '../../domain/entities/trip.dart';
import '../../domain/usecases/cache_expenses.dart';
import '../../domain/usecases/cache_chat_messages.dart';
import '../../domain/usecases/cache_itinerary_items.dart';
import '../../domain/usecases/cache_polls.dart';
import '../../domain/usecases/create_expense.dart';
import '../../domain/usecases/get_cached_chat_messages.dart';
import '../../domain/usecases/get_cached_expenses.dart';
import '../../domain/usecases/create_itinerary_item.dart';
import '../../domain/usecases/create_poll.dart';
import '../../domain/usecases/get_chat_messages.dart';
import '../../domain/usecases/get_expense_summary.dart';
import '../../domain/usecases/delete_itinerary_item.dart';
import '../../domain/usecases/delete_local_itinerary_item.dart';
import '../../domain/usecases/delete_local_poll.dart';
import '../../domain/usecases/get_expenses.dart';
import '../../domain/usecases/send_chat_message.dart';
import '../../domain/usecases/get_cached_itinerary_items.dart';
import '../../domain/usecases/get_cached_polls.dart';
import '../../domain/usecases/get_itinerary_items.dart';
import '../../domain/usecases/get_polls.dart';
import '../../domain/usecases/get_trip_invites.dart';
import '../../domain/usecases/get_trip_members.dart';
import '../../domain/usecases/reorder_itinerary_items.dart';
import '../../domain/usecases/revoke_invite.dart';
import '../../domain/usecases/send_trip_invite.dart';
import '../../domain/usecases/update_itinerary_item.dart';
import '../../domain/usecases/upsert_local_chat_message.dart';
import '../../domain/usecases/upsert_local_itinerary_item.dart';
import '../../domain/usecases/upsert_local_poll.dart';
import '../../domain/usecases/vote_poll.dart';
import '../bloc/chat_bloc.dart';
import '../bloc/collaborators_bloc.dart';
import '../bloc/expenses_bloc.dart';
import '../bloc/itinerary_bloc.dart';
import '../bloc/polls_bloc.dart';
import 'chat_tab.dart';
import 'collaborators_tab.dart';
import 'expenses_tab.dart';
import 'itinerary_tab.dart';
import 'polls_tab.dart';

class TripDetailScreen extends StatelessWidget {
  final TripEntity trip;

  const TripDetailScreen({super.key, required this.trip});

  @override
  Widget build(BuildContext context) {
    final itineraryRepository = context.read<ItineraryRepositoryImpl>();
    final pollsRepository = context.read<PollsRepositoryImpl>();
    final collaboratorsRepository = context.read<CollaboratorsRepositoryImpl>();
    final chatRepository = context.read<ChatRepositoryImpl>();
    final expensesRepository = context.read<ExpensesRepositoryImpl>();
    final connectivityService = context.read<ConnectivityService>();
    final syncQueue = context.read<SyncQueue>();
    final syncService = context.read<SyncService>();

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => ItineraryBloc(
            getItineraryItems: GetItineraryItems(itineraryRepository),
            getCachedItineraryItems: GetCachedItineraryItems(itineraryRepository),
            createItineraryItem: CreateItineraryItem(itineraryRepository),
            updateItineraryItem: UpdateItineraryItem(itineraryRepository),
            deleteItineraryItem: DeleteItineraryItem(itineraryRepository),
            reorderItineraryItems: ReorderItineraryItems(itineraryRepository),
            cacheItineraryItems: CacheItineraryItems(itineraryRepository),
            upsertLocalItineraryItem: UpsertLocalItineraryItem(itineraryRepository),
            deleteLocalItineraryItem: DeleteLocalItineraryItem(itineraryRepository),
            connectivityService: connectivityService,
            syncQueue: syncQueue,
            syncService: syncService,
          )..add(ItineraryStarted(tripId: trip.id)),
        ),
        BlocProvider(
          create: (_) => PollsBloc(
            getPolls: GetPolls(pollsRepository),
            getCachedPolls: GetCachedPolls(pollsRepository),
            createPoll: CreatePoll(pollsRepository),
            votePoll: VotePoll(pollsRepository),
            cachePolls: CachePolls(pollsRepository),
            upsertLocalPoll: UpsertLocalPoll(pollsRepository),
            deleteLocalPoll: DeleteLocalPoll(pollsRepository),
            connectivityService: connectivityService,
            syncQueue: syncQueue,
            syncService: syncService,
          )..add(PollsStarted(tripId: trip.id)),
        ),
        BlocProvider(
          create: (_) => CollaboratorsBloc(
            getTripMembers: GetTripMembers(collaboratorsRepository),
            getTripInvites: GetTripInvites(collaboratorsRepository),
            sendTripInvite: SendTripInvite(collaboratorsRepository),
            revokeInvite: RevokeInvite(collaboratorsRepository),
            connectivityService: connectivityService,
          )..add(CollaboratorsStarted(tripId: trip.id)),
        ),
        BlocProvider(
          create: (_) => ChatBloc(
            getChatMessages: GetChatMessages(chatRepository),
            getCachedChatMessages: GetCachedChatMessages(chatRepository),
            sendChatMessage: SendChatMessage(chatRepository),
            cacheChatMessages: CacheChatMessages(chatRepository),
            upsertLocalChatMessage: UpsertLocalChatMessage(chatRepository),
            chatRepository: chatRepository,
            connectivityService: connectivityService,
            syncQueue: syncQueue,
          )..add(ChatStarted(tripId: trip.id)),
        ),
        BlocProvider(
          create: (_) => ExpensesBloc(
            getExpenses: GetExpenses(expensesRepository),
            getCachedExpenses: GetCachedExpenses(expensesRepository),
            createExpense: CreateExpense(expensesRepository),
            getExpenseSummary: GetExpenseSummary(expensesRepository),
            cacheExpenses: CacheExpenses(expensesRepository),
            connectivityService: connectivityService,
          )..add(ExpensesStarted(tripId: trip.id)),
        ),
      ],
      child: DefaultTabController(
        length: 5,
        child: Scaffold(
          appBar: AppBar(
            title: Text(trip.title),
            bottom: const TabBar(
              tabs: [
                Tab(icon: Icon(Icons.route_outlined), text: 'Itinerary'),
                Tab(icon: Icon(Icons.payments_outlined), text: 'Expenses'),
                Tab(icon: Icon(Icons.how_to_vote_outlined), text: 'Polls'),
                Tab(icon: Icon(Icons.group_outlined), text: 'Collaborators'),
                Tab(icon: Icon(Icons.forum_outlined), text: 'Chat'),
              ],
            ),
          ),
          body: TabBarView(
            children: [
              ItineraryTab(trip: trip),
              ExpensesTab(trip: trip),
              PollsTab(trip: trip),
              CollaboratorsTab(trip: trip),
              ChatTab(trip: trip),
            ],
          ),
        ),
      ),
    );
  }
}
