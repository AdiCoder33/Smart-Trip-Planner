import '../entities/expense.dart';
import '../repositories/expenses_repository.dart';

class GetExpenses {
  final ExpensesRepository repository;

  const GetExpenses(this.repository);

  Future<List<ExpenseEntity>> call(String tripId) {
    return repository.getExpenses(tripId);
  }
}
