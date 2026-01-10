import '../entities/expense.dart';
import '../repositories/expenses_repository.dart';

class GetCachedExpenses {
  final ExpensesRepository repository;

  const GetCachedExpenses(this.repository);

  Future<List<ExpenseEntity>> call(String tripId) {
    return repository.getCachedExpenses(tripId);
  }
}
