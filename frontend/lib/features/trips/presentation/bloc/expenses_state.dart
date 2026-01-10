part of 'expenses_bloc.dart';

enum ExpensesStatus { initial, loading, loaded, error }

class ExpensesState extends Equatable {
  final ExpensesStatus status;
  final List<ExpenseEntity> expenses;
  final List<ExpenseSummaryEntity> summary;
  final bool isRefreshing;
  final String? message;
  final String? tripId;

  const ExpensesState({
    this.status = ExpensesStatus.initial,
    this.expenses = const [],
    this.summary = const [],
    this.isRefreshing = false,
    this.message,
    this.tripId,
  });

  ExpensesState copyWith({
    ExpensesStatus? status,
    List<ExpenseEntity>? expenses,
    List<ExpenseSummaryEntity>? summary,
    bool? isRefreshing,
    String? message,
    String? tripId,
  }) {
    return ExpensesState(
      status: status ?? this.status,
      expenses: expenses ?? this.expenses,
      summary: summary ?? this.summary,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      message: message ?? this.message,
      tripId: tripId ?? this.tripId,
    );
  }

  @override
  List<Object?> get props => [status, expenses, summary, isRefreshing, message, tripId];
}
