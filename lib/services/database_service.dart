import 'package:hive_flutter/hive_flutter.dart';
import '../models/expense_model.dart';
import '../models/category_model.dart';

class DatabaseService {
  static const String expenseBoxName = 'expenses';
  static const String categoryBoxName = 'categories';
  static const String savingsBoxName = 'savings';

  static Future<void> init() async {
    await Hive.initFlutter();

    // Register Adapters
    Hive.registerAdapter(ExpenseAdapter());
    Hive.registerAdapter(CategoryAdapter());

    // Open Boxes
    await Hive.openBox<Expense>(expenseBoxName);
    await Hive.openBox<Category>(categoryBoxName);
    await Hive.openBox(savingsBoxName);

    final defaultCategories = {
      'food': Category(id: 'food', name: 'Food', iconCodePoint: '0xf316'),
      'bakery': Category(id: 'bakery', name: 'Bakery', iconCodePoint: '0xe0c9'),
      'grocery': Category(
        id: 'grocery',
        name: 'Grocery',
        iconCodePoint: '0xf37e',
      ),
      'petrol': Category(id: 'petrol', name: 'Petrol', iconCodePoint: '0xf17c'),
      'shopping': Category(
        id: 'shopping',
        name: 'Shopping',
        iconCodePoint: '0xf37d',
      ),
      'lent': Category(id: 'lent', name: 'Lent', iconCodePoint: '0xef70'),
      'egg': Category(id: 'egg', name: 'Egg', iconCodePoint: '0xf05f1'),
      'travel': Category(id: 'travel', name: 'Travel', iconCodePoint: '0xefc6'),
      'rent': Category(id: 'rent', name: 'Rent', iconCodePoint: '0xf107'),
      'allowance': Category(
        id: 'allowance',
        name: 'Allowance',
        iconCodePoint: '0xf520',
      ),
      'entertainment': Category(
        id: 'entertainment',
        name: 'Entertainment',
        iconCodePoint: '0xe40f',
      ),
      'misc': Category(id: 'misc', name: 'MISC', iconCodePoint: '0xef37'),
    };

    final categoryBox = Hive.box<Category>(categoryBoxName);

    // Force update all default categories so names and icons are exactly as expected
    for (var entry in defaultCategories.entries) {
      await categoryBox.put(entry.key, entry.value);
    }

    // Seed savings defaults if empty
    final savingsBox = Hive.box(savingsBoxName);
    if (savingsBox.get('targetAmount') == null) {
      await savingsBox.put('targetAmount', 1000.0);
    }
    if (savingsBox.get('savedAmount') == null) {
      await savingsBox.put('savedAmount', 200.0);
    }
  }

  static const List<String> defaultCategoryIds = [
    'food',
    'bakery',
    'grocery',
    'petrol',
    'egg',
    'shopping',
    'lent',
    'travel',
    'rent',
    'allowance',
    'entertainment',
    'misc',
  ];

  static Box<Expense> get expenseBox => Hive.box<Expense>(expenseBoxName);
  static Box<Category> get categoryBox => Hive.box<Category>(categoryBoxName);
  static Box get savingsBox => Hive.box(savingsBoxName);

  static Future<void> addExpense(Expense expense) async {
    await expenseBox.put(expense.id, expense);
  }

  static Future<void> deleteExpense(String id) async {
    await expenseBox.delete(id);
  }
}
