import 'package:hive/hive.dart';

part 'expense_model.g.dart';

@HiveType(typeId: 0)
class Expense extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final double amount;

  @HiveField(2)
  final DateTime date;

  @HiveField(3)
  final String categoryId;

  @HiveField(4)
  final String? note;

  Expense({
    required this.id,
    required this.amount,
    required this.date,
    required this.categoryId,
    this.note,
  });
}
