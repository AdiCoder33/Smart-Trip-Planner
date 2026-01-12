import '../entities/expense.dart';
import '../repositories/expenses_repository.dart';

class UpdateExpense {
  final ExpensesRepository repository;

  const UpdateExpense(this.repository);

  Future<ExpenseEntity> call({
    required String tripId,
    required String expenseId,
    required String title,
    required double amount,
    String currency = 'USD',
  }) {
    return repository.updateExpense(
      tripId: tripId,
      expenseId: expenseId,
      title: title,
      amount: amount,
      currency: currency,
    );
  }
}
