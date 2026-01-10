import '../entities/expense.dart';
import '../repositories/expenses_repository.dart';

class CreateExpense {
  final ExpensesRepository repository;

  const CreateExpense(this.repository);

  Future<ExpenseEntity> call({
    required String tripId,
    required String title,
    required double amount,
    String currency = 'USD',
  }) {
    return repository.createExpense(
      tripId: tripId,
      title: title,
      amount: amount,
      currency: currency,
    );
  }
}
