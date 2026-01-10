import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/connectivity/connectivity_cubit.dart';
import '../../../../core/widgets/offline_banner.dart';
import '../../../../core/widgets/skeleton_loader.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../domain/entities/expense.dart';
import '../../domain/entities/expense_summary.dart';
import '../../domain/entities/trip.dart';
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
                        ...state.expenses.map((expense) => _ExpenseCard(expense: expense)),
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

  const _ExpenseCard({required this.expense});

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
          Text(
            '${expense.currency} ${expense.amount.toStringAsFixed(2)}',
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _ExpenseFormSheet extends StatefulWidget {
  final void Function(String title, double amount, String currency) onSubmit;

  const _ExpenseFormSheet({required this.onSubmit});

  @override
  State<_ExpenseFormSheet> createState() => _ExpenseFormSheetState();
}

class _ExpenseFormSheetState extends State<_ExpenseFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _currencyController = TextEditingController(text: 'USD');

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
            Text('Add expense', style: Theme.of(context).textTheme.titleLarge),
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
                child: const Text('Create'),
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
