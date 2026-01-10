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
                TextButton.icon(
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
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    poll.question,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (!poll.isActive)
                  const Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: Text('Closed', style: TextStyle(color: Colors.red)),
                  ),
                if (poll.isPending)
                  const Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: Text('Pending', style: TextStyle(color: Colors.orange)),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            ...poll.options.map((option) => _PollOptionTile(
                  option: option,
                  selectedId: poll.userVoteOptionId,
                  disabled: !poll.isActive || poll.isPending,
                  onSelected: onVote,
                )),
          ],
        ),
      ),
    );
  }
}

class _PollOptionTile extends StatelessWidget {
  final PollOptionEntity option;
  final String? selectedId;
  final bool disabled;
  final ValueChanged<String> onSelected;

  const _PollOptionTile({
    required this.option,
    required this.selectedId,
    required this.disabled,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return RadioListTile<String>(
      value: option.id,
      groupValue: selectedId,
      onChanged: disabled ? null : (value) => value == null ? null : onSelected(value),
      title: Text(option.text),
      subtitle: Text('${option.voteCount} votes'),
      dense: true,
      contentPadding: EdgeInsets.zero,
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
