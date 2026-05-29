import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:auto_size_text/auto_size_text.dart';
import '../blocs/expense/expense_bloc.dart';
import '../blocs/savings/savings_bloc.dart';
import '../models/expense_model.dart';
import '../models/category_model.dart';
import '../services/database_service.dart';
import 'main_navigation_screen.dart';
import 'add_expense_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _savedController = TextEditingController();
  final _goalController = TextEditingController();
  final _initialBalanceController = TextEditingController();
  bool _isShowingSalaryPopup = false;
  String? _touchedChartCategoryId;

  @override
  void dispose() {
    _savedController.dispose();
    _goalController.dispose();
    _initialBalanceController.dispose();
    super.dispose();
  }

  void _showInitialBalanceDialog(
    BuildContext context,
    double currentInitialBalance,
    double currentBalance,
  ) {
    _initialBalanceController.text = '';

    showDialog(
      context: context,
      builder: (context) {
        bool isAdding = true;
        return Dialog(
          backgroundColor: const Color(0xFF141416),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(
              color: Colors.white.withValues(alpha: 0.05),
              width: 1,
            ),
          ),
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 24,
          ),
          child: StatefulBuilder(
            builder: (context, setState) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        vertical: 24,
                        horizontal: 16,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF00E676).withValues(alpha: 0.15),
                            const Color(0xFF00B0FF).withValues(alpha: 0.02),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        border: Border(
                          bottom: BorderSide(
                            color: const Color(
                              0xFF00E676,
                            ).withValues(alpha: 0.1),
                            width: 1,
                          ),
                        ),
                      ),
                      child: Text(
                        isAdding ? 'Add Total Balance' : 'Deduct Total Balance',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    isAdding = !isAdding;
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: isAdding
                                        ? const Color(
                                            0xFF00E676,
                                          ).withValues(alpha: 0.15)
                                        : Colors.redAccent.withValues(
                                            alpha: 0.15,
                                          ),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isAdding
                                          ? const Color(
                                              0xFF00E676,
                                            ).withValues(alpha: 0.3)
                                          : Colors.redAccent.withValues(
                                              alpha: 0.3,
                                            ),
                                    ),
                                  ),
                                  child: Text(
                                    isAdding ? '+' : '-',
                                    style: TextStyle(
                                      color: isAdding
                                          ? const Color(0xFF00E676)
                                          : Colors.redAccent,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 24,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: TextField(
                                  controller: _initialBalanceController,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  decoration: InputDecoration(
                                    prefixText: '₹ ',
                                    prefixStyle: const TextStyle(
                                      fontSize: 28,
                                      color: Colors.grey,
                                    ),
                                    filled: true,
                                    fillColor: const Color(0xFF1E1E22),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide.none,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _buildQuickAddButton(200, isAdding),
                              _buildQuickAddButton(500, isAdding),
                              _buildQuickAddButton(1000, isAdding),
                            ],
                          ),
                          const SizedBox(height: 32),
                          Row(
                            children: [
                              Expanded(
                                child: TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text(
                                    'Cancel',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () {
                                    final amount =
                                        double.tryParse(
                                          _initialBalanceController.text,
                                        ) ??
                                        0.0;
                                    if (amount <= 0) {
                                      Navigator.pop(context);
                                      return;
                                    }

                                    if (!isAdding && amount > currentBalance) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Cannot deduct more than available balance (₹${currentBalance.toStringAsFixed(0)})',
                                          ),
                                          backgroundColor: Color(0xFF00E676),
                                        ),
                                      );
                                      return;
                                    }

                                    final newInitialBalance = isAdding
                                        ? currentInitialBalance + amount
                                        : currentInitialBalance - amount;

                                    context.read<SavingsBloc>().add(
                                      UpdateInitialBalance(newInitialBalance),
                                    );
                                    Navigator.pop(context);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF00E676),
                                    foregroundColor: Colors.black,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text(
                                    'Save',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildQuickAddButton(double amount, bool isAdding) {
    return GestureDetector(
      onTap: () {
        final currentAmount =
            double.tryParse(_initialBalanceController.text) ?? 0.0;
        final newAmount = currentAmount + amount; // Just add to the delta
        _initialBalanceController.text = newAmount.toStringAsFixed(0);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E22),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          '${isAdding ? '+' : '-'}₹${amount.toStringAsFixed(0)}',
          style: TextStyle(
            color: isAdding ? const Color(0xFF00E676) : Colors.redAccent,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  void _showSavingsDialog(BuildContext context, double currentGoal) {
    _goalController.text = currentGoal.toStringAsFixed(0);

    Widget buildPresetChip(StateSetter dialogSetState, double amount) {
      final isSelected = double.tryParse(_goalController.text) == amount;
      return GestureDetector(
        onTap: () {
          dialogSetState(() {
            _goalController.text = amount.toStringAsFixed(0);
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF00E676).withValues(alpha: 0.15)
                : const Color(0xFF1E1E22),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF00E676)
                  : Colors.white.withValues(alpha: 0.05),
              width: 1,
            ),
          ),
          child: Text(
            NumberFormat.currency(symbol: '₹', decimalDigits: 0).format(amount),
            style: TextStyle(
              color: isSelected
                  ? const Color(0xFF00E676)
                  : Colors.white.withValues(alpha: 0.7),
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      );
    }

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: const Color(0xFF141416),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(
              color: Colors.white.withValues(alpha: 0.05),
              width: 1,
            ),
          ),
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 24,
          ),
          child: StatefulBuilder(
            builder: (context, dialogSetState) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Premium Gradient Header
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        vertical: 24,
                        horizontal: 16,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF00E676).withValues(alpha: 0.15),
                            const Color(0xFF00B0FF).withValues(alpha: 0.02),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        border: Border(
                          bottom: BorderSide(
                            color: const Color(
                              0xFF00E676,
                            ).withValues(alpha: 0.1),
                            width: 1,
                          ),
                        ),
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF00E676,
                              ).withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF00E676,
                                  ).withValues(alpha: 0.2),
                                  blurRadius: 16,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.track_changes_rounded,
                              color: Color(0xFF00E676),
                              size: 32,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Savings Goal',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Set your monthly milestone',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Interactive body content
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Input field
                            TextField(
                              controller: _goalController,
                              keyboardType: TextInputType.number,
                              onChanged: (val) {
                                dialogSetState(() {});
                              },
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              decoration: InputDecoration(
                                labelText: 'Target Goal Amount',
                                labelStyle: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.6),
                                  fontSize: 14,
                                ),
                                prefixIcon: const Icon(
                                  Icons.currency_rupee_rounded,
                                  color: Color(0xFF00E676),
                                  size: 20,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.white.withValues(alpha: 0.1),
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.white.withValues(alpha: 0.1),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF00E676),
                                    width: 2,
                                  ),
                                ),
                                filled: true,
                                fillColor: const Color(0xFF1E1E22),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Quick presets chips
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              alignment: WrapAlignment.center,
                              children: [
                                buildPresetChip(dialogSetState, 3000),
                                buildPresetChip(dialogSetState, 4000),
                                buildPresetChip(dialogSetState, 5000),
                              ],
                            ),
                            const SizedBox(height: 28),
                            // Action Buttons
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () => Navigator.pop(context),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      side: BorderSide(
                                        color: Colors.white.withValues(
                                          alpha: 0.1,
                                        ),
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: Text(
                                      'Cancel',
                                      style: TextStyle(
                                        color: Colors.white.withValues(
                                          alpha: 0.7,
                                        ),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () {
                                      final goal =
                                          double.tryParse(
                                            _goalController.text,
                                          ) ??
                                          1000.0;
                                      context.read<SavingsBloc>().add(
                                        UpdateTargetAmount(goal),
                                      );
                                      Navigator.pop(context);
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF00E676),
                                      foregroundColor: Colors.black,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      elevation: 4,
                                      shadowColor: const Color(
                                        0xFF00E676,
                                      ).withValues(alpha: 0.4),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: const Text(
                                      'Apply Goal',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
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
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expens.io'),
        actions: [
          CircleAvatar(
            backgroundColor: const Color(0xFF1E1E22),
            child: IconButton(
              icon: const Icon(Icons.add, color: Color(0xFF00E676)),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddExpenseScreen(),
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          if (_touchedChartCategoryId != null) {
            setState(() {
              _touchedChartCategoryId = null;
            });
          }
        },
        child: BlocBuilder<ExpenseBloc, ExpenseState>(
          builder: (context, expenseState) {
            return BlocBuilder<SavingsBloc, SavingsState>(
              builder: (context, savingsState) {
                if (expenseState.isLoading || savingsState.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                final expenses = expenseState.expenses;

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _checkAndShowSalaryPopup(context, expenses);
                });

                // Stat calculations
                final now = DateTime.now();
                final todayExpenses = expenses
                    .where(
                      (e) =>
                          e.date.day == now.day &&
                          e.date.month == now.month &&
                          e.date.year == now.year,
                    )
                    .fold(0.0, (sum, e) => sum + e.amount);

                final yesterday = now.subtract(const Duration(days: 1));
                final yesterdayExpenses = expenses
                    .where(
                      (e) =>
                          e.date.day == yesterday.day &&
                          e.date.month == yesterday.month &&
                          e.date.year == yesterday.year,
                    )
                    .fold(0.0, (sum, e) => sum + e.amount);

                double todayPercentage = 0.0;
                if (yesterdayExpenses > 0) {
                  todayPercentage =
                      ((todayExpenses - yesterdayExpenses) /
                          yesterdayExpenses) *
                      100;
                } else if (todayExpenses > 0) {
                  todayPercentage = 100.0;
                }

                final startOfWeek = DateTime(
                  now.year,
                  now.month,
                  now.day,
                ).subtract(Duration(days: now.weekday - 1));
                final weeklyExpenses = expenses
                    .where(
                      (e) =>
                          e.date.isAfter(startOfWeek) ||
                          e.date.isAtSameMomentAs(startOfWeek),
                    )
                    .fold(0.0, (sum, e) => sum + e.amount);

                final startOfLastWeek = startOfWeek.subtract(
                  const Duration(days: 7),
                );
                final lastWeekExpenses = expenses
                    .where(
                      (e) =>
                          (e.date.isAfter(startOfLastWeek) ||
                              e.date.isAtSameMomentAs(startOfLastWeek)) &&
                          e.date.isBefore(startOfWeek),
                    )
                    .fold(0.0, (sum, e) => sum + e.amount);

                double weeklyPercentage = 0.0;
                if (lastWeekExpenses > 0) {
                  weeklyPercentage =
                      ((weeklyExpenses - lastWeekExpenses) / lastWeekExpenses) *
                      100;
                } else if (weeklyExpenses > 0) {
                  weeklyPercentage = 100.0;
                }

                final monthlyExpenses = expenses
                    .where(
                      (e) =>
                          e.date.month == now.month && e.date.year == now.year,
                    )
                    .fold(0.0, (sum, e) => sum + e.amount);

                final lastMonth = now.month == 1 ? 12 : now.month - 1;
                final lastMonthYear = now.month == 1 ? now.year - 1 : now.year;
                final lastMonthExpenses = expenses
                    .where(
                      (e) =>
                          e.date.month == lastMonth &&
                          e.date.year == lastMonthYear,
                    )
                    .fold(0.0, (sum, e) => sum + e.amount);

                double monthlyPercentage = 0.0;
                if (lastMonthExpenses > 0) {
                  monthlyPercentage =
                      ((monthlyExpenses - lastMonthExpenses) /
                          lastMonthExpenses) *
                      100;
                } else if (monthlyExpenses > 0) {
                  monthlyPercentage = 100.0;
                }

                // Current Balance calculations
                final normalExpenses = expenses
                    .where((e) => !e.isFromSavings)
                    .fold(0.0, (sum, e) => sum + e.amount);
                final currentBalance =
                    savingsState.initialBalance - normalExpenses;

                final savingsExpenses = expenses
                    .where((e) => e.isFromSavings)
                    .fold(0.0, (sum, e) => sum + e.amount);

                final Map<String, double> historicalSavingsMap =
                    Map<String, double>.from(
                      DatabaseService.savingsBox.get('historicalSavings') ?? {},
                    );
                final rawTotalSavings = historicalSavingsMap.values.fold(
                  0.0,
                  (sum, val) => sum + val,
                );
                final totalSavings = rawTotalSavings - savingsExpenses;

                final cycleResetInitialBalance =
                    DatabaseService.savingsBox.get(
                          'cycleResetInitialBalance',
                          defaultValue: 0.0,
                        )
                        as double;
                final cycleResetNormalExpenses =
                    DatabaseService.savingsBox.get(
                          'cycleResetNormalExpenses',
                          defaultValue: 0.0,
                        )
                        as double;

                final incomeAddedSinceReset =
                    savingsState.initialBalance - cycleResetInitialBalance;
                final expensesSinceReset =
                    normalExpenses - cycleResetNormalExpenses;

                double percentageChange = 0.0;
                if (incomeAddedSinceReset > 0) {
                  percentageChange =
                      -(expensesSinceReset / incomeAddedSinceReset) * 100;
                } else if (expensesSinceReset > 0) {
                  percentageChange = -100.0;
                }

                final isZeroChange = percentageChange == 0.0;
                final isPositiveChange = percentageChange > 0;
                final changeColor = isZeroChange
                    ? Colors.grey
                    : isPositiveChange
                    ? const Color(0xFF00E676)
                    : Colors.redAccent;
                final changeSign = isZeroChange
                    ? ''
                    : (isPositiveChange ? '+' : '');

                // Category mapping for Donut Chart
                final categoryMap = <String, double>{};
                for (final e in expenses) {
                  String catId = e.categoryId;
                  if (!DatabaseService.defaultCategoryIds.contains(catId)) {
                    catId = 'others';
                  }
                  categoryMap[catId] = (categoryMap[catId] ?? 0.0) + e.amount;
                }

                return SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Total Balance Section
                        const SizedBox(height: 10),
                        GestureDetector(
                          onTap: () => _showInitialBalanceDialog(
                            context,
                            savingsState.initialBalance,
                            currentBalance,
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  const Text(
                                    'Total Balance',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(
                                    Icons.edit,
                                    size: 16,
                                    color: Colors.grey,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        GestureDetector(
                          onTap: () =>
                              _showTotalBalanceTrendDialog(context, expenses),
                          child: Row(
                            children: [
                              Text(
                                NumberFormat.currency(
                                  symbol: '₹',
                                  decimalDigits: 0,
                                ).format(currentBalance),
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: changeColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '$changeSign${percentageChange.toStringAsFixed(1)}%',
                                  style: TextStyle(
                                    color: changeColor,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(
                              Icons.savings_outlined,
                              size: 16,
                              color: Color(0xFF00E676),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'Total Savings',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              NumberFormat.currency(
                                symbol: '₹',
                                decimalDigits: 0,
                              ).format(totalSavings),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF00E676),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Section A: Daily, Weekly, Monthly Stats
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                'Today\'s Expense',
                                todayExpenses,
                                todayPercentage,
                                onTap: () =>
                                    _showExpenseTrendDialog(context, expenses),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildStatCard(
                                'Weekly Expense',
                                weeklyExpenses,
                                weeklyPercentage,
                                onTap: () =>
                                    _showWeeklyTrendDialog(context, expenses),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildStatCard(
                          'Monthly Expense',
                          monthlyExpenses,
                          monthlyPercentage,
                          isFullWidth: true,
                          onTap: () =>
                              _showMonthlyTrendDialog(context, expenses),
                        ),
                        const SizedBox(height: 24),

                        // Section B: Quick Glance Custom Donut Chart & Savings side-by-side
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Left side: Pie/Donut Quick Glance Card
                            Expanded(
                              flex: 1,
                              child: DonutChartCard(
                                categories: categoryMap,
                                touchedCategoryId: _touchedChartCategoryId,
                                onCategoryTouched: (categoryId) {
                                  setState(() {
                                    _touchedChartCategoryId = categoryId;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Right side: Explicit Savings Section (Mockup Goal widget)
                            Expanded(
                              flex: 1,
                              child: _buildSavingsWidget(
                                context,
                                savingsState,
                                expenses,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Section D: Recent Transactions Header
                        GestureDetector(
                          onTap: () =>
                              MainNavigationScreen.navigateToTab(context, 2),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Recent Transactions',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      MainNavigationScreen.navigateToTab(
                                        context,
                                        2,
                                      ); // Go to History tab
                                    },
                                    child: const Text(
                                      'See All',
                                      style: TextStyle(
                                        color: Color(0xFF00E676),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              // Recent Transaction Items
                              if (expenses.isEmpty)
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 24.0),
                                  child: Center(
                                    child: Text(
                                      'No recent transactions.',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ),
                                )
                              else
                                ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: expenses.length > 3
                                      ? 3
                                      : expenses.length,
                                  itemBuilder: (context, index) {
                                    final expense = expenses[index];
                                    final category = DatabaseService.categoryBox
                                        .get(expense.categoryId);
                                    return _buildRecentTransactionTile(
                                      expense,
                                      category,
                                    );
                                  },
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    double amount,
    double percentageChange, {
    bool isFullWidth = false,
    VoidCallback? onTap,
  }) {
    final isZeroChange = percentageChange == 0.0;
    final isPositive = percentageChange > 0;
    // For expenses, an increase is bad (red), decrease is good (green)
    final changeColor = isZeroChange
        ? Colors.grey
        : isPositive
        ? Colors.redAccent
        : const Color(0xFF00E676);
    final changeSign = isZeroChange ? '' : (isPositive ? '+' : '');

    final cardContent = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF141416),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.03)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: AutoSizeText(
                  '- ${NumberFormat.currency(symbol: '₹', decimalDigits: 0).format(amount)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  minFontSize: 10,
                  overflowReplacement: Text(
                    '- ${NumberFormat.currency(symbol: '₹', decimalDigits: 0).format(amount)}',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: changeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '$changeSign${percentageChange.toStringAsFixed(1)}%',
                  style: TextStyle(
                    color: changeColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: cardContent);
    }
    return cardContent;
  }

  Widget _buildSavingsWidget(
    BuildContext context,
    SavingsState savingsState,
    List<Expense> expenses,
  ) {
    // Calculate saved amount based on 5th of the month
    final now = DateTime.now();
    DateTime mostRecent5th;
    if (now.day >= 5) {
      mostRecent5th = DateTime(now.year, now.month, 5);
    } else {
      final prevMonth = now.month == 1 ? 12 : now.month - 1;
      final prevYear = now.month == 1 ? now.year - 1 : now.year;
      mostRecent5th = DateTime(prevYear, prevMonth, 5);
    }

    final expensesBefore5th = expenses
        .where((e) => e.date.isBefore(mostRecent5th) && !e.isFromSavings)
        .fold(0.0, (sum, e) => sum + e.amount);

    final calculatedSavedAmount =
        savingsState.initialBalance - expensesBefore5th;

    // ignore: unused_local_variable
    final progress = savingsState.targetAmount > 0
        ? (calculatedSavedAmount / savingsState.targetAmount).clamp(0.0, 1.0)
        : 0.0;

    // Generate trend data for the last 6 months (savings at the 5th of each month)
    final List<double> trendData = [];
    for (int i = 5; i >= 0; i--) {
      // Dart DateTime automatically handles zero/negative months by rolling back the year
      final monthDate = DateTime(now.year, now.month - i, 5);
      final expensesBeforeMonth = expenses
          .where((e) => e.date.isBefore(monthDate))
          .fold(0.0, (sum, e) => sum + e.amount);
      trendData.add(savingsState.initialBalance - expensesBeforeMonth);
    }

    return GestureDetector(
      onTap: () => _showSavingsDialog(context, savingsState.targetAmount),
      child: Container(
        height: 180,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF141416),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.03)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Savings Goal',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
                Icon(
                  Icons.edit,
                  size: 16,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
              ],
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Target this month',
                        style: TextStyle(color: Colors.grey, fontSize: 11),
                      ),
                      const SizedBox(height: 4),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          NumberFormat.currency(
                            symbol: '₹',
                            decimalDigits: 0,
                          ).format(savingsState.targetAmount),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 60,
                      height: 40,
                      child: CustomPaint(painter: SparklinePainter(trendData)),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Savings',
                      style: TextStyle(color: Colors.grey, fontSize: 10),
                    ),
                  ],
                ),
              ],
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentTransactionTile(Expense expense, Category? category) {
    final iconData = category != null
        ? IconData(
            int.parse(category.iconCodePoint),
            fontFamily: 'MaterialIcons',
          )
        : Icons.receipt;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF141416),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF09090B),
          child: Icon(
            iconData,
            color:
                DatabaseService.categoryColors[expense.categoryId] ??
                Colors.white,
          ),
        ),
        title: Text(
          category?.name ?? 'Unknown',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          DateFormat.yMMMd().format(expense.date),
          style: const TextStyle(color: Colors.grey, fontSize: 12),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (expense.isFromSavings) ...[
              const Icon(
                Icons.savings_outlined,
                color: Color(0xFF00E676),
                size: 16,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              '-${NumberFormat.currency(symbol: '₹').format(expense.amount)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTotalBalanceTrendDialog(
    BuildContext context,
    List<Expense> expenses,
  ) {
    final now = DateTime.now();

    // Get the cycle reset date, default to the 5th of current or previous month
    final String? resetDateStr = DatabaseService.savingsBox.get(
      'cycleResetDate',
    );
    DateTime cycleStartDate;
    if (resetDateStr != null) {
      cycleStartDate = DateTime.parse(resetDateStr);
    } else {
      if (now.day >= 5) {
        cycleStartDate = DateTime(now.year, now.month, 5);
      } else {
        cycleStartDate = DateTime(
          now.month == 1 ? now.year - 1 : now.year,
          now.month == 1 ? 12 : now.month - 1,
          5,
        );
      }
    }

    final int daysSinceStart = now.difference(cycleStartDate).inDays;

    // Safety check if cycle is completely broken
    final int displayDays = daysSinceStart < 0 ? 0 : daysSinceStart;

    final List<double> dailyBalances = [];
    final List<String> dailyLabels = [];

    final savingsState = context.read<SavingsBloc>().state;
    final double initialBalance = savingsState.initialBalance;

    for (int i = 0; i <= displayDays; i++) {
      final targetDate = cycleStartDate.add(Duration(days: i));
      final endOfDay = DateTime(
        targetDate.year,
        targetDate.month,
        targetDate.day,
        23,
        59,
        59,
      );

      final expensesUpToDay = expenses
          .where((e) {
            return !e.isFromSavings &&
                e.date.isAfter(
                  cycleStartDate.subtract(const Duration(milliseconds: 1)),
                ) &&
                e.date.isBefore(endOfDay.add(const Duration(milliseconds: 1)));
          })
          .fold(0.0, (sum, e) => sum + e.amount);

      final balanceOnDay = initialBalance - expensesUpToDay;
      dailyBalances.add(balanceOnDay);
      dailyLabels.add(DateFormat('MMM d').format(targetDate));
    }

    showDialog(
      context: context,
      builder: (context) {
        int? activeIndex;

        return Dialog(
          backgroundColor: const Color(0xFF141416),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(
              color: Colors.white.withValues(alpha: 0.05),
              width: 1,
            ),
          ),
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 24,
          ),
          child: StatefulBuilder(
            builder: (context, dialogSetState) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        vertical: 24,
                        horizontal: 16,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF00E676).withValues(alpha: 0.15),
                            const Color(0xFF00B0FF).withValues(alpha: 0.02),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        border: Border(
                          bottom: BorderSide(
                            color: const Color(
                              0xFF00E676,
                            ).withValues(alpha: 0.1),
                            width: 1,
                          ),
                        ),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'Cycle Burn Down',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            activeIndex != null
                                ? '₹${dailyBalances[activeIndex!].toStringAsFixed(0)}'
                                : '₹${dailyBalances.last.toStringAsFixed(0)}',
                            style: const TextStyle(
                              color: Color(0xFF00E676),
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            activeIndex != null
                                ? dailyLabels[activeIndex!]
                                : 'Current Balance',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(
                            height: 200,
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                if (dailyBalances.isEmpty) {
                                  return const SizedBox();
                                }

                                return GestureDetector(
                                  onHorizontalDragDown: (details) {
                                    final maxIndex = dailyBalances.length - 1;
                                    if (maxIndex <= 0) return;
                                    final spacing =
                                        constraints.maxWidth / maxIndex;
                                    final index =
                                        (details.localPosition.dx / spacing)
                                            .round()
                                            .clamp(0, maxIndex);
                                    dialogSetState(() {
                                      activeIndex = index;
                                    });
                                  },
                                  onHorizontalDragStart: (details) {
                                    final maxIndex = dailyBalances.length - 1;
                                    if (maxIndex <= 0) return;
                                    final spacing =
                                        constraints.maxWidth / maxIndex;
                                    final index =
                                        (details.localPosition.dx / spacing)
                                            .round()
                                            .clamp(0, maxIndex);
                                    dialogSetState(() {
                                      activeIndex = index;
                                    });
                                  },
                                  onHorizontalDragUpdate: (details) {
                                    final maxIndex = dailyBalances.length - 1;
                                    if (maxIndex <= 0) return;
                                    final spacing =
                                        constraints.maxWidth / maxIndex;
                                    final index =
                                        (details.localPosition.dx / spacing)
                                            .round()
                                            .clamp(0, maxIndex);
                                    dialogSetState(() {
                                      activeIndex = index;
                                    });
                                  },
                                  onHorizontalDragEnd: (details) {
                                    dialogSetState(() {
                                      activeIndex = null;
                                    });
                                  },
                                  child: CustomPaint(
                                    painter: ExpenseChartPainter(
                                      dailyBalances,
                                      dailyLabels,
                                      activeIndex,
                                      showLabels: false,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () => Navigator.pop(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF00E676),
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Close',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _showExpenseTrendDialog(BuildContext context, List<Expense> expenses) {
    final now = DateTime.now();
    final List<double> weeklyAmounts = [];
    final List<String> weeklyLabels = [];
    final List<DateTime> dates = [];

    for (int i = 6; i >= 0; i--) {
      final date = DateTime(now.year, now.month, now.day - i);
      dates.add(date);

      final startOfDay = DateTime(date.year, date.month, date.day, 0, 0, 0);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      final daySum = expenses
          .where(
            (e) =>
                e.date.isAfter(
                  startOfDay.subtract(const Duration(milliseconds: 1)),
                ) &&
                e.date.isBefore(endOfDay.add(const Duration(milliseconds: 1))),
          )
          .fold(0.0, (sum, e) => sum + e.amount);

      weeklyAmounts.add(daySum);
      weeklyLabels.add(DateFormat('E').format(date));
    }

    final totalWeeklyExpenses = weeklyAmounts.fold(
      0.0,
      (sum, val) => sum + val,
    );
    final averageWeeklyExpenses = totalWeeklyExpenses / 7;

    showDialog(
      context: context,
      builder: (context) {
        int? activeIndex;

        return Dialog(
          backgroundColor: const Color(0xFF141416),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(
              color: Colors.white.withValues(alpha: 0.05),
              width: 1,
            ),
          ),
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 24,
          ),
          child: StatefulBuilder(
            builder: (context, dialogSetState) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        vertical: 24,
                        horizontal: 16,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF00E676).withValues(alpha: 0.15),
                            const Color(0xFF00B0FF).withValues(alpha: 0.02),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        border: Border(
                          bottom: BorderSide(
                            color: const Color(
                              0xFF00E676,
                            ).withValues(alpha: 0.1),
                            width: 1,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E1E22),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.05),
                              ),
                            ),
                            child: activeIndex != null
                                ? Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Spent on ${DateFormat('EEEE, MMM d').format(dates[activeIndex!])}:',
                                        style: TextStyle(
                                          color: Colors.white.withValues(
                                            alpha: 0.5,
                                          ),
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        NumberFormat.currency(
                                          symbol: '₹',
                                          decimalDigits: 0,
                                        ).format(weeklyAmounts[activeIndex!]),
                                        style: const TextStyle(
                                          color: Color(0xFF00E676),
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  )
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Average Daily Spent:',
                                        style: TextStyle(
                                          color: Colors.white.withValues(
                                            alpha: 0.5,
                                          ),
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        NumberFormat.currency(
                                          symbol: '₹',
                                          decimalDigits: 0,
                                        ).format(averageWeeklyExpenses),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            height: 180,
                            width: double.infinity,
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                return GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onLongPressStart: (details) {
                                    final maxIndex = weeklyAmounts.length - 1;
                                    final spacing =
                                        constraints.maxWidth / maxIndex;
                                    final index =
                                        (details.localPosition.dx / spacing)
                                            .round()
                                            .clamp(0, maxIndex);
                                    dialogSetState(() {
                                      activeIndex = index;
                                    });
                                  },
                                  onLongPressMoveUpdate: (details) {
                                    final maxIndex = weeklyAmounts.length - 1;
                                    final spacing =
                                        constraints.maxWidth / maxIndex;
                                    final index =
                                        (details.localPosition.dx / spacing)
                                            .round()
                                            .clamp(0, maxIndex);
                                    dialogSetState(() {
                                      activeIndex = index;
                                    });
                                  },
                                  onLongPressEnd: (details) {
                                    dialogSetState(() {
                                      activeIndex = null;
                                    });
                                  },
                                  onHorizontalDragStart: (details) {
                                    final maxIndex = weeklyAmounts.length - 1;
                                    final spacing =
                                        constraints.maxWidth / maxIndex;
                                    final index =
                                        (details.localPosition.dx / spacing)
                                            .round()
                                            .clamp(0, maxIndex);
                                    dialogSetState(() {
                                      activeIndex = index;
                                    });
                                  },
                                  onHorizontalDragUpdate: (details) {
                                    final maxIndex = weeklyAmounts.length - 1;
                                    final spacing =
                                        constraints.maxWidth / maxIndex;
                                    final index =
                                        (details.localPosition.dx / spacing)
                                            .round()
                                            .clamp(0, maxIndex);
                                    dialogSetState(() {
                                      activeIndex = index;
                                    });
                                  },
                                  onHorizontalDragEnd: (details) {
                                    dialogSetState(() {
                                      activeIndex = null;
                                    });
                                  },
                                  child: CustomPaint(
                                    painter: ExpenseChartPainter(
                                      weeklyAmounts,
                                      weeklyLabels,
                                      activeIndex,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () => Navigator.pop(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF00E676),
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Close',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _showWeeklyTrendDialog(BuildContext context, List<Expense> expenses) {
    final now = DateTime.now();
    final List<double> weeklyAmounts = [];
    final List<String> weeklyLabels = [];
    final List<DateTime> dates = [];

    for (int i = 7; i >= 0; i--) {
      final endDate = now.subtract(Duration(days: i * 7));
      final startDate = endDate.subtract(const Duration(days: 6));
      dates.add(startDate);

      final startOfDay = DateTime(
        startDate.year,
        startDate.month,
        startDate.day,
        0,
        0,
        0,
      );
      final endOfDay = DateTime(
        endDate.year,
        endDate.month,
        endDate.day,
        23,
        59,
        59,
      );

      final weekSum = expenses
          .where(
            (e) =>
                e.date.isAfter(
                  startOfDay.subtract(const Duration(milliseconds: 1)),
                ) &&
                e.date.isBefore(endOfDay.add(const Duration(milliseconds: 1))),
          )
          .fold(0.0, (sum, e) => sum + e.amount);

      weeklyAmounts.add(weekSum);
      weeklyLabels.add('${startDate.day}/${startDate.month}');
    }

    final totalWeeklyExpenses = weeklyAmounts.fold(
      0.0,
      (sum, val) => sum + val,
    );
    final averageWeeklyExpenses = totalWeeklyExpenses / 8;

    showDialog(
      context: context,
      builder: (context) {
        int? activeIndex;

        return Dialog(
          backgroundColor: const Color(0xFF141416),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(
              color: Colors.white.withValues(alpha: 0.05),
              width: 1,
            ),
          ),
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 24,
          ),
          child: StatefulBuilder(
            builder: (context, dialogSetState) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        vertical: 24,
                        horizontal: 16,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF00E676).withValues(alpha: 0.15),
                            const Color(0xFF00B0FF).withValues(alpha: 0.02),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        border: Border(
                          bottom: BorderSide(
                            color: const Color(
                              0xFF00E676,
                            ).withValues(alpha: 0.1),
                            width: 1,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E1E22),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.05),
                              ),
                            ),
                            child: activeIndex != null
                                ? Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Week of ${DateFormat('MMM d').format(dates[activeIndex!])}:',
                                        style: TextStyle(
                                          color: Colors.white.withValues(
                                            alpha: 0.5,
                                          ),
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        NumberFormat.currency(
                                          symbol: '₹',
                                          decimalDigits: 0,
                                        ).format(weeklyAmounts[activeIndex!]),
                                        style: const TextStyle(
                                          color: Color(0xFF00E676),
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  )
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Average Weekly Spent:',
                                        style: TextStyle(
                                          color: Colors.white.withValues(
                                            alpha: 0.5,
                                          ),
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        NumberFormat.currency(
                                          symbol: '₹',
                                          decimalDigits: 0,
                                        ).format(averageWeeklyExpenses),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            height: 180,
                            width: double.infinity,
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                return GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onLongPressStart: (details) {
                                    final maxIndex = weeklyAmounts.length - 1;
                                    final spacing =
                                        constraints.maxWidth / maxIndex;
                                    final index =
                                        (details.localPosition.dx / spacing)
                                            .round()
                                            .clamp(0, maxIndex);
                                    dialogSetState(() {
                                      activeIndex = index;
                                    });
                                  },
                                  onLongPressMoveUpdate: (details) {
                                    final maxIndex = weeklyAmounts.length - 1;
                                    final spacing =
                                        constraints.maxWidth / maxIndex;
                                    final index =
                                        (details.localPosition.dx / spacing)
                                            .round()
                                            .clamp(0, maxIndex);
                                    dialogSetState(() {
                                      activeIndex = index;
                                    });
                                  },
                                  onLongPressEnd: (details) {
                                    dialogSetState(() {
                                      activeIndex = null;
                                    });
                                  },
                                  onHorizontalDragStart: (details) {
                                    final maxIndex = weeklyAmounts.length - 1;
                                    final spacing =
                                        constraints.maxWidth / maxIndex;
                                    final index =
                                        (details.localPosition.dx / spacing)
                                            .round()
                                            .clamp(0, maxIndex);
                                    dialogSetState(() {
                                      activeIndex = index;
                                    });
                                  },
                                  onHorizontalDragUpdate: (details) {
                                    final maxIndex = weeklyAmounts.length - 1;
                                    final spacing =
                                        constraints.maxWidth / maxIndex;
                                    final index =
                                        (details.localPosition.dx / spacing)
                                            .round()
                                            .clamp(0, maxIndex);
                                    dialogSetState(() {
                                      activeIndex = index;
                                    });
                                  },
                                  onHorizontalDragEnd: (details) {
                                    dialogSetState(() {
                                      activeIndex = null;
                                    });
                                  },
                                  child: CustomPaint(
                                    painter: ExpenseChartPainter(
                                      weeklyAmounts,
                                      weeklyLabels,
                                      activeIndex,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () => Navigator.pop(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF00E676),
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Close',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _showMonthlyTrendDialog(BuildContext context, List<Expense> expenses) {
    final now = DateTime.now();
    final List<double> monthlyAmounts = [];
    final List<String> monthlyLabels = [];
    final List<DateTime> dates = [];

    for (int i = 11; i >= 0; i--) {
      final targetDate = DateTime(now.year, now.month - i, 1);
      final startOfMonth = DateTime(
        targetDate.year,
        targetDate.month,
        1,
        0,
        0,
        0,
      );

      // End of month is the day before the 1st of the next month
      final endOfMonth = DateTime(
        targetDate.year,
        targetDate.month + 1,
        1,
        0,
        0,
        0,
      ).subtract(const Duration(milliseconds: 1));

      dates.add(startOfMonth);

      final monthSum = expenses
          .where(
            (e) =>
                e.date.isAfter(
                  startOfMonth.subtract(const Duration(milliseconds: 1)),
                ) &&
                e.date.isBefore(
                  endOfMonth.add(const Duration(milliseconds: 1)),
                ),
          )
          .fold(0.0, (sum, e) => sum + e.amount);

      monthlyAmounts.add(monthSum);
      monthlyLabels.add(DateFormat('MMM').format(startOfMonth));
    }

    final totalMonthlyExpenses = monthlyAmounts.fold(
      0.0,
      (sum, val) => sum + val,
    );
    final averageMonthlyExpenses = totalMonthlyExpenses / 12;

    showDialog(
      context: context,
      builder: (context) {
        int? activeIndex;

        return Dialog(
          backgroundColor: const Color(0xFF141416),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(
              color: Colors.white.withValues(alpha: 0.05),
              width: 1,
            ),
          ),
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 24,
          ),
          child: StatefulBuilder(
            builder: (context, dialogSetState) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        vertical: 24,
                        horizontal: 16,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF00E676).withValues(alpha: 0.15),
                            const Color(0xFF00B0FF).withValues(alpha: 0.02),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        border: Border(
                          bottom: BorderSide(
                            color: const Color(
                              0xFF00E676,
                            ).withValues(alpha: 0.1),
                            width: 1,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E1E22),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.05),
                              ),
                            ),
                            child: activeIndex != null
                                ? Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Spent in ${DateFormat('MMMM yyyy').format(dates[activeIndex!])}:',
                                        style: TextStyle(
                                          color: Colors.white.withValues(
                                            alpha: 0.5,
                                          ),
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        NumberFormat.currency(
                                          symbol: '₹',
                                          decimalDigits: 0,
                                        ).format(monthlyAmounts[activeIndex!]),
                                        style: const TextStyle(
                                          color: Color(0xFF00E676),
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  )
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Average Monthly Spent:',
                                        style: TextStyle(
                                          color: Colors.white.withValues(
                                            alpha: 0.5,
                                          ),
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        NumberFormat.currency(
                                          symbol: '₹',
                                          decimalDigits: 0,
                                        ).format(averageMonthlyExpenses),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            height: 180,
                            width: double.infinity,
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                return GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onLongPressStart: (details) {
                                    final maxIndex = monthlyAmounts.length - 1;
                                    final spacing =
                                        constraints.maxWidth / maxIndex;
                                    final index =
                                        (details.localPosition.dx / spacing)
                                            .round()
                                            .clamp(0, maxIndex);
                                    dialogSetState(() {
                                      activeIndex = index;
                                    });
                                  },
                                  onLongPressMoveUpdate: (details) {
                                    final maxIndex = monthlyAmounts.length - 1;
                                    final spacing =
                                        constraints.maxWidth / maxIndex;
                                    final index =
                                        (details.localPosition.dx / spacing)
                                            .round()
                                            .clamp(0, maxIndex);
                                    dialogSetState(() {
                                      activeIndex = index;
                                    });
                                  },
                                  onLongPressEnd: (details) {
                                    dialogSetState(() {
                                      activeIndex = null;
                                    });
                                  },
                                  onHorizontalDragStart: (details) {
                                    final maxIndex = monthlyAmounts.length - 1;
                                    final spacing =
                                        constraints.maxWidth / maxIndex;
                                    final index =
                                        (details.localPosition.dx / spacing)
                                            .round()
                                            .clamp(0, maxIndex);
                                    dialogSetState(() {
                                      activeIndex = index;
                                    });
                                  },
                                  onHorizontalDragUpdate: (details) {
                                    final maxIndex = monthlyAmounts.length - 1;
                                    final spacing =
                                        constraints.maxWidth / maxIndex;
                                    final index =
                                        (details.localPosition.dx / spacing)
                                            .round()
                                            .clamp(0, maxIndex);
                                    dialogSetState(() {
                                      activeIndex = index;
                                    });
                                  },
                                  onHorizontalDragEnd: (details) {
                                    dialogSetState(() {
                                      activeIndex = null;
                                    });
                                  },
                                  child: CustomPaint(
                                    painter: ExpenseChartPainter(
                                      monthlyAmounts,
                                      monthlyLabels,
                                      activeIndex,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () => Navigator.pop(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF00E676),
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Close',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _checkAndShowSalaryPopup(BuildContext context, List<Expense> expenses) {
    final now = DateTime.now();
    if (now.day < 5) return; // Only from 5th onwards

    final cycleStartMonth = now.month == 1 ? 12 : now.month - 1;
    final cycleStartYear = now.month == 1 ? now.year - 1 : now.year;
    final completedMonthKey =
        "$cycleStartYear-${cycleStartMonth.toString().padLeft(2, '0')}";

    final salaryCreditedMonth = DatabaseService.savingsBox.get(
      'salaryCreditedMonth',
    );
    if (salaryCreditedMonth == completedMonthKey) return; // Already answered

    if (_isShowingSalaryPopup) return;
    _isShowingSalaryPopup = true;

    showDialog(
      context: context,
      barrierDismissible: false, // Force them to answer
      builder: (context) {
        return Dialog(
          backgroundColor: const Color(0xFF141416),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(
              color: Colors.white.withValues(alpha: 0.05),
              width: 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 24,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF00E676).withValues(alpha: 0.15),
                        const Color(0xFF00B0FF).withValues(alpha: 0.02),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border(
                      bottom: BorderSide(
                        color: const Color(0xFF00E676).withValues(alpha: 0.1),
                        width: 1,
                      ),
                    ),
                  ),
                  child: const Column(
                    children: [
                      Icon(
                        Icons.account_balance_wallet,
                        color: Color(0xFF00E676),
                        size: 48,
                      ),
                      SizedBox(height: 12),
                      Text(
                        'New Month Cycle! 🎉',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const Text(
                        'Has your salary been credited for this month?',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'If yes, your remaining balance from last month will be safely archived into Savings, and your Total Balance will reset.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 32),
                      Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: () {
                                _isShowingSalaryPopup = false;
                                Navigator.pop(context);
                              },
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Not Yet',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                _isShowingSalaryPopup = false;
                                DatabaseService.savingsBox.put(
                                  'salaryCreditedMonth',
                                  completedMonthKey,
                                );

                                final currentExpenses = context
                                    .read<ExpenseBloc>()
                                    .state
                                    .expenses;
                                final normalExpenses = currentExpenses
                                    .where((e) => !e.isFromSavings)
                                    .fold(0.0, (sum, e) => sum + e.amount);

                                final currentBalance =
                                    context
                                        .read<SavingsBloc>()
                                        .state
                                        .initialBalance -
                                    normalExpenses;

                                context.read<SavingsBloc>().add(
                                  ArchiveCycle(
                                    currentBalance,
                                    completedMonthKey,
                                  ),
                                );
                                context.read<SavingsBloc>().add(
                                  UpdateInitialBalance(normalExpenses),
                                );

                                DatabaseService.savingsBox.put(
                                  'cycleResetNormalExpenses',
                                  normalExpenses,
                                );
                                DatabaseService.savingsBox.put(
                                  'cycleResetInitialBalance',
                                  normalExpenses,
                                );

                                Navigator.pop(context);

                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Balance reset to 0! You can now add your new salary.',
                                    ),
                                    backgroundColor: Color(0xFF00E676),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF00E676),
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Yes, Credited!',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// Custom Painter for Sparkline Trend Chart
class SparklinePainter extends CustomPainter {
  final List<double> data;
  final Color lineColor;

  SparklinePainter(this.data, {this.lineColor = const Color(0xFF00E676)});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final minData = data.reduce(min);
    final maxData = data.reduce(max);
    final range = maxData - minData == 0 ? 1 : maxData - minData;

    final path = Path();
    final widthStep = size.width / (data.length > 1 ? data.length - 1 : 1);

    for (int i = 0; i < data.length; i++) {
      final x = i * widthStep;
      // Invert Y axis so higher values are at the top
      final normalizedY = (data[i] - minData) / range;
      final y = size.height - (normalizedY * size.height);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);

    // Optional: draw a gradient fill below the line
    final fillPath = Path.from(path);
    fillPath.lineTo(size.width, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = ui.Gradient.linear(
        const Offset(0, 0),
        Offset(0, size.height),
        [lineColor.withValues(alpha: 0.3), lineColor.withValues(alpha: 0.0)],
      )
      ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, fillPaint);
  }

  @override
  bool shouldRepaint(covariant SparklinePainter oldDelegate) {
    return true;
  }
}

// Custom Painter for Donut Chart
class DonutChartPainter extends CustomPainter {
  final Map<String, double> categories;
  final String? touchedCategoryId;

  DonutChartPainter(this.categories, {this.touchedCategoryId});

  final Map<String, Color> categoryColors = {
    'rent': const Color(0xFF2563EB),
    'petrol': const Color(0xFFF97316),
    'bakery': const Color(0xFFD97706),
    'food': const Color(0xFFEF4444),
    'grocery': const Color(0xFF22C55E),
    'shopping': const Color(0xFFA855F7),
    'egg': const Color(0xFFEAB308),
    'travel': const Color(0xFF14B8A6),
    'allowance': const Color(0xFF10B981),
    'entertainment': const Color(0xFFEC4899),
    'lent': const Color(0xFF6B7280),
    'misc': const Color(0xFF94A3B8),
    'others': const Color(0xFF06B6D4),
  };

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width / 2.2, size.height / 2.2);

    final double total = categories.values.fold(0.0, (sum, val) => sum + val);
    if (total == 0) return;

    double startAngle = -pi / 2;

    categories.forEach((catId, amount) {
      final sweepAngle = (amount / total) * 2 * pi;
      final isTouched = catId == touchedCategoryId;

      final paint = Paint()
        ..color = categoryColors[catId] ?? Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = isTouched ? 32 : 24;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );

      // Draw percentage text
      final percentage = (amount / total) * 100;
      if (percentage >= 5) {
        // Only draw if large enough
        final angle = startAngle + (sweepAngle / 2);
        final textRadius = radius;
        final offset = Offset(
          center.dx + textRadius * cos(angle),
          center.dy + textRadius * sin(angle),
        );

        final textSpan = TextSpan(
          text: '${percentage.toStringAsFixed(0)}%',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        );
        final textPainter = TextPainter(
          text: textSpan,
          textDirection: ui.TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          offset - Offset(textPainter.width / 2, textPainter.height / 2),
        );
      }

      startAngle += sweepAngle;
    });

    // Outer thin boundary
    final outlinePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(center, radius + 15, outlinePaint);
  }

  @override
  bool shouldRepaint(covariant DonutChartPainter oldDelegate) {
    return oldDelegate.categories != categories ||
        oldDelegate.touchedCategoryId != touchedCategoryId;
  }
}

class DonutChartCard extends StatelessWidget {
  final Map<String, double> categories;
  final String? touchedCategoryId;
  final ValueChanged<String?> onCategoryTouched;

  const DonutChartCard({
    super.key,
    required this.categories,
    required this.touchedCategoryId,
    required this.onCategoryTouched,
  });

  void _handleTap(TapUpDetails details, Size size) {
    final double total = categories.values.fold(0.0, (sum, val) => sum + val);
    if (total == 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final dx = details.localPosition.dx - center.dx;
    final dy = details.localPosition.dy - center.dy;
    final distance = sqrt(dx * dx + dy * dy);

    final radius = min(size.width / 2.2, size.height / 2.2);
    final strokeWidth = 24.0;

    // Check if tap is within donut ring thickness roughly
    if (distance < radius - strokeWidth || distance > radius + strokeWidth) {
      onCategoryTouched(null);
      return;
    }

    double angle = atan2(dy, dx);
    double touchAngle = (angle + pi / 2) % (2 * pi);
    if (touchAngle < 0) touchAngle += 2 * pi;

    double currentAngle = 0;
    for (var entry in categories.entries) {
      final sweepAngle = (entry.value / total) * 2 * pi;
      if (touchAngle >= currentAngle &&
          touchAngle <= currentAngle + sweepAngle) {
        onCategoryTouched(entry.key);
        return;
      }
      currentAngle += sweepAngle;
    }

    onCategoryTouched(null);
  }

  @override
  Widget build(BuildContext context) {
    final double total = categories.values.fold(0.0, (sum, val) => sum + val);

    return Container(
      height: 180,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF141416),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.03)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Spending Glance',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: total == 0
                ? const Center(
                    child: Text(
                      'No Data',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  )
                : LayoutBuilder(
                    builder: (context, constraints) {
                      final size = Size(
                        constraints.maxWidth,
                        constraints.maxHeight,
                      );
                      final radius = min(size.width / 2.2, size.height / 2.2);

                      return Stack(
                        children: [
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTapUp: (details) => _handleTap(details, size),
                            child: CustomPaint(
                              size: size,
                              painter: DonutChartPainter(
                                categories,
                                touchedCategoryId: touchedCategoryId,
                              ),
                            ),
                          ),
                          if (touchedCategoryId != null)
                            Center(
                              child: SizedBox(
                                width: (radius - 24) * 2.2, //
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    AutoSizeText(
                                      touchedCategoryId == 'others'
                                          ? 'Others'
                                          : (DatabaseService.categoryBox
                                                    .get(touchedCategoryId)
                                                    ?.name ??
                                                'Unknown'),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                      maxLines: 1,
                                      minFontSize: 6,
                                      textAlign: TextAlign.center,
                                    ),
                                    AutoSizeText(
                                      '₹${categories[touchedCategoryId]?.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 10,
                                      ),
                                      maxLines: 1,
                                      minFontSize: 6,
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class ExpenseChartPainter extends CustomPainter {
  final List<double> values;
  final List<String> labels;
  final int? activeIndex;
  final bool showLabels;

  ExpenseChartPainter(
    this.values,
    this.labels,
    this.activeIndex, {
    this.showLabels = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double maxVal = values.fold(0.0, (max, val) => val > max ? val : max);
    final double maxValue = maxVal > 0 ? maxVal : 100.0;

    final double width = size.width;
    final double height = size.height;

    final double topPadding = 16.0;
    final double bottomPadding = 24.0;
    final double graphHeight = height - topPadding - bottomPadding;

    final int pointCount = values.length;
    final double spacing = pointCount > 1 ? width / (pointCount - 1) : width;

    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..strokeWidth = 1.0;

    for (int i = 0; i <= 3; i++) {
      final double y = topPadding + (graphHeight / 3) * i;
      canvas.drawLine(Offset(0, y), Offset(width, y), gridPaint);
    }

    final List<Offset> points = [];
    for (int i = 0; i < pointCount; i++) {
      final double x = i * spacing;
      final double y =
          topPadding + graphHeight - (values[i] / maxValue) * graphHeight;
      points.add(Offset(x, y));
    }

    if (points.isNotEmpty) {
      final fillPath = Path()..moveTo(0, topPadding + graphHeight);

      for (int i = 0; i < points.length; i++) {
        fillPath.lineTo(points[i].dx, points[i].dy);
      }
      fillPath.lineTo(width, topPadding + graphHeight);
      fillPath.close();

      final fillGradient = LinearGradient(
        colors: [
          const Color(0xFF00E676).withValues(alpha: 0.12),
          const Color(0xFF00E676).withValues(alpha: 0.0),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      );

      final fillPaint = Paint()
        ..shader = fillGradient.createShader(
          Rect.fromLTWH(0, topPadding, width, graphHeight),
        )
        ..style = PaintingStyle.fill;

      canvas.drawPath(fillPath, fillPaint);
    }

    final linePaint = Paint()
      ..color = const Color(0xFF00E676)
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final linePath = Path();
    if (points.isNotEmpty) {
      linePath.moveTo(points[0].dx, points[0].dy);
      for (int i = 1; i < points.length; i++) {
        linePath.lineTo(points[i].dx, points[i].dy);
      }
      canvas.drawPath(linePath, linePaint);
    }

    final textPainter = TextPainter(
      textDirection: ui.TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    final textStyle = TextStyle(
      color: Colors.white.withValues(alpha: 0.4),
      fontSize: 10,
      fontWeight: FontWeight.w500,
    );

    if (showLabels) {
      for (int i = 0; i < pointCount; i++) {
        textPainter.text = TextSpan(
          text: labels[i],
          style: activeIndex == i
              ? textStyle.copyWith(
                  color: const Color(0xFF00E676),
                  fontWeight: FontWeight.bold,
                )
              : textStyle,
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(
            points[i].dx - textPainter.width / 2,
            height - bottomPadding + 8,
          ),
        );
      }
    }

    if (activeIndex != null && activeIndex! >= 0 && activeIndex! < pointCount) {
      final activePoint = points[activeIndex!];

      final guidePaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.15)
        ..strokeWidth = 1.0;

      double startY = topPadding;
      final double endY = topPadding + graphHeight;
      final double dashWidth = 4.0;
      final double dashSpace = 4.0;

      while (startY < endY) {
        canvas.drawLine(
          Offset(activePoint.dx, startY),
          Offset(activePoint.dx, startY + dashWidth),
          guidePaint,
        );
        startY += dashWidth + dashSpace;
      }

      final glowPaint = Paint()
        ..color = const Color(0xFF00E676).withValues(alpha: 0.25)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(activePoint, 12.0, glowPaint);

      final midGlowPaint = Paint()
        ..color = const Color(0xFF00E676).withValues(alpha: 0.5)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(activePoint, 7.0, midGlowPaint);

      final solidPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      canvas.drawCircle(activePoint, 4.0, solidPaint);
    }
  }

  @override
  bool shouldRepaint(covariant ExpenseChartPainter oldDelegate) {
    return oldDelegate.values != values ||
        oldDelegate.labels != labels ||
        oldDelegate.activeIndex != activeIndex;
  }
}
