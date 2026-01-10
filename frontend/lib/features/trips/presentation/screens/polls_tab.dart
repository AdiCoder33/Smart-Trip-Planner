import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/connectivity/connectivity_cubit.dart';
import '../../../../core/widgets/offline_banner.dart';
import '../../../../core/widgets/skeleton_loader.dart';
import '../../domain/entities/poll.dart';
import '../../domain/entities/poll_option.dart';
import '../../domain/entities/trip.dart';
import '../bloc/polls_bloc.dart';

class PollsTab extends StatelessWidget {
  final TripEntity trip;

  const PollsTab({super.key, required this.trip});

  @override
  Widget build(BuildContext context) {
    return BlocListener<PollsBloc, PollsState>(
      listenWhen: (prev, next) => prev.message != next.message && next.message != null,
      listener: (context, state) {
        if (state.message != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message!)),
          );
        }
      },
      child: Column(
        children: [
          BlocBuilder<ConnectivityCubit, ConnectivityState>(
            builder: (context, connectivityState) {
              return OfflineBanner(
                isOnline: connectivityState.isOnline,
                message: 'Offline mode: showing cached polls',
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                Text('Polls', style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                FilledButton.icon(
                  onPressed: () => _showCreatePoll(context),
                  icon: const Icon(Icons.add),
                  label: const Text('New poll'),
                ),
              ],
            ),
          ),
          Expanded(
            child: BlocBuilder<PollsBloc, PollsState>(
              builder: (context, state) {
                if (state.status == PollsStatus.loading && state.polls.isEmpty) {
                  return const SkeletonLoader();
                }

                if (state.polls.isEmpty) {
                  return Center(
                    child: Text(
                      'No polls yet.',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    context.read<PollsBloc>().add(PollsRefreshed(tripId: trip.id));
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: state.polls.length,
                    itemBuilder: (context, index) {
                      final poll = state.polls[index];
                      return _PollCard(
                        poll: poll,
                        onVote: (optionId) {
                          context.read<PollsBloc>().add(
                                PollVoted(
                                  tripId: trip.id,
                                  pollId: poll.id,
                                  optionId: optionId,
                                ),
                              );
                        },
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showCreatePoll(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _PollFormSheet(
        onSubmit: (question, options) {
          context.read<PollsBloc>().add(
                PollCreated(tripId: trip.id, question: question, options: options),
              );
        },
      ),
    );
  }
}

class _PollCard extends StatelessWidget {
  final PollEntity poll;
  final ValueChanged<String> onVote;

  const _PollCard({required this.poll, required this.onVote});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalVotes = poll.options.fold<int>(0, (sum, option) => sum + option.voteCount);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  poll.question,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              if (!poll.isActive)
                const _StatusChip(
                  label: 'Closed',
                  color: Colors.red,
                ),
              if (poll.isPending)
                const _StatusChip(
                  label: 'Pending',
                  color: Colors.orange,
                ),
            ],
          ),
          const SizedBox(height: 12),
          ...poll.options.map((option) => _PollOptionTile(
                option: option,
                selectedId: poll.userVoteOptionId,
                disabled: !poll.isActive || poll.isPending,
                totalVotes: totalVotes,
                onSelected: onVote,
              )),
        ],
      ),
    );
  }
}

class _PollOptionTile extends StatelessWidget {
  final PollOptionEntity option;
  final String? selectedId;
  final bool disabled;
  final int totalVotes;
  final ValueChanged<String> onSelected;

  const _PollOptionTile({
    required this.option,
    required this.selectedId,
    required this.disabled,
    required this.totalVotes,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSelected = option.id == selectedId;
    final ratio = totalVotes == 0 ? 0.0 : option.voteCount / totalVotes;
    final percent = (ratio * 100).round();
    final voteLabel = option.voteCount == 1 ? '1 vote' : '${option.voteCount} votes';

    return InkWell(
      onTap: disabled ? null : () => onSelected(option.id),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceVariant.withOpacity(0.6),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? theme.colorScheme.primary : theme.colorScheme.outlineVariant,
            width: isSelected ? 1.4 : 1,
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: ratio.clamp(0.0, 1.0),
                  child: Container(
                    color: theme.colorScheme.primary.withOpacity(0.14),
                  ),
                ),
              ),
            ),
            Row(
              children: [
                Icon(
                  isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                  size: 20,
                  color: isSelected ? theme.colorScheme.primary : Colors.black38,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        option.text,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        voteLabel,
                        style: theme.textTheme.bodySmall?.copyWith(color: Colors.black54),
                      ),
                    ],
                  ),
                ),
                Text(
                  '$percent%',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isSelected ? theme.colorScheme.primary : Colors.black54,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 8, top: 2),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _PollFormSheet extends StatefulWidget {
  final void Function(String question, List<String> options) onSubmit;

  const _PollFormSheet({required this.onSubmit});

  @override
  State<_PollFormSheet> createState() => _PollFormSheetState();
}

class _PollFormSheetState extends State<_PollFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _questionController = TextEditingController();
  final List<TextEditingController> _optionControllers = [
    TextEditingController(),
    TextEditingController(),
  ];

  @override
  void dispose() {
    _questionController.dispose();
    for (final controller in _optionControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Create poll', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextFormField(
              controller: _questionController,
              decoration: const InputDecoration(labelText: 'Question'),
              validator: (value) => value == null || value.trim().isEmpty ? 'Question is required' : null,
            ),
            const SizedBox(height: 12),
            ..._optionControllers.asMap().entries.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: TextFormField(
                      controller: entry.value,
                      decoration: InputDecoration(labelText: 'Option ${entry.key + 1}'),
                      validator: (value) => value == null || value.trim().isEmpty ? 'Option required' : null,
                    ),
                  ),
                ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _addOption,
                icon: const Icon(Icons.add),
                label: const Text('Add option'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submit,
                child: const Text('Create'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _addOption() {
    setState(() {
      _optionControllers.add(TextEditingController());
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final question = _questionController.text.trim();
    final options = _optionControllers
        .map((controller) => controller.text.trim())
        .where((value) => value.isNotEmpty)
        .toList();
    if (options.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('At least two options are required.')),
      );
      return;
    }
    widget.onSubmit(question, options);
    Navigator.of(context).pop();
  }
}
