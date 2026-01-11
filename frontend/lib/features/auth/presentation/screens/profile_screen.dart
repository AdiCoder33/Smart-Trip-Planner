import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/auth_bloc.dart';
import '../../../trips/domain/entities/trip.dart';
import '../../../trips/domain/entities/trip_invite.dart';
import '../../../trips/domain/usecases/accept_invite_by_id.dart';
import '../../../trips/domain/usecases/decline_invite.dart';
import '../../../trips/domain/usecases/get_received_invites.dart';
import '../../../trips/domain/usecases/get_sent_invites.dart';
import '../../../trips/presentation/bloc/received_invites_cubit.dart';
import '../../../trips/presentation/bloc/sent_invites_cubit.dart';
import '../../../trips/presentation/bloc/trips_bloc.dart';
import '../../../trips/data/repositories/collaborators_repository_impl.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthBloc>().state.user;
    final nameValue = (user?.name ?? '').trim();
    final displayName = nameValue.isNotEmpty ? nameValue : 'Traveler';

    final collaboratorsRepository = context.read<CollaboratorsRepositoryImpl>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (_) => SentInvitesCubit(
              getSentInvites: GetSentInvites(collaboratorsRepository),
            )..load(),
          ),
          BlocProvider(
            create: (_) => ReceivedInvitesCubit(
              getReceivedInvites: GetReceivedInvites(collaboratorsRepository),
              acceptInviteById: AcceptInviteById(collaboratorsRepository),
              declineInvite: DeclineInvite(collaboratorsRepository),
            )..load(),
          ),
        ],
        child: MultiBlocListener(
          listeners: [
            BlocListener<ReceivedInvitesCubit, ReceivedInvitesState>(
              listenWhen: (prev, next) => prev.message != next.message && next.message != null,
              listener: (context, state) {
                if (state.message != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(state.message!)),
                  );
                }
              },
            ),
          ],
          child: BlocBuilder<TripsBloc, TripsState>(
            builder: (context, tripsState) {
              final trips = tripsState.trips;
              final completed = trips.where(_isCompleted).toList()
                ..sort((a, b) => _endDateOrMin(b).compareTo(_endDateOrMin(a)));
              final upcoming = trips.where((trip) => !_isCompleted(trip)).toList();

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _ProfileHeader(
                    name: displayName,
                    email: user?.email ?? 'Unknown',
                  ),
                  const SizedBox(height: 16),
                  _StatsRow(
                    total: trips.length,
                    completed: completed.length,
                    upcoming: upcoming.length,
                  ),
                  const SizedBox(height: 24),
                  Text('Tour History', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  if (completed.isEmpty)
                    Text(
                      'No completed tours yet.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: completed.length,
                      separatorBuilder: (_, __) => const Divider(height: 16),
                      itemBuilder: (context, index) {
                        final trip = completed[index];
                        final subtitle = _buildTripSubtitle(trip);
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(trip.title),
                          subtitle: subtitle == null ? null : Text(subtitle),
                          trailing: const Icon(Icons.check_circle, color: Colors.teal),
                        );
                      },
                    ),
                  const SizedBox(height: 24),
                  Text('Invites', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  DefaultTabController(
                    length: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const TabBar(
                          tabs: [
                            Tab(text: 'Sent'),
                            Tab(text: 'Received'),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 260,
                          child: TabBarView(
                            children: [
                              _InvitesList<SentInvitesCubit, SentInvitesState>(
                                emptyLabel: 'No sent invites yet.',
                                loadingStatus: SentInvitesStatus.loading,
                                errorStatus: SentInvitesStatus.error,
                              ),
                              _InvitesList<ReceivedInvitesCubit, ReceivedInvitesState>(
                                emptyLabel: 'No received invites yet.',
                                loadingStatus: ReceivedInvitesStatus.loading,
                                errorStatus: ReceivedInvitesStatus.error,
                                onAccept: (invite) async {
                                  final accepted = await context
                                      .read<ReceivedInvitesCubit>()
                                      .acceptInvite(invite.id);
                                  if (accepted) {
                                    context.read<TripsBloc>().add(const TripsRefreshed());
                                  }
                                },
                                onDecline: (invite) async {
                                  await context
                                      .read<ReceivedInvitesCubit>()
                                      .declineInviteById(invite.id);
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        context.read<AuthBloc>().add(const LogoutRequested());
                        Navigator.of(context).popUntil((route) => route.isFirst);
                      },
                      icon: const Icon(Icons.logout),
                      label: const Text('Logout'),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  bool _isCompleted(TripEntity trip) {
    final endDate = trip.endDate;
    if (endDate == null) {
      return false;
    }
    final today = DateTime.now();
    final endDay = DateTime(endDate.year, endDate.month, endDate.day);
    final currentDay = DateTime(today.year, today.month, today.day);
    return endDay.isBefore(currentDay);
  }

  DateTime _endDateOrMin(TripEntity trip) {
    return trip.endDate ?? DateTime(1970, 1, 1);
  }

  String? _buildTripSubtitle(TripEntity trip) {
    final parts = <String>[];
    if (trip.destination != null && trip.destination!.trim().isNotEmpty) {
      parts.add(trip.destination!.trim());
    }
    if (trip.endDate != null) {
      parts.add('Ended ${_formatDate(trip.endDate!)}');
    }
    if (parts.isEmpty) {
      return null;
    }
    return parts.join(' - ');
  }

  String _formatDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}

class _ProfileHeader extends StatelessWidget {
  final String name;
  final String email;

  const _ProfileHeader({required this.name, required this.email});

  @override
  Widget build(BuildContext context) {
    final initials = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Row(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: Colors.teal.shade100,
          foregroundColor: Colors.teal.shade900,
          child: Text(initials, style: const TextStyle(fontSize: 20)),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(email, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatsRow extends StatelessWidget {
  final int total;
  final int completed;
  final int upcoming;

  const _StatsRow({
    required this.total,
    required this.completed,
    required this.upcoming,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'Total',
            value: total,
            icon: Icons.card_travel,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            label: 'Completed',
            value: completed,
            icon: Icons.check_circle_outline,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            label: 'Upcoming',
            value: upcoming,
            icon: Icons.event_available_outlined,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;

  const _StatCard({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: theme.colorScheme.primary),
              const SizedBox(width: 6),
              Text(label, style: theme.textTheme.bodySmall),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value.toString(),
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _InvitesList<C extends Cubit<S>, S> extends StatelessWidget {
  final String emptyLabel;
  final Object loadingStatus;
  final Object errorStatus;
  final Future<void> Function(TripInviteEntity invite)? onAccept;
  final Future<void> Function(TripInviteEntity invite)? onDecline;

  const _InvitesList({
    required this.emptyLabel,
    required this.loadingStatus,
    required this.errorStatus,
    this.onAccept,
    this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<C, S>(
      builder: (context, state) {
        final dynamic status = (state as dynamic).status;
        final dynamic message = (state as dynamic).message;
        final List invites = (state as dynamic).invites as List;

        if (status == loadingStatus) {
          return const Center(child: CircularProgressIndicator());
        }
        if (status == errorStatus) {
          return Text(
            message ?? 'Failed to load invites.',
            style: Theme.of(context).textTheme.bodyMedium,
          );
        }
        if (invites.isEmpty) {
          return Text(
            emptyLabel,
            style: Theme.of(context).textTheme.bodyMedium,
          );
        }

        return ListView.separated(
          itemCount: invites.length,
          separatorBuilder: (_, __) => const Divider(height: 16),
          itemBuilder: (context, index) {
            final invite = invites[index] as TripInviteEntity;
            final tripTitle = invite.tripTitle ?? 'Trip';
            final subtitleParts = <String>[
              invite.email,
              invite.role,
              invite.status,
            ];
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.mail_outline),
              title: Text(tripTitle),
              subtitle: Text(subtitleParts.join(' - ')),
              trailing: _buildActions(invite),
            );
          },
        );
      },
    );
  }

  Widget? _buildActions(TripInviteEntity invite) {
    if (onAccept == null && onDecline == null) {
      return null;
    }
    if (invite.status != 'pending') {
      return null;
    }
    return SizedBox(
      width: 48,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          _InviteActionIcon(
            icon: Icons.close,
            color: Colors.redAccent,
            onTap: onDecline == null ? null : () => onDecline!(invite),
          ),
          const SizedBox(width: 4),
          _InviteActionIcon(
            icon: Icons.check_circle,
            color: Colors.teal,
            onTap: onAccept == null ? null : () => onAccept!(invite),
          ),
        ],
      ),
    );
  }
}

class _InviteActionIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _InviteActionIcon({
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      radius: 16,
      child: SizedBox(
        width: 20,
        height: 20,
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }
}
