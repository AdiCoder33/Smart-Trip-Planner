import 'package:dio/dio.dart';

import '../models/expense_model.dart';
import '../../domain/entities/expense_summary.dart';

class ExpensesRemoteDataSource {
  final Dio dio;

  const ExpensesRemoteDataSource(this.dio);

  Future<List<ExpenseModel>> fetchExpenses(String tripId) async {
    final response = await dio.get('/api/trips/$tripId/expenses');
    final data = response.data as List;
    return data
        .map((item) => ExpenseModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<ExpenseModel> createExpense({
    required String tripId,
    required String title,
    required double amount,
    String currency = 'USD',
  }) async {
    final response = await dio.post(
      '/api/trips/$tripId/expenses',
      data: {
        'title': title,
        'amount': amount.toStringAsFixed(2),
        'currency': currency,
      },
    );
    return ExpenseModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<ExpenseModel> updateExpense({
    required String expenseId,
    required String title,
    required double amount,
    String currency = 'USD',
  }) async {
    final response = await dio.patch(
      '/api/expenses/$expenseId',
      data: {
        'title': title,
        'amount': amount.toStringAsFixed(2),
        'currency': currency,
      },
    );
    return ExpenseModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteExpense(String expenseId) async {
    await dio.delete('/api/expenses/$expenseId');
  }

  Future<List<ExpenseSummaryEntity>> fetchSummary(String tripId) async {
    final response = await dio.get('/api/trips/$tripId/expenses/summary');
    final data = response.data as List;
    return data.map((item) {
      final map = item as Map<String, dynamic>;
      final user = map['user'] as Map<String, dynamic>;
      final paidRaw = map['paid'];
      final owedRaw = map['owed'];
      final netRaw = map['net'];
      return ExpenseSummaryEntity(
        userId: user['id'] as String,
        userName: user['name'] as String?,
        paid: paidRaw is num ? paidRaw.toDouble() : double.parse(paidRaw as String),
        owed: owedRaw is num ? owedRaw.toDouble() : double.parse(owedRaw as String),
        net: netRaw is num ? netRaw.toDouble() : double.parse(netRaw as String),
      );
    }).toList();
  }
}
