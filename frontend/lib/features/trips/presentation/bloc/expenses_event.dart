part of 'expenses_bloc.dart';

abstract class ExpensesEvent extends Equatable {
  const ExpensesEvent();

  @override
  List<Object?> get props => [];
}

class ExpensesStarted extends ExpensesEvent {
  final String tripId;

  const ExpensesStarted({required this.tripId});

  @override
  List<Object?> get props => [tripId];
}

class ExpensesRefreshed extends ExpensesEvent {
  final String tripId;

  const ExpensesRefreshed({required this.tripId});

  @override
  List<Object?> get props => [tripId];
}

class ExpenseCreated extends ExpensesEvent {
  final String tripId;
  final String title;
  final double amount;
  final String currency;

  const ExpenseCreated({
    required this.tripId,
    required this.title,
    required this.amount,
    required this.currency,
  });

  @override
  List<Object?> get props => [tripId, title, amount, currency];
}
