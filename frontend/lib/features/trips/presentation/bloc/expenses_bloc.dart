import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/connectivity/connectivity_service.dart';
import '../../../../core/errors/app_exception.dart';
import '../../domain/entities/expense.dart';
import '../../domain/entities/expense_summary.dart';
import '../../domain/usecases/cache_expenses.dart';
import '../../domain/usecases/create_expense.dart';
import '../../domain/usecases/delete_expense.dart';
import '../../domain/usecases/get_cached_expenses.dart';
import '../../domain/usecases/get_expense_summary.dart';
import '../../domain/usecases/get_expenses.dart';
import '../../domain/usecases/update_expense.dart';

part 'expenses_event.dart';
part 'expenses_state.dart';

class ExpensesBloc extends Bloc<ExpensesEvent, ExpensesState> {
  final GetExpenses getExpenses;
  final GetCachedExpenses getCachedExpenses;
  final CreateExpense createExpense;
  final UpdateExpense updateExpense;
  final DeleteExpense deleteExpense;
  final GetExpenseSummary getExpenseSummary;
  final CacheExpenses cacheExpenses;
  final ConnectivityService connectivityService;

  ExpensesBloc({
    required this.getExpenses,
    required this.getCachedExpenses,
    required this.createExpense,
    required this.updateExpense,
    required this.deleteExpense,
    required this.getExpenseSummary,
    required this.cacheExpenses,
    required this.connectivityService,
  }) : super(const ExpensesState()) {
    on<ExpensesStarted>(_onStarted);
    on<ExpensesRefreshed>(_onRefreshed);
    on<ExpenseCreated>(_onCreated);
    on<ExpenseUpdated>(_onUpdated);
    on<ExpenseDeleted>(_onDeleted);
  }

  Future<void> _onStarted(ExpensesStarted event, Emitter<ExpensesState> emit) async {
    emit(state.copyWith(status: ExpensesStatus.loading, message: null, tripId: event.tripId));
    final cached = await getCachedExpenses(event.tripId);
    emit(state.copyWith(status: ExpensesStatus.loading, expenses: cached, tripId: event.tripId));

    final online = await connectivityService.isOnline();
    if (!online) {
      emit(state.copyWith(status: ExpensesStatus.loaded));
      return;
    }

    try {
      final remote = await getExpenses(event.tripId);
      final summary = await getExpenseSummary(event.tripId);
      emit(state.copyWith(status: ExpensesStatus.loaded, expenses: remote, summary: summary));
      await cacheExpenses(event.tripId, remote);
    } catch (error) {
      final message = error is AppException ? error.message : 'Failed to load expenses';
      emit(state.copyWith(status: ExpensesStatus.error, message: message));
    }
  }

  Future<void> _onRefreshed(ExpensesRefreshed event, Emitter<ExpensesState> emit) async {
    final online = await connectivityService.isOnline();
    if (!online) {
      emit(state.copyWith(message: 'You are offline.'));
      return;
    }
    emit(state.copyWith(isRefreshing: true, message: null));
    try {
      final remote = await getExpenses(event.tripId);
      final summary = await getExpenseSummary(event.tripId);
      emit(state.copyWith(
        status: ExpensesStatus.loaded,
        expenses: remote,
        summary: summary,
        isRefreshing: false,
      ));
      await cacheExpenses(event.tripId, remote);
    } catch (error) {
      final message = error is AppException ? error.message : 'Failed to refresh expenses';
      emit(state.copyWith(isRefreshing: false, message: message));
    }
  }

  Future<void> _onCreated(ExpenseCreated event, Emitter<ExpensesState> emit) async {
    final online = await connectivityService.isOnline();
    if (!online) {
      emit(state.copyWith(message: 'You are offline. Expense creation is disabled.'));
      return;
    }
    try {
      final created = await createExpense(
        tripId: event.tripId,
        title: event.title,
        amount: event.amount,
        currency: event.currency,
      );
      final updated = [created, ...state.expenses];
      emit(state.copyWith(expenses: updated));
      final summary = await getExpenseSummary(event.tripId);
      emit(state.copyWith(summary: summary));
      await cacheExpenses(event.tripId, updated);
    } catch (error) {
      final message = error is AppException ? error.message : 'Failed to create expense';
      emit(state.copyWith(message: message));
    }
  }

  Future<void> _onUpdated(ExpenseUpdated event, Emitter<ExpensesState> emit) async {
    final online = await connectivityService.isOnline();
    if (!online) {
      emit(state.copyWith(message: 'You are offline. Editing expenses is disabled.'));
      return;
    }
    try {
      final updated = await updateExpense(
        tripId: event.tripId,
        expenseId: event.expenseId,
        title: event.title,
        amount: event.amount,
        currency: event.currency,
      );
      final updatedExpenses = state.expenses
          .map((expense) => expense.id == updated.id ? updated : expense)
          .toList();
      emit(state.copyWith(expenses: updatedExpenses));
      await cacheExpenses(event.tripId, updatedExpenses);
      final summary = await getExpenseSummary(event.tripId);
      emit(state.copyWith(summary: summary));
    } catch (error) {
      final message = error is AppException ? error.message : 'Failed to update expense';
      emit(state.copyWith(message: message));
    }
  }

  Future<void> _onDeleted(ExpenseDeleted event, Emitter<ExpensesState> emit) async {
    final online = await connectivityService.isOnline();
    if (!online) {
      emit(state.copyWith(message: 'You are offline. Deleting expenses is disabled.'));
      return;
    }
    final previous = state.expenses;
    final updated = previous.where((expense) => expense.id != event.expenseId).toList();
    emit(state.copyWith(expenses: updated));
    try {
      await deleteExpense(expenseId: event.expenseId);
      await cacheExpenses(event.tripId, updated);
      final summary = await getExpenseSummary(event.tripId);
      emit(state.copyWith(summary: summary, message: 'Expense deleted.'));
    } catch (error) {
      final message = error is AppException ? error.message : 'Failed to delete expense';
      emit(state.copyWith(expenses: previous, message: message));
    }
  }
}
