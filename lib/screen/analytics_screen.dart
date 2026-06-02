import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../blocs/expense/expense_bloc.dart';
import '../models/expense_model.dart';
import '../services/database_service.dart';
import '../utils/constants.dart';
import 'home_screen.dart'; // To reuse ExpenseChartPainter
import '../widgets/no_data_animation.dart';

enum AnalyticsFilter { oneDay, sevenDays, oneMonth, custom }

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  AnalyticsFilter _selectedFilter = AnalyticsFilter.sevenDays;
  DateTime? _customStartDate;
  DateTime? _customEndDate;
  int? _activeIndex;

  List<Expense> _getFilteredExpenses(List<Expense> allExpenses) {
    final now = DateTime.now();
    DateTime startDate;
    DateTime endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);

    switch (_selectedFilter) {
      case AnalyticsFilter.oneDay:
        startDate = DateTime(now.year, now.month, now.day, 0, 0, 0);
        break;
      case AnalyticsFilter.sevenDays:
        startDate = DateTime(now.year, now.month, now.day - 6, 0, 0, 0);
        break;
      case AnalyticsFilter.oneMonth:
        startDate = DateTime(now.year, now.month - 29, now.day, 0, 0, 0);
        if (_selectedFilter == AnalyticsFilter.oneMonth) {
          startDate = now.subtract(const Duration(days: 29));
          startDate = DateTime(
            startDate.year,
            startDate.month,
            startDate.day,
            0,
            0,
            0,
          );
        }
        break;
      case AnalyticsFilter.custom:
        startDate =
            _customStartDate ?? DateTime(now.year, now.month, now.day, 0, 0, 0);
        if (_customEndDate != null) {
          endDate = DateTime(
            _customEndDate!.year,
            _customEndDate!.month,
            _customEndDate!.day,
            23,
            59,
            59,
          );
        }
        break;
    }

    return allExpenses.where((e) {
      if (e.isFromSavings || e.isIncome) return false;
      return e.date.isAfter(
            startDate.subtract(const Duration(milliseconds: 1)),
          ) &&
          e.date.isBefore(endDate.add(const Duration(milliseconds: 1)));
    }).toList();
  }

  Future<void> _selectCustomDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _customStartDate != null && _customEndDate != null
          ? DateTimeRange(start: _customStartDate!, end: _customEndDate!)
          : null,
      builder: (context, child) {
        return Container(
          // Fakes the dialog barrier
          alignment: Alignment.center,
          color: Colors.black.withValues(alpha: 0.5),
          child: Material(
            color: const Color(0xFF141416), // Dark background for the popup
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
            ),
            clipBehavior: Clip.hardEdge,
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.9,
              height: 550, // Popup height
              child: Theme(
                data: Theme.of(context).copyWith(
                  scaffoldBackgroundColor: Colors.transparent,
                  appBarTheme: const AppBarTheme(
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                  ),
                  colorScheme: const ColorScheme.dark(
                    primary: Color(0xFF00E676),
                    onPrimary: Colors.black,
                    secondary: Color(
                      0xFF00E676,
                    ), // Overrides the default cyan/teal
                    onSecondary: Colors.black,
                    surface: Color(0xFF141416),
                    onSurface: Colors.white,
                    primaryContainer: Color(
                      0xFF004D27,
                    ), // Darker green container
                    onPrimaryContainer: Color(0xFF00E676),
                  ),
                  datePickerTheme: DatePickerThemeData(
                    rangeSelectionOverlayColor: WidgetStateProperty.all(
                      const Color(0xFF00E676).withValues(alpha: 0.15),
                    ),
                    rangePickerHeaderBackgroundColor: const Color(0xFF141416),
                  ),
                ),
                child: child!,
              ),
            ),
          ),
        );
      },
    );

    if (picked != null) {
      setState(() {
        _customStartDate = picked.start;
        _customEndDate = picked.end;
        _selectedFilter = AnalyticsFilter.custom;
        _activeIndex = null;
      });
    }
  }

  Widget _buildFilterChip(String label, AnalyticsFilter filter) {
    final isSelected = _selectedFilter == filter;

    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF00E676) : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected
              ? const Color(0xFF00E676)
              : Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.black : Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );

    if (filter == AnalyticsFilter.custom) {
      return GestureDetector(onTap: _selectCustomDateRange, child: chip);
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = filter;
          _activeIndex = null;
        });
      },
      child: chip,
    );
  }

  Widget _buildChart(List<Expense> filteredExpenses) {
    List<double> values = [];
    List<String> axisLabels = [];
    List<String> scrubLabels = [];
    final now = DateTime.now();

    if (_selectedFilter == AnalyticsFilter.oneDay) {
      final startOfDay = DateTime(now.year, now.month, now.day, 0, 0, 0);
      final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

      final todaysExpenses = filteredExpenses
          .where(
            (e) =>
                e.date.isAfter(
                  startOfDay.subtract(const Duration(milliseconds: 1)),
                ) &&
                e.date.isBefore(endOfDay.add(const Duration(milliseconds: 1))),
          )
          .toList();

      todaysExpenses.sort((a, b) => a.date.compareTo(b.date));

      if (todaysExpenses.isEmpty) {
        values.add(0.0);
        axisLabels.add('Today');
        scrubLabels.add('No entries');
      } else {
        for (var e in todaysExpenses) {
          values.add(e.amount);
          final timeStr = DateFormat('h:mm a').format(e.date);
          axisLabels.add(timeStr);
          scrubLabels.add(timeStr);
        }
      }
    } else if (_selectedFilter == AnalyticsFilter.sevenDays) {
      for (int i = 6; i >= 0; i--) {
        final day = now.subtract(Duration(days: i));
        final start = DateTime(day.year, day.month, day.day, 0, 0, 0);
        final end = DateTime(day.year, day.month, day.day, 23, 59, 59);
        final sum = filteredExpenses
            .where(
              (e) =>
                  e.date.isAfter(
                    start.subtract(const Duration(milliseconds: 1)),
                  ) &&
                  e.date.isBefore(end.add(const Duration(milliseconds: 1))),
            )
            .fold(0.0, (sum, e) => sum + e.amount);
        values.add(sum);

        final label = DateFormat('E').format(day);
        axisLabels.add(label);
        scrubLabels.add(label);
      }
    } else if (_selectedFilter == AnalyticsFilter.oneMonth) {
      for (int i = 29; i >= 0; i--) {
        final day = now.subtract(Duration(days: i));
        final start = DateTime(day.year, day.month, day.day, 0, 0, 0);
        final end = DateTime(day.year, day.month, day.day, 23, 59, 59);
        final sum = filteredExpenses
            .where(
              (e) =>
                  e.date.isAfter(
                    start.subtract(const Duration(milliseconds: 1)),
                  ) &&
                  e.date.isBefore(end.add(const Duration(milliseconds: 1))),
            )
            .fold(0.0, (sum, e) => sum + e.amount);
        values.add(sum);

        final label = DateFormat('d MMM').format(day);
        axisLabels.add(i % 6 == 0 ? label : '');
        scrubLabels.add(label);
      }
    } else if (_selectedFilter == AnalyticsFilter.custom) {
      if (_customStartDate == null || _customEndDate == null) {
        return const SizedBox();
      }
      final diff = _customEndDate!.difference(_customStartDate!).inDays;
      if (diff == 0) {
        final startOfDay = DateTime(
          _customStartDate!.year,
          _customStartDate!.month,
          _customStartDate!.day,
          0,
          0,
          0,
        );
        final endOfDay = DateTime(
          _customStartDate!.year,
          _customStartDate!.month,
          _customStartDate!.day,
          23,
          59,
          59,
        );

        final todaysExpenses = filteredExpenses
            .where(
              (e) =>
                  e.date.isAfter(
                    startOfDay.subtract(const Duration(milliseconds: 1)),
                  ) &&
                  e.date.isBefore(
                    endOfDay.add(const Duration(milliseconds: 1)),
                  ),
            )
            .toList();

        todaysExpenses.sort((a, b) => a.date.compareTo(b.date));

        if (todaysExpenses.isEmpty) {
          values.add(0.0);
          final dayStr = DateFormat('MMM d').format(_customStartDate!);
          axisLabels.add(dayStr);
          scrubLabels.add('No entries');
        } else {
          for (var e in todaysExpenses) {
            values.add(e.amount);
            final timeStr = DateFormat('h:mm a').format(e.date);
            axisLabels.add(timeStr);
            scrubLabels.add(timeStr);
          }
        }
      } else {
        for (int i = 0; i <= diff; i++) {
          final day = _customStartDate!.add(Duration(days: i));
          final start = DateTime(day.year, day.month, day.day, 0, 0, 0);
          final end = DateTime(day.year, day.month, day.day, 23, 59, 59);
          final sum = filteredExpenses
              .where(
                (e) =>
                    e.date.isAfter(
                      start.subtract(const Duration(milliseconds: 1)),
                    ) &&
                    e.date.isBefore(end.add(const Duration(milliseconds: 1))),
              )
              .fold(0.0, (sum, e) => sum + e.amount);
          values.add(sum);

          final label = DateFormat('d MMM').format(day);
          axisLabels.add((diff <= 7 || i % (diff ~/ 5) == 0) ? label : '');
          scrubLabels.add(label);
        }
      }
    }

    if (values.isEmpty) return const SizedBox();
    final double totalExpenses = values.fold(0.0, (sum, v) => sum + v);

    Color activeColor = const Color(0xFF00E676);
    if (values.isNotEmpty) {
      final double sum = values.reduce((a, b) => a + b);
      final double average = sum / values.length;
      final double currentVal = _activeIndex != null
          ? values[_activeIndex!]
          : values.last;

      if (currentVal < average * 0.5) {
        activeColor = const Color(0xFFFF8A80); // Light Red
      } else if (currentVal > average * 1.5) {
        activeColor = const Color(0xFFB71C1C); // Dark Red
      } else {
        activeColor = const Color(0xFFE53935); // Normal Red
      }
    }

    String displayAmount = '';
    String displayLabel = '';
    if (_activeIndex != null &&
        _activeIndex! >= 0 &&
        _activeIndex! < values.length) {
      displayAmount = '₹${values[_activeIndex!].toStringAsFixed(0)}';
      displayLabel = scrubLabels[_activeIndex!];
    } else {
      displayAmount = '₹${totalExpenses.toStringAsFixed(0)}';
      displayLabel = 'Total for Period';
    }

    return Column(
      children: [
        Text(
          displayAmount,
          style: TextStyle(
            color: activeColor,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          displayLabel.isEmpty ? 'Data Point' : displayLabel,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 180,
          width: double.infinity,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return GestureDetector(
                onHorizontalDragDown: (details) {
                  final maxIndex = values.length - 1;
                  if (maxIndex <= 0) return;
                  final spacing = constraints.maxWidth / maxIndex;
                  final index = (details.localPosition.dx / spacing)
                      .round()
                      .clamp(0, maxIndex);
                  setState(() => _activeIndex = index);
                },
                onHorizontalDragStart: (details) {
                  final maxIndex = values.length - 1;
                  if (maxIndex <= 0) return;
                  final spacing = constraints.maxWidth / maxIndex;
                  final index = (details.localPosition.dx / spacing)
                      .round()
                      .clamp(0, maxIndex);
                  setState(() => _activeIndex = index);
                },
                onHorizontalDragUpdate: (details) {
                  final maxIndex = values.length - 1;
                  if (maxIndex <= 0) return;
                  final spacing = constraints.maxWidth / maxIndex;
                  final index = (details.localPosition.dx / spacing)
                      .round()
                      .clamp(0, maxIndex);
                  setState(() => _activeIndex = index);
                },
                onHorizontalDragEnd: (details) =>
                    setState(() => _activeIndex = null),
                child: CustomPaint(
                  painter: ExpenseChartPainter(
                    values,
                    axisLabels,
                    _activeIndex,
                    showLabels: true,
                    isExpenseTrend: true,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  List<Widget> _buildCategoryList(List<Expense> expenses) {
    final Map<String, double> categorySums = {};
    for (final exp in expenses) {
      categorySums[exp.categoryId] =
          (categorySums[exp.categoryId] ?? 0.0) + exp.amount;
    }

    final double total = categorySums.values.fold(0.0, (sum, val) => sum + val);

    final sortedCategories = categorySums.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedCategories.map((entry) {
      final category = DatabaseService.categoryBox.get(entry.key);
      final double percentage = total > 0 ? (entry.value / total) * 100 : 0.0;
      final iconData = category != null
          ? IconData(
              int.parse(category.iconCodePoint),
              fontFamily: 'MaterialIcons',
            )
          : Icons.receipt;

      // Grab color from shared constants map
      final Color catColor =
          AppConstants.categoryColors[entry.key] ?? const Color(0xFF00E676);

      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF141416),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: catColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(iconData, color: catColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category?.name ?? 'Unknown',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: percentage / 100,
                      backgroundColor: Colors.white.withValues(alpha: 0.05),
                      valueColor: AlwaysStoppedAnimation<Color>(catColor),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '-${NumberFormat.currency(symbol: '₹').format(entry.value)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '${percentage.toStringAsFixed(1)}%',
                  style: const TextStyle(color: Colors.grey, fontSize: 11),
                ),
              ],
            ),
          ],
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text(
          'Analytics',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: BlocBuilder<ExpenseBloc, ExpenseState>(
          builder: (context, state) {
            if (state.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            final allExpenses = state.expenses;
            if (allExpenses.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 40.0,
                ),
                child: Container(
                  height: MediaQuery.of(context).size.height * 0.6,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF141416),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.05),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(height: 180, child: NoDataAnimation()),
                      const SizedBox(height: 24),
                      const Text(
                        'No transactions to analyze.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Add a transaction to kickstart your analytics.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            final filteredExpenses = _getFilteredExpenses(allExpenses);

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Trend Chart Container
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF141416),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.05),
                      ),
                    ),
                    child: _buildChart(filteredExpenses),
                  ),
                  const SizedBox(height: 24),

                  // Filter Row
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('1D', AnalyticsFilter.oneDay),
                        const SizedBox(width: 8),
                        _buildFilterChip('7D', AnalyticsFilter.sevenDays),
                        const SizedBox(width: 8),
                        _buildFilterChip('1M', AnalyticsFilter.oneMonth),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          _selectedFilter == AnalyticsFilter.custom &&
                                  _customStartDate != null &&
                                  _customEndDate != null
                              ? '${DateFormat('MMM d').format(_customStartDate!)} - ${DateFormat('MMM d').format(_customEndDate!)}'
                              : 'Custom',
                          AnalyticsFilter.custom,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                  // Category List
                  const Text(
                    'Category Breakdown',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  if (filteredExpenses.isEmpty)
                    Container(
                      height: 180,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF141416),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.05),
                        ),
                      ),
                      child: NoDataAnimation(),
                    )
                  else
                    ..._buildCategoryList(filteredExpenses),
                  const SizedBox(height: 40), // Bottom padding
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
