import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../blocs/expense/expense_bloc.dart';
import '../blocs/savings/savings_bloc.dart';
import '../models/expense_model.dart';
import '../models/category_model.dart';
import '../services/database_service.dart';

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _newCategoryController = TextEditingController();

  Category? _selectedCategory;
  bool _isAddingCategory = false;
  DateTime _selectedDate = DateTime.now();
  bool _isFromSavings = false;

  final Map<String, List<double>> _quickActions = {
    'rent': [7500],
    'petrol': [100, 110, 200],
    'bakery': [37, 50, 100],
    'food': [90, 100, 200],
    'grocery': [20, 50, 100],
    'shopping': [50, 100, 200],
    'egg': [60, 80],
    'travel': [80, 90, 100],
    'allowance': [1000, 2000, 3000],
    'entertainment': [100, 200, 500],
    'lent': [100, 200, 500],
    'misc': [50, 100],
  };

  @override
  void initState() {
    super.initState();
    _amountController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _newCategoryController.dispose();
    super.dispose();
  }

  void _saveExpense() {
    if (_amountController.text.isEmpty || _selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter an amount and select a category.'),
          backgroundColor: Color(0xFF00E676),
        ),
      );
      return;
    }

    final amount = double.tryParse(_amountController.text) ?? 0.0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please enter a valid amount.',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final expense = Expense(
      id: const Uuid().v4(),
      amount: amount,
      date: _selectedDate,
      categoryId: _selectedCategory!.id,
      note: _noteController.text.isNotEmpty ? _noteController.text : null,
      isFromSavings: _isFromSavings,
    );

    context.read<ExpenseBloc>().add(AddExpenseEvent(expense));
    Navigator.pop(context);
  }

  Future<void> _pickDate(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF00E676),
              onPrimary: Colors.black,
              surface: Color(0xFF141416),
              onSurface: Colors.white,
            ),
            dialogTheme: DialogThemeData(
              backgroundColor: const Color(0xFF141416),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _addNewCategory() {
    final name = _newCategoryController.text.trim();
    if (name.isNotEmpty) {
      final newCat = Category(
        id: const Uuid().v4(),
        name: name,
        iconCodePoint: '0xe5c3',
      );
      DatabaseService.categoryBox.put(newCat.id, newCat);
      setState(() {
        _selectedCategory = newCat;
        _isAddingCategory = false;
        _newCategoryController.clear();
      });
    } else {
      setState(() {
        _isAddingCategory = false;
      });
    }
  }

  void _showDeleteCategoryDialog(Category cat) {
    if (DatabaseService.defaultCategoryIds.contains(cat.id)) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF141416),
        title: Text('Delete ${cat.name}?'),
        content: const Text(
          'Are you sure you want to delete this custom category?',
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              DatabaseService.categoryBox.delete(cat.id);
              if (_selectedCategory?.id == cat.id) {
                setState(() => _selectedCategory = null);
              } else {
                setState(() {});
              }
              Navigator.pop(ctx);
            },
            child: const Text(
              'DELETE -',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySection() {
    final categories = DatabaseService.categoryBox.values.toList();

    // Sort categories based on the order defined in defaultCategoryIds
    final predefinedOrder = DatabaseService.defaultCategoryIds;
    categories.sort((a, b) {
      final indexA = predefinedOrder.indexOf(a.id);
      final indexB = predefinedOrder.indexOf(b.id);

      if (indexA != -1 && indexB != -1) return indexA.compareTo(indexB);
      if (indexA != -1 && indexB == -1) return -1;
      if (indexA == -1 && indexB != -1) return 1;
      return a.name.compareTo(b.name);
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '1. Select Category',
          style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            ...categories.map((cat) {
              final isSelected = _selectedCategory?.id == cat.id;
              final isCustom = !DatabaseService.defaultCategoryIds.contains(
                cat.id,
              );

              return GestureDetector(
                onTap: () {
                  setState(() => _selectedCategory = cat);
                },
                onLongPress: isCustom
                    ? () => _showDeleteCategoryDialog(cat)
                    : null,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF00E676).withValues(alpha: 0.15)
                        : const Color(0xFF141416),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF00E676)
                          : Colors.white.withValues(alpha: 0.05),
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        IconData(
                          int.parse(cat.iconCodePoint),
                          fontFamily: 'MaterialIcons',
                        ),
                        size: 16,
                        color:
                            DatabaseService.categoryColors[cat.id] ??
                            Colors.white,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        cat.name,
                        style: TextStyle(
                          color: isSelected
                              ? const Color(0xFF00E676)
                              : Colors.white,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),

            // Add Category Button / Input
            if (_isAddingCategory)
              Container(
                width: 150,
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF141416),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF00E676)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _newCategoryController,
                        autofocus: true,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.white,
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Name...',
                          hintStyle: TextStyle(
                            color: Colors.grey,
                            fontSize: 13,
                          ),
                          isDense: true,
                        ),
                        onSubmitted: (_) => _addNewCategory(),
                      ),
                    ),
                    GestureDetector(
                      onTap: _addNewCategory,
                      child: const Icon(
                        Icons.check,
                        color: Color(0xFF00E676),
                        size: 18,
                      ),
                    ),
                  ],
                ),
              )
            else
              GestureDetector(
                onTap: () => setState(() => _isAddingCategory = true),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    border: Border.all(
                      color: Colors.grey,
                      style: BorderStyle.solid,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add, size: 16, color: Colors.grey),
                      SizedBox(width: 6),
                      Text(
                        'Add',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildAmountSection(SavingsState savingsState) {
    final typedAmount = double.tryParse(_amountController.text) ?? 0.0;

    // Calculate total expenses so far (only normal expenses)
    final totalExpenses = DatabaseService.expenseBox.values
        .where((e) => !e.isFromSavings)
        .fold(0.0, (sum, e) => sum + e.amount);
    final normalAvailable = savingsState.initialBalance - totalExpenses;

    // Calculate total savings so far
    final savingsExpenses = DatabaseService.expenseBox.values
        .where((e) => e.isFromSavings)
        .fold(0.0, (sum, e) => sum + e.amount);
    final historicalSavingsMap = Map<String, double>.from(
      DatabaseService.savingsBox.get('historicalSavings') ?? {},
    );
    final rawTotalSavings = historicalSavingsMap.values.fold(
      0.0,
      (sum, val) => sum + val,
    );
    final savingsAvailable = rawTotalSavings - savingsExpenses;

    final availableBalance = _isFromSavings
        ? savingsAvailable
        : normalAvailable;
    final remainingBalance = availableBalance - typedAmount;

    // Determine Quick Actions
    List<double> currentQA = [];
    if (_selectedCategory != null) {
      final key = _selectedCategory!.name.toLowerCase();
      currentQA = _quickActions[key] ?? [];
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '2. Amount',
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
            ),
            GestureDetector(
              onTap: () => _pickDate(context),
              child: Row(
                children: [
                  Text(
                    DateFormat('MMM d, yyyy').format(_selectedDate),
                    style: const TextStyle(
                      color: Color(0xFF00E676),
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.calendar_today,
                    color: Color(0xFF00E676),
                    size: 14,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Dynamic Balance Display
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Available: ${NumberFormat.currency(symbol: '₹', decimalDigits: 0).format(availableBalance)}',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            if (_amountController.text.isNotEmpty)
              Text(
                'Remaining: ${NumberFormat.currency(symbol: '₹', decimalDigits: 0).format(remainingBalance)}',
                style: TextStyle(
                  color: remainingBalance < 0
                      ? Colors.redAccent
                      : const Color(0xFF00E676),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),

        // Amount Field
        TextField(
          controller: _amountController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(
            fontSize: 42,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          decoration: InputDecoration(
            prefixText: '₹ ',
            prefixStyle: const TextStyle(fontSize: 42, color: Colors.grey),
            filled: true,
            fillColor: const Color(0xFF141416),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 20,
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Quick Actions
        if (currentQA.isNotEmpty)
          Wrap(
            spacing: 8,
            children: currentQA.map((amt) {
              return ActionChip(
                backgroundColor: const Color(0xFF141416),
                side: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
                label: Text(
                  '+₹${amt.toStringAsFixed(0)}',
                  style: const TextStyle(color: Colors.white),
                ),
                onPressed: () {
                  _amountController.text = amt.toStringAsFixed(0);
                },
              );
            }).toList(),
          ),
        const SizedBox(height: 24),

        // Deduct From Selection
        const Text(
          'Deduct From',
          style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _isFromSavings = false),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: !_isFromSavings
                        ? const Color(0xFF00E676).withValues(alpha: 0.15)
                        : const Color(0xFF141416),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: !_isFromSavings
                          ? const Color(0xFF00E676)
                          : Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'Normal Balance',
                    style: TextStyle(
                      color: !_isFromSavings
                          ? const Color(0xFF00E676)
                          : Colors.white,
                      fontWeight: !_isFromSavings
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _isFromSavings = true),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: _isFromSavings
                        ? const Color(0xFF00E676).withValues(alpha: 0.15)
                        : const Color(0xFF141416),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _isFromSavings
                          ? const Color(0xFF00E676)
                          : Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'Savings Balance',
                    style: TextStyle(
                      color: _isFromSavings
                          ? const Color(0xFF00E676)
                          : Colors.white,
                      fontWeight: _isFromSavings
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNotesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '3. Notes (Optional)',
          style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _noteController,
          maxLines: 3,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Write something...',
            hintStyle: const TextStyle(color: Colors.grey),
            filled: true,
            fillColor: const Color(0xFF141416),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Add Expense',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: BlocBuilder<SavingsBloc, SavingsState>(
          builder: (context, savingsState) {
            return SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20.0,
                        vertical: 10.0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildCategorySection(),
                          const SizedBox(height: 32),
                          _buildAmountSection(savingsState),
                          const SizedBox(height: 32),
                          _buildNotesSection(),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: ElevatedButton(
                      onPressed: _saveExpense,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        backgroundColor: const Color(0xFF00E676),
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 5,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_outline),
                          SizedBox(width: 8),
                          Text(
                            'SAVE EXPENSE',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
