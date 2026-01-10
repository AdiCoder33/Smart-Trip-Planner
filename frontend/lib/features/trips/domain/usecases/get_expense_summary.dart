import '../entities/expense_summary.dart';
import '../repositories/expenses_repository.dart';

class GetExpenseSummary {
  final ExpensesRepository repository;

  const GetExpenseSummary(this.repository);

  Future<List<ExpenseSummaryEntity>> call(String tripId) {
    return repository.getSummary(tripId);
  }
}
