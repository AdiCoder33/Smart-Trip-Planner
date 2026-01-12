import '../entities/expense.dart';
import '../entities/expense_summary.dart';

abstract class ExpensesRepository {
  Future<List<ExpenseEntity>> getCachedExpenses(String tripId);
  Future<List<ExpenseEntity>> getExpenses(String tripId);
  Future<ExpenseEntity> createExpense({
    required String tripId,
    required String title,
    required double amount,
    String currency,
  });
  Future<ExpenseEntity> updateExpense({
    required String tripId,
    required String expenseId,
    required String title,
    required double amount,
    String currency,
  });
  Future<void> deleteExpense({required String expenseId});
  Future<List<ExpenseSummaryEntity>> getSummary(String tripId);
  Future<void> cacheExpenses(String tripId, List<ExpenseEntity> expenses);
}
