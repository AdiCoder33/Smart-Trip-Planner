import '../entities/expense.dart';
import '../repositories/expenses_repository.dart';

class CacheExpenses {
  final ExpensesRepository repository;

  const CacheExpenses(this.repository);

  Future<void> call(String tripId, List<ExpenseEntity> expenses) {
    return repository.cacheExpenses(tripId, expenses);
  }
}
