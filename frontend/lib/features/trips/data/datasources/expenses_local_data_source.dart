import 'package:hive/hive.dart';

import '../models/expense_model.dart';

class ExpensesLocalDataSource {
  final Box<ExpenseModel> box;

  const ExpensesLocalDataSource(this.box);

  Future<List<ExpenseModel>> getExpenses(String tripId) async {
    final expenses = box.values.where((expense) => expense.tripId == tripId).toList();
    expenses.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return expenses;
  }

  Future<void> cacheExpenses(String tripId, List<ExpenseModel> expenses) async {
    final idsToRemove = box.values
        .where((expense) => expense.tripId == tripId)
        .map((expense) => expense.id)
        .toList();
    await box.deleteAll(idsToRemove);
    final map = {for (final expense in expenses) expense.id: expense};
    await box.putAll(map);
  }

  Future<void> upsertExpense(ExpenseModel expense) async {
    await box.put(expense.id, expense);
  }
}
