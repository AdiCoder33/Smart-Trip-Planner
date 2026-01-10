import 'package:hive/hive.dart';

import '../../domain/entities/expense_split.dart';

class ExpenseSplitModel extends ExpenseSplitEntity {
  const ExpenseSplitModel({
    required super.userId,
    required super.amount,
    super.userName,
  });

  factory ExpenseSplitModel.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>?;
    final amountRaw = json['amount'];
    final amountValue = amountRaw is num ? amountRaw.toDouble() : double.parse(amountRaw as String);
    return ExpenseSplitModel(
      userId: user?['id'] as String? ?? json['user_id'] as String,
      userName: user?['name'] as String?,
      amount: amountValue,
    );
  }

  static ExpenseSplitModel fromEntity(ExpenseSplitEntity entity) {
    if (entity is ExpenseSplitModel) {
      return entity;
    }
    return ExpenseSplitModel(
      userId: entity.userId,
      userName: entity.userName,
      amount: entity.amount,
    );
  }
}

class ExpenseSplitModelAdapter extends TypeAdapter<ExpenseSplitModel> {
  @override
  final int typeId = 8;

  @override
  ExpenseSplitModel read(BinaryReader reader) {
    final userId = reader.read() as String;
    final userName = reader.read() as String?;
    final amount = reader.read() as double;
    return ExpenseSplitModel(
      userId: userId,
      userName: userName,
      amount: amount,
    );
  }

  @override
  void write(BinaryWriter writer, ExpenseSplitModel obj) {
    writer
      ..write(obj.userId)
      ..write(obj.userName)
      ..write(obj.amount);
  }
}
