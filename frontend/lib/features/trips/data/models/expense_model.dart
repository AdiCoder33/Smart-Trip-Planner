import 'package:hive/hive.dart';

import '../../domain/entities/expense.dart';
import '../../domain/entities/expense_split.dart';
import 'expense_split_model.dart';

class ExpenseModel extends ExpenseEntity {
  const ExpenseModel({
    required super.id,
    required super.tripId,
    required super.title,
    required super.amount,
    required super.currency,
    required super.paidById,
    required super.splits,
    required super.createdAt,
    super.paidByName,
  });

  factory ExpenseModel.fromJson(Map<String, dynamic> json) {
    final paidBy = json['paid_by'] as Map<String, dynamic>;
    final splitsJson = json['splits'] as List? ?? [];
    final splits = splitsJson
        .map((item) => ExpenseSplitModel.fromJson(item as Map<String, dynamic>))
        .toList();
    final amountRaw = json['amount'];
    final amountValue = amountRaw is num ? amountRaw.toDouble() : double.parse(amountRaw as String);
    return ExpenseModel(
      id: json['id'] as String,
      tripId: json['trip_id'] as String,
      title: json['title'] as String,
      amount: amountValue,
      currency: (json['currency'] as String?) ?? 'USD',
      paidById: paidBy['id'] as String,
      paidByName: paidBy['name'] as String?,
      splits: splits,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  static ExpenseModel fromEntity(ExpenseEntity entity) {
    if (entity is ExpenseModel) {
      return entity;
    }
    final splits = entity.splits.map(ExpenseSplitModel.fromEntity).toList();
    return ExpenseModel(
      id: entity.id,
      tripId: entity.tripId,
      title: entity.title,
      amount: entity.amount,
      currency: entity.currency,
      paidById: entity.paidById,
      paidByName: entity.paidByName,
      splits: splits,
      createdAt: entity.createdAt,
    );
  }

  ExpenseModel copyWith({
    String? id,
    String? tripId,
    String? title,
    double? amount,
    String? currency,
    String? paidById,
    String? paidByName,
    List<ExpenseSplitEntity>? splits,
    DateTime? createdAt,
  }) {
    return ExpenseModel(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      paidById: paidById ?? this.paidById,
      paidByName: paidByName ?? this.paidByName,
      splits: splits ?? this.splits,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class ExpenseModelAdapter extends TypeAdapter<ExpenseModel> {
  @override
  final int typeId = 7;

  @override
  ExpenseModel read(BinaryReader reader) {
    final id = reader.read() as String;
    final tripId = reader.read() as String;
    final title = reader.read() as String;
    final amount = reader.read() as double;
    final currency = reader.read() as String;
    final paidById = reader.read() as String;
    final paidByName = reader.read() as String?;
    final splits = (reader.read() as List).cast<ExpenseSplitModel>();
    final createdAt = reader.read() as DateTime;
    return ExpenseModel(
      id: id,
      tripId: tripId,
      title: title,
      amount: amount,
      currency: currency,
      paidById: paidById,
      paidByName: paidByName,
      splits: splits,
      createdAt: createdAt,
    );
  }

  @override
  void write(BinaryWriter writer, ExpenseModel obj) {
    writer
      ..write(obj.id)
      ..write(obj.tripId)
      ..write(obj.title)
      ..write(obj.amount)
      ..write(obj.currency)
      ..write(obj.paidById)
      ..write(obj.paidByName)
      ..write(obj.splits.map(ExpenseSplitModel.fromEntity).toList())
      ..write(obj.createdAt);
  }
}
