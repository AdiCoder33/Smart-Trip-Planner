import '../repositories/expenses_repository.dart';

class DeleteExpense {
  final ExpensesRepository repository;

  const DeleteExpense(this.repository);

  Future<void> call({required String expenseId}) {
    return repository.deleteExpense(expenseId: expenseId);
  }
}
