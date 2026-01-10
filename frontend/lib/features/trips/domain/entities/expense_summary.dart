import 'package:equatable/equatable.dart';

class ExpenseSummaryEntity extends Equatable {
  final String userId;
  final String? userName;
  final double paid;
  final double owed;
  final double net;

  const ExpenseSummaryEntity({
    required this.userId,
    required this.paid,
    required this.owed,
    required this.net,
    this.userName,
  });

  @override
  List<Object?> get props => [userId, userName, paid, owed, net];
}
