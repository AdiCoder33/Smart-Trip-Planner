import 'package:equatable/equatable.dart';

import 'expense_split.dart';

class ExpenseEntity extends Equatable {
  final String id;
  final String tripId;
  final String title;
  final double amount;
  final String currency;
  final String paidById;
  final String? paidByName;
  final List<ExpenseSplitEntity> splits;
  final DateTime createdAt;

  const ExpenseEntity({
    required this.id,
    required this.tripId,
    required this.title,
    required this.amount,
    required this.currency,
    required this.paidById,
    required this.splits,
    required this.createdAt,
    this.paidByName,
  });

  @override
  List<Object?> get props => [
        id,
        tripId,
        title,
        amount,
        currency,
        paidById,
        paidByName,
        splits,
        createdAt,
      ];
}
