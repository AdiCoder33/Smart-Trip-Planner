import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/connectivity/connectivity_cubit.dart';
import '../../../../core/widgets/offline_banner.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../data/repositories/collaborators_repository_impl.dart';
import '../../domain/entities/trip.dart';
import '../../domain/usecases/accept_invite.dart';
import '../bloc/collaborators_bloc.dart';
import '../bloc/invite_accept_cubit.dart';
import 'invite_accept_screen.dart';

class CollaboratorsTab extends StatefulWidget {
  final TripEntity trip;

  const CollaboratorsTab({super.key, required this.trip});

  @override
  State<CollaboratorsTab> createState() => _CollaboratorsTabState();
}

class _CollaboratorsTabState extends State<CollaboratorsTab> {
  final _emailController = TextEditingController();
  final _searchController = TextEditingController();
  String _role = 'viewer';
  String _query = '';

  @override
  void dispose() {
    _emailController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _query = _searchController.text.trim().toLowerCase());
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CollaboratorsBloc, CollaboratorsState>(
      listenWhen: (prev, next) => prev.message != next.message && next.message != null,
      listener: (context, state) {
        if (state.message != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message!)),
          );
        }
      },
      child: BlocBuilder<CollaboratorsBloc, CollaboratorsState>(
        builder: (context, state) {
          final userId = context.read<AuthBloc>().state.user?.id;
          final isOwner = state.members.any(
            (member) => member.userId == userId && member.role == 'owner',
          );
          final filteredMembers = _query.isEmpty
              ? state.members
              : state.members.where((member) {
                  final name = member.name?.toLowerCase() ?? '';
                  final email = member.email.toLowerCase();
                  return name.contains(_query) || email.contains(_query);
                }).toList();

          if (state.status == CollaboratorsStatus.loading && state.members.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              BlocBuilder<ConnectivityCubit, ConnectivityState>(
                builder: (context, connectivityState) {
                  return OfflineBanner(
                    isOnline: connectivityState.isOnline,
                    message: 'Offline mode: collaborators are read-only',
                  );
                },
              ),
              const SizedBox(height: 12),
              _SectionHeader(
                title: 'Members',
                onRefresh: () {
                  context
                      .read<CollaboratorsBloc>()
                      .add(CollaboratorsRefreshed(tripId: widget.trip.id));
                },
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search members by name or email',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => _searchController.clear(),
                        ),
                ),
              ),
              const SizedBox(height: 8),
              if (filteredMembers.isEmpty)
                Text(
                  'No members match your search.',
                  style: Theme.of(context).textTheme.bodyMedium,
                )
              else
                ...filteredMembers.map(
                  (member) => ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.person)),
                    title: Text(member.name?.isNotEmpty == true ? member.name! : member.email),
                    subtitle: Text('${member.email} - ${member.role}'),
                  ),
                ),
              const SizedBox(height: 12),
              if (isOwner) ...[
                const Divider(),
                const SizedBox(height: 12),
                Text('Invite by email', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _role,
                  decoration: const InputDecoration(labelText: 'Role'),
                  items: const [
                    DropdownMenuItem(value: 'editor', child: Text('Editor')),
                    DropdownMenuItem(value: 'viewer', child: Text('Viewer')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _role = value);
                    }
                  },
                ),
                const SizedBox(height: 8),
                BlocBuilder<ConnectivityCubit, ConnectivityState>(
                  builder: (context, connectivityState) {
                    return SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: connectivityState.isOnline ? _sendInvite : null,
                        child: const Text('Send invite'),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                if (state.invites.isNotEmpty) ...[
                  Text('Pending invites', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  ...state.invites.map(
                    (invite) => ListTile(
                      leading: const Icon(Icons.mail_outline),
                      title: Text(invite.email),
                      subtitle: Text('${invite.role} - ${invite.status}'),
                      trailing: TextButton(
                        onPressed: invite.status == 'pending'
                            ? () => context.read<CollaboratorsBloc>().add(
                                  InviteRevoked(inviteId: invite.id),
                                )
                            : null,
                        child: const Text('Revoke'),
                      ),
                    ),
                  ),
                ],
              ],
              const Divider(),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => _openAcceptInvite(context),
                  child: const Text('Accept invite token'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _sendInvite() {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email is required.')),
      );
      return;
    }
    context.read<CollaboratorsBloc>().add(
          InviteSent(tripId: widget.trip.id, email: email, role: _role),
        );
    _emailController.clear();
  }

  Future<void> _openAcceptInvite(BuildContext context) async {
    final repository = context.read<CollaboratorsRepositoryImpl>();
    final bloc = context.read<CollaboratorsBloc>();
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider(
          create: (_) => InviteAcceptCubit(
            acceptInvite: AcceptInvite(repository),
          ),
          child: const InviteAcceptScreen(),
        ),
      ),
    );
    if (!mounted) {
      return;
    }
    bloc.add(CollaboratorsRefreshed(tripId: widget.trip.id));
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback onRefresh;

  const _SectionHeader({required this.title, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const Spacer(),
        IconButton(onPressed: onRefresh, icon: const Icon(Icons.refresh)),
      ],
    );
  }
}
