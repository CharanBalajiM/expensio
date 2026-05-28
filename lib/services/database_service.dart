import 'package:hive_flutter/hive_flutter.dart';
import '../models/expense_model.dart';
import '../models/category_model.dart';

class DatabaseService {
  static const String expenseBoxName = 'expenses';
  static const String categoryBoxName = 'categories';

  static Future<void> init() async {
    await Hive.initFlutter();
    
    // Register Adapters (will be generated)
    Hive.registerAdapter(ExpenseAdapter());
    Hive.registerAdapter(CategoryAdapter());

    // Open Boxes
    await Hive.openBox<Expense>(expenseBoxName);
    await Hive.openBox<Category>(categoryBoxName);
    
    // Seed some initial categories if empty
    final categoryBox = Hive.box<Category>(categoryBoxName);
    if (categoryBox.isEmpty) {
      await categoryBox.putAll({
        'food': Category(id: 'food', name: 'Food & Dining', iconCodePoint: '0xe25a'), 
        'transport': Category(id: 'transport', name: 'Transportation', iconCodePoint: '0xe1d5'),
        'shopping': Category(id: 'shopping', name: 'Shopping', iconCodePoint: '0xe5fc'),
        'bills': Category(id: 'bills', name: 'Bills & Utilities', iconCodePoint: '0xe4fc'),
        'entertainment': Category(id: 'entertainment', name: 'Entertainment', iconCodePoint: '0xe40f'),
      });
    }
  }

  static Box<Expense> get expenseBox => Hive.box<Expense>(expenseBoxName);
  static Box<Category> get categoryBox => Hive.box<Category>(categoryBoxName);

  static Future<void> addExpense(Expense expense) async {
    await expenseBox.put(expense.id, expense);
  }

  static Future<void> deleteExpense(String id) async {
    await expenseBox.delete(id);
  }
}
