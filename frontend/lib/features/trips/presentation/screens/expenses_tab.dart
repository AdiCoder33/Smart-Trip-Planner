import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/connectivity/connectivity_cubit.dart';
import '../../../../core/widgets/offline_banner.dart';
import '../../../../core/widgets/skeleton_loader.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../domain/entities/expense.dart';
import '../../domain/entities/expense_summary.dart';
import '../../domain/entities/trip.dart';
import '../bloc/collaborators_bloc.dart';
import '../bloc/expenses_bloc.dart';

class ExpensesTab extends StatelessWidget {
  final TripEntity trip;

  const ExpensesTab({super.key, required this.trip});

  @override
  Widget build(BuildContext context) {
    return BlocListener<ExpensesBloc, ExpensesState>(
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
                message: 'Offline mode: showing cached expenses',
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                Text('Expenses', style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                IconButton(
                  onPressed: () => context.read<ExpensesBloc>().add(
                        ExpensesRefreshed(tripId: trip.id),
                      ),
                  icon: const Icon(Icons.refresh),
                ),
                TextButton.icon(
                  onPressed: () => _showInviteCollaborators(context),
                  icon: const Icon(Icons.person_add_alt_1_outlined),
                  label: const Text('Invite'),
                ),
                FilledButton.icon(
                  onPressed: () => _showCreateExpense(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Add'),
                ),
              ],
            ),
          ),
          Expanded(
            child: BlocBuilder<ExpensesBloc, ExpensesState>(
              builder: (context, state) {
                if (state.status == ExpensesStatus.loading && state.expenses.isEmpty) {
                  return const SkeletonLoader();
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    context.read<ExpensesBloc>().add(ExpensesRefreshed(tripId: trip.id));
                  },
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _SummaryRow(summary: _findSummary(context, state.summary)),
                      const SizedBox(height: 16),
                      if (state.expenses.isEmpty)
                        Center(
                          child: Text(
                            'No expenses yet.',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        )
                      else
                        ...state.expenses.map(
                          (expense) => _ExpenseCard(
                            expense: expense,
                            onEdit: () => _showEditExpense(context, expense),
                            onDelete: () => _confirmDelete(context, expense),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  ExpenseSummaryEntity? _findSummary(
    BuildContext context,
    List<ExpenseSummaryEntity> summary,
  ) {
    final userId = context.read<AuthBloc>().state.user?.id;
    if (userId == null) {
      return null;
    }
    for (final item in summary) {
      if (item.userId == userId) {
        return item;
      }
    }
    return null;
  }

  void _showCreateExpense(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ExpenseFormSheet(
        title: 'Add expense',
        submitLabel: 'Create',
        onSubmit: (title, amount, currency) {
          context.read<ExpensesBloc>().add(
                ExpenseCreated(
                  tripId: trip.id,
                  title: title,
                  amount: amount,
                  currency: currency,
                ),
              );
        },
      ),
    );
  }

  void _showEditExpense(BuildContext context, ExpenseEntity expense) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ExpenseFormSheet(
        title: 'Edit expense',
        submitLabel: 'Save',
        initialTitle: expense.title,
        initialAmount: expense.amount,
        initialCurrency: expense.currency,
        onSubmit: (title, amount, currency) {
          context.read<ExpensesBloc>().add(
                ExpenseUpdated(
                  tripId: trip.id,
                  expenseId: expense.id,
                  title: title,
                  amount: amount,
                  currency: currency,
                ),
              );
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, ExpenseEntity expense) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete expense'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<ExpensesBloc>().add(
                    ExpenseDeleted(tripId: trip.id, expenseId: expense.id),
                  );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showInviteCollaborators(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => BlocProvider.value(
        value: context.read<CollaboratorsBloc>(),
        child: _InviteCollaboratorsSheet(tripId: trip.id),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final ExpenseSummaryEntity? summary;

  const _SummaryRow({required this.summary});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final paid = summary?.paid ?? 0;
    final owed = summary?.owed ?? 0;
    final net = summary?.net ?? 0;

    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            label: 'Paid',
            value: paid,
            color: theme.colorScheme.primary,
            icon: Icons.account_balance_wallet_outlined,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryCard(
            label: 'Owed',
            value: owed,
            color: theme.colorScheme.secondary,
            icon: Icons.receipt_long_outlined,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryCard(
            label: 'Net',
            value: net,
            color: net >= 0 ? Colors.green : Colors.red,
            icon: Icons.swap_horiz,
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final IconData icon;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(label, style: theme.textTheme.bodySmall),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value.toStringAsFixed(2),
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _ExpenseCard extends StatelessWidget {
  final ExpenseEntity expense;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ExpenseCard({
    required this.expense,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final paidBy = expense.paidByName?.trim();
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.payments_outlined, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  expense.title,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Text(
                  paidBy != null && paidBy.isNotEmpty ? 'Paid by $paidBy' : 'Paid by member',
                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.black54),
                ),
                const SizedBox(height: 4),
                Text(
                  '${expense.splits.length} split(s)',
                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.black45),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${expense.currency} ${expense.amount.toStringAsFixed(2)}',
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined),
                    iconSize: 18,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints.tightFor(width: 30, height: 30),
                  ),
                  IconButton(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline),
                    iconSize: 18,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints.tightFor(width: 30, height: 30),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ExpenseFormSheet extends StatefulWidget {
  final void Function(String title, double amount, String currency) onSubmit;
  final String title;
  final String submitLabel;
  final String? initialTitle;
  final double? initialAmount;
  final String? initialCurrency;

  const _ExpenseFormSheet({
    required this.onSubmit,
    required this.title,
    required this.submitLabel,
    this.initialTitle,
    this.initialAmount,
    this.initialCurrency,
  });

  @override
  State<_ExpenseFormSheet> createState() => _ExpenseFormSheetState();
}

class _ExpenseFormSheetState extends State<_ExpenseFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _amountController;
  late final TextEditingController _currencyController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle ?? '');
    _amountController = TextEditingController(
      text: widget.initialAmount?.toStringAsFixed(2) ?? '',
    );
    _currencyController = TextEditingController(text: widget.initialCurrency ?? 'USD');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _currencyController.dispose();
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
            Text(widget.title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title'),
              validator: (value) => value == null || value.trim().isEmpty ? 'Title is required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _amountController,
              decoration: const InputDecoration(labelText: 'Amount'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                final parsed = double.tryParse(value ?? '');
                if (parsed == null || parsed <= 0) {
                  return 'Enter a valid amount';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _currencyController,
              decoration: const InputDecoration(labelText: 'Currency'),
              textCapitalization: TextCapitalization.characters,
              maxLength: 3,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submit,
                child: Text(widget.submitLabel),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final title = _titleController.text.trim();
    final amount = double.parse(_amountController.text.trim());
    final currency = _currencyController.text.trim().toUpperCase();
    widget.onSubmit(title, amount, currency.isEmpty ? 'USD' : currency);
    Navigator.of(context).pop();
  }
}

class _InviteCollaboratorsSheet extends StatefulWidget {
  final String tripId;

  const _InviteCollaboratorsSheet({required this.tripId});

  @override
  State<_InviteCollaboratorsSheet> createState() => _InviteCollaboratorsSheetState();
}

class _InviteCollaboratorsSheetState extends State<_InviteCollaboratorsSheet> {
  final _emailController = TextEditingController();
  final _searchController = TextEditingController();
  Timer? _debounce;
  String _role = 'viewer';
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
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
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Invite collaborators', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
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
            const SizedBox(height: 12),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search users',
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
            if (_query.length >= 2)
              BlocBuilder<CollaboratorsBloc, CollaboratorsState>(
                builder: (context, state) {
                  if (state.isSearching) {
                    return const LinearProgressIndicator(minHeight: 2);
                  }
                  if (state.searchResults.isEmpty) {
                    return Text(
                      'No users found.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    );
                  }
                  return Column(
                    children: state.searchResults
                        .map(
                          (user) => ListTile(
                            dense: true,
                            leading: const CircleAvatar(child: Icon(Icons.person_outline)),
                            title: Text(user.name?.isNotEmpty == true ? user.name! : user.email),
                            subtitle: Text(user.email),
                            trailing: TextButton(
                              onPressed: () => _sendInvite(user.email),
                              child: const Text('Invite'),
                            ),
                          ),
                        )
                        .toList(),
                  );
                },
              ),
            const SizedBox(height: 12),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Invite by email'),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            BlocBuilder<ConnectivityCubit, ConnectivityState>(
              builder: (context, connectivityState) {
                return SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: connectivityState.isOnline ? _sendInviteFromField : null,
                    child: const Text('Send invite'),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    setState(() => _query = query);
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) {
        return;
      }
      context.read<CollaboratorsBloc>().add(
            CollaboratorsSearchRequested(tripId: widget.tripId, query: query),
          );
    });
  }

  void _sendInviteFromField() {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email is required.')),
      );
      return;
    }
    _sendInvite(email);
    _emailController.clear();
  }

  void _sendInvite(String email) {
    context.read<CollaboratorsBloc>().add(
          InviteSent(tripId: widget.tripId, email: email, role: _role),
        );
  }
}
