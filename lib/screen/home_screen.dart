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
  ) {
    _initialBalanceController.text = currentInitialBalance.toStringAsFixed(0);

    showDialog(
      context: context,
      builder: (context) {
        bool isAdding = true;
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E1E22),
              title: const Text('Set Total Balance'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _initialBalanceController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(labelText: 'Amount'),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            isAdding = !isAdding;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isAdding
                                ? const Color(0xFF00E676).withOpacity(0.15)
                                : Colors.redAccent.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            isAdding ? '+' : '-',
                            style: TextStyle(
                              color: isAdding
                                  ? const Color(0xFF00E676)
                                  : Colors.redAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      _buildQuickAddButton(200, isAdding),
                      _buildQuickAddButton(500, isAdding),
                      _buildQuickAddButton(1000, isAdding),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    final amount =
                        double.tryParse(_initialBalanceController.text) ?? 0.0;
                    context.read<SavingsBloc>().add(
                      UpdateInitialBalance(amount),
                    );
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'Save',
                    style: TextStyle(color: Color(0xFF00E676)),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildQuickAddButton(double amount, bool isAdding) {
    return GestureDetector(
      onTap: () {
        final currentAmount =
            double.tryParse(_initialBalanceController.text) ?? 0.0;
        final newAmount = isAdding
            ? currentAmount + amount
            : currentAmount - amount;
        _initialBalanceController.text = newAmount.toStringAsFixed(0);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isAdding
              ? const Color(0xFF00E676).withOpacity(0.15)
              : Colors.redAccent.withOpacity(0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          '${amount.toInt()}',
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

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E22),
          title: const Text('Update Savings Goal'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _goalController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Target Goal Amount',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () {
                final goal = double.tryParse(_goalController.text) ?? 1000.0;
                context.read<SavingsBloc>().add(UpdateTargetAmount(goal));
                Navigator.pop(context);
              },
              child: const Text(
                'Save',
                style: TextStyle(color: Color(0xFF00E676)),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expensio'),
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
                final totalExpenses = expenses.fold(
                  0.0,
                  (sum, e) => sum + e.amount,
                );
                final currentBalance =
                    savingsState.initialBalance - totalExpenses;

                final oneMonthAgo = DateTime(
                  now.year,
                  now.month - 1,
                  now.day,
                  now.hour,
                  now.minute,
                );
                final expensesBefore1Month = expenses
                    .where((e) => e.date.isBefore(oneMonthAgo))
                    .fold(0.0, (sum, e) => sum + e.amount);
                final balanceOneMonthAgo =
                    savingsState.initialBalance - expensesBefore1Month;

                double percentageChange = 0.0;
                if (balanceOneMonthAgo != 0) {
                  percentageChange =
                      ((currentBalance - balanceOneMonthAgo) /
                          balanceOneMonthAgo) *
                      100;
                } else if (currentBalance > 0) {
                  percentageChange = 100.0;
                }

                final isPositiveChange = percentageChange >= 0;
                final changeColor = isPositiveChange
                    ? const Color(0xFF00E676)
                    : Colors.redAccent;
                final changeSign = isPositiveChange ? '+' : '';

                // Category mapping for Donut Chart
                final categoryMap = <String, double>{};
                for (final e in expenses) {
                  categoryMap[e.categoryId] =
                      (categoryMap[e.categoryId] ?? 0.0) + e.amount;
                }

                return SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Total Balance Section
                        const SizedBox(height: 10),
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
                            GestureDetector(
                              onTap: () => _showInitialBalanceDialog(
                                context,
                                savingsState.initialBalance,
                              ),
                              child: const Icon(
                                Icons.edit,
                                size: 16,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              NumberFormat.currency(
                                symbol: '₹',
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
                                color: changeColor.withOpacity(0.15),
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
                        const SizedBox(height: 24),

                        // Section A: Daily, Weekly, Monthly Stats
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                'Today\'s Expense',
                                todayExpenses,
                                todayPercentage,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildStatCard(
                                'Weekly Expense',
                                weeklyExpenses,
                                weeklyPercentage,
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
  }) {
    final isPositive = percentageChange >= 0;
    // For expenses, an increase is bad (red), decrease is good (green)
    final changeColor = isPositive ? Colors.redAccent : const Color(0xFF00E676);
    final changeSign = isPositive ? '+' : '';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF141416),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.03)),
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
                  color: changeColor.withOpacity(0.15),
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
        .where((e) => e.date.isBefore(mostRecent5th))
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
          border: Border.all(color: Colors.white.withOpacity(0.03)),
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
                  color: Colors.white.withOpacity(0.5),
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
          child: Icon(iconData, color: Colors.white),
        ),
        title: Text(
          category?.name ?? 'Unknown',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          DateFormat.yMMMd().format(expense.date),
          style: const TextStyle(color: Colors.grey, fontSize: 12),
        ),
        trailing: Text(
          '-${NumberFormat.currency(symbol: '₹').format(expense.amount)}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
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

  final List<Color> colors = [
    const Color(0xFF00E676),
    Colors.blueAccent,
    Colors.deepPurpleAccent,
    Colors.orangeAccent,
    Colors.redAccent,
    Colors.yellowAccent,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width / 2.2, size.height / 2.2);

    final double total = categories.values.fold(0.0, (sum, val) => sum + val);
    if (total == 0) return;

    double startAngle = -pi / 2;

    int colorIndex = 0;
    categories.forEach((catId, amount) {
      final sweepAngle = (amount / total) * 2 * pi;
      final isTouched = catId == touchedCategoryId;

      final paint = Paint()
        ..color = colors[colorIndex % colors.length]
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
      colorIndex++;
    });

    // Outer thin boundary
    final outlinePaint = Paint()
      ..color = Colors.white.withOpacity(0.05)
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
        border: Border.all(color: Colors.white.withOpacity(0.03)),
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
                                      DatabaseService.categoryBox
                                              .get(touchedCategoryId)
                                              ?.name ??
                                          'Unknown',
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
