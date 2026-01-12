import '../../domain/entities/expense.dart';
import '../../domain/entities/expense_summary.dart';
import '../../domain/repositories/expenses_repository.dart';
import '../datasources/expenses_local_data_source.dart';
import '../datasources/expenses_remote_data_source.dart';
import '../models/expense_model.dart';

class ExpensesRepositoryImpl implements ExpensesRepository {
  final ExpensesRemoteDataSource remoteDataSource;
  final ExpensesLocalDataSource localDataSource;

  const ExpensesRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<List<ExpenseEntity>> getCachedExpenses(String tripId) async {
    return localDataSource.getExpenses(tripId);
  }

  @override
  Future<List<ExpenseEntity>> getExpenses(String tripId) async {
    final expenses = await remoteDataSource.fetchExpenses(tripId);
    await localDataSource.cacheExpenses(tripId, expenses);
    return expenses;
  }

  @override
  Future<ExpenseEntity> createExpense({
    required String tripId,
    required String title,
    required double amount,
    String currency = 'USD',
  }) async {
    final expense = await remoteDataSource.createExpense(
      tripId: tripId,
      title: title,
      amount: amount,
      currency: currency,
    );
    await localDataSource.upsertExpense(expense);
    return expense;
  }

  @override
  Future<ExpenseEntity> updateExpense({
    required String tripId,
    required String expenseId,
    required String title,
    required double amount,
    String currency = 'USD',
  }) async {
    final expense = await remoteDataSource.updateExpense(
      expenseId: expenseId,
      title: title,
      amount: amount,
      currency: currency,
    );
    await localDataSource.upsertExpense(expense);
    return expense;
  }

  @override
  Future<void> deleteExpense({required String expenseId}) async {
    await remoteDataSource.deleteExpense(expenseId);
    await localDataSource.deleteExpense(expenseId);
  }

  @override
  Future<List<ExpenseSummaryEntity>> getSummary(String tripId) {
    return remoteDataSource.fetchSummary(tripId);
  }

  @override
  Future<void> cacheExpenses(String tripId, List<ExpenseEntity> expenses) async {
    final models = expenses.map(ExpenseModel.fromEntity).toList();
    await localDataSource.cacheExpenses(tripId, models);
  }
}
