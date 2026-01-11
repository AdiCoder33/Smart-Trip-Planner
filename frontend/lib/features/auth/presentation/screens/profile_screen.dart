import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/auth_bloc.dart';
import '../../../trips/domain/entities/trip.dart';
import '../../../trips/domain/usecases/get_sent_invites.dart';
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
      body: BlocProvider(
        create: (_) => SentInvitesCubit(
          getSentInvites: GetSentInvites(collaboratorsRepository),
        )..load(),
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
                Text('Sent Invites', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                BlocBuilder<SentInvitesCubit, SentInvitesState>(
                  builder: (context, state) {
                    if (state.status == SentInvitesStatus.loading) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (state.status == SentInvitesStatus.error) {
                      return Text(
                        state.message ?? 'Failed to load sent invites.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      );
                    }
                    if (state.invites.isEmpty) {
                      return Text(
                        'No sent invites yet.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      );
                    }
                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: state.invites.length,
                      separatorBuilder: (_, __) => const Divider(height: 16),
                      itemBuilder: (context, index) {
                        final invite = state.invites[index];
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
                          subtitle: Text(subtitleParts.join(' • ')),
                        );
                      },
                    );
                  },
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
