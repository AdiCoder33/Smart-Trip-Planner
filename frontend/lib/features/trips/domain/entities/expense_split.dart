import 'package:equatable/equatable.dart';

class ExpenseSplitEntity extends Equatable {
  final String userId;
  final String? userName;
  final double amount;

  const ExpenseSplitEntity({
    required this.userId,
    required this.amount,
    this.userName,
  });

  @override
  List<Object?> get props => [userId, userName, amount];
}
