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

  @HiveField(5, defaultValue: false)
  final bool isFromSavings;

  @HiveField(6, defaultValue: false)
  final bool isIncome;

  Expense({
    required this.id,
    required this.amount,
    required this.date,
    required this.categoryId,
    this.note,
    this.isFromSavings = false,
    this.isIncome = false,
  });
}
