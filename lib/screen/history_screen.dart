import 'package:expensio/models/category_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../blocs/expense/expense_bloc.dart';
import '../blocs/savings/savings_bloc.dart';
import '../models/expense_model.dart';
import '../services/database_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

enum TransactionFilter { all, sent, received, category }

class _HistoryScreenState extends State<HistoryScreen> {
  String _searchQuery = '';
  TransactionFilter _currentFilter = TransactionFilter.all;
  String? _selectedCategoryId;

  @override
  Widget build(BuildContext context) {
    final categories = DatabaseService.categoryBox.values.toList();

    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 10.0,
              ),
              child: TextField(
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.toLowerCase();
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Search transactions...',
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  filled: true,
                  fillColor: const Color(0xFF141416),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),

            // Filter Bubbles
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  _buildFilterBubble('All', TransactionFilter.all),
                  const SizedBox(width: 8),
                  _buildFilterBubble('Sent', TransactionFilter.sent),
                  const SizedBox(width: 8),
                  _buildFilterBubble('Received', TransactionFilter.received),
                  const SizedBox(width: 8),
                  _buildCategoryDropdownBubble(categories),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Expense List
            Expanded(
              child: BlocBuilder<ExpenseBloc, ExpenseState>(
                builder: (context, state) {
                  return BlocBuilder<SavingsBloc, SavingsState>(
                    builder: (context, savingsState) {
                      if (state.isLoading || savingsState.isLoading) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      // Compute running normal and savings balances backwards (newest to oldest)
                      final Map<String, double> runningNormalBalances = {};
                      final Map<String, double> runningSavingsBalances = {};

                      // Calculate final normal balance today
                      final normalExpenses = state.expenses
                          .where((e) => !e.isFromSavings && !e.isIncome)
                          .fold(0.0, (sum, e) => sum + e.amount);

                      final totalIncome = state.expenses
                          .where((e) => e.isIncome)
                          .fold(0.0, (sum, e) => sum + e.amount);

                      double normalBalance =
                          savingsState.initialBalance +
                          totalIncome -
                          normalExpenses;

                      // Calculate final savings balance today
                      final savingsExpenses = state.expenses
                          .where((e) => e.isFromSavings)
                          .fold(0.0, (sum, e) => sum + e.amount);

                      final historicalSavingsMap = Map<String, double>.from(
                        DatabaseService.savingsBox.get('historicalSavings') ??
                            {},
                      );
                      final rawTotalSavings = historicalSavingsMap.values.fold(
                        0.0,
                        (sum, val) => sum + val,
                      );

                      double savingsBalance = rawTotalSavings - savingsExpenses;

                      // Iterate backwards to calculate running history for both balances
                      for (final exp in state.expenses) {
                        if (exp.isFromSavings) {
                          runningSavingsBalances[exp.id] = savingsBalance;
                          savingsBalance += exp.amount; // reverse subtraction
                        } else {
                          runningNormalBalances[exp.id] = normalBalance;
                          if (exp.isIncome) {
                            normalBalance -= exp.amount; // reverse addition
                          } else {
                            normalBalance += exp.amount; // reverse subtraction
                          }
                        }
                      }

                      // Apply search and category filters
                      var filtered = state.expenses;

                      switch (_currentFilter) {
                        case TransactionFilter.all:
                          break;
                        case TransactionFilter.sent:
                          filtered = filtered
                              .where((e) => !e.isIncome)
                              .toList();
                          break;
                        case TransactionFilter.received:
                          filtered = filtered.where((e) => e.isIncome).toList();
                          break;
                        case TransactionFilter.category:
                          if (_selectedCategoryId != null) {
                            filtered = filtered
                                .where(
                                  (e) => e.categoryId == _selectedCategoryId,
                                )
                                .toList();
                          }
                          break;
                      }

                      if (_searchQuery.isNotEmpty) {
                        filtered = filtered.where((e) {
                          final note = e.note?.toLowerCase() ?? '';
                          final catName =
                              DatabaseService.categoryBox
                                  .get(e.categoryId)
                                  ?.name
                                  .toLowerCase() ??
                              '';
                          return note.contains(_searchQuery) ||
                              catName.contains(_searchQuery);
                        }).toList();
                      }

                      if (filtered.isEmpty) {
                        return const Center(
                          child: Text(
                            'No matching transactions.',
                            style: TextStyle(color: Colors.grey),
                          ),
                        );
                      }

                      // Group by date
                      final Map<String, List<Expense>> grouped = {};
                      for (final exp in filtered) {
                        final formattedDate = DateFormat.yMMMMd().format(
                          exp.date,
                        );
                        if (grouped[formattedDate] == null) {
                          grouped[formattedDate] = [];
                        }
                        grouped[formattedDate]!.add(exp);
                      }

                      final datesList = grouped.keys.toList();

                      return ListView.builder(
                        itemCount: datesList.length,
                        itemBuilder: (context, dateIndex) {
                          final dateStr = datesList[dateIndex];
                          final dayExpenses = grouped[dateStr]!;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Date Header
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20.0,
                                  vertical: 10.0,
                                ),
                                child: Text(
                                  dateStr,
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),

                              // Expenses under this date
                              ...dayExpenses.map((expense) {
                                final category = DatabaseService.categoryBox
                                    .get(expense.categoryId);
                                final iconData = category != null
                                    ? IconData(
                                        int.parse(category.iconCodePoint),
                                        fontFamily: 'MaterialIcons',
                                      )
                                    : Icons.receipt;

                                return _SlidableTransactionTile(
                                  key: Key(expense.id),
                                  expense: expense,
                                  category: category,
                                  iconData: iconData,
                                  runningBalance: expense.isFromSavings
                                      ? (runningSavingsBalances[expense.id] ??
                                            savingsState.savedAmount)
                                      : (runningNormalBalances[expense.id] ??
                                            savingsState.initialBalance),
                                  onDelete: () {
                                    context.read<ExpenseBloc>().add(
                                      DeleteExpenseEvent(expense.id),
                                    );
                                  },
                                );
                              }),
                            ],
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterBubble(String text, TransactionFilter filterType) {
    final isSelected = _currentFilter == filterType;
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentFilter = filterType;
          if (filterType != TransactionFilter.category) {
            _selectedCategoryId = null;
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? const Color(0xFF00E676) : Colors.white,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryDropdownBubble(List<Category> categories) {
    final isSelected = _currentFilter == TransactionFilter.category;

    Category? selectedCategory;
    if (_selectedCategoryId != null) {
      try {
        selectedCategory = categories.firstWhere(
          (c) => c.id == _selectedCategoryId,
        );
      } catch (e) {
        selectedCategory = null;
      }
    }

    return PopupMenuButton<String>(
      onSelected: (String newValue) {
        setState(() {
          _currentFilter = TransactionFilter.category;
          _selectedCategoryId = newValue;
        });
      },
      color: const Color(0xFF1E1E22),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      position: PopupMenuPosition.under,
      itemBuilder: (BuildContext context) {
        return categories.map((Category category) {
          final iconData = IconData(
            int.parse(category.iconCodePoint),
            fontFamily: 'MaterialIcons',
          );
          return PopupMenuItem<String>(
            value: category.id,
            child: Row(
              children: [
                Icon(
                  iconData,
                  size: 16,
                  color:
                      DatabaseService.categoryColors[category.id] ??
                      Colors.white,
                ),
                const SizedBox(width: 8),
                Text(
                  category.name,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
              ],
            ),
          );
        }).toList();
      },
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 12),
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
            if (isSelected && selectedCategory != null) ...[
              Icon(
                IconData(
                  int.parse(selectedCategory.iconCodePoint),
                  fontFamily: 'MaterialIcons',
                ),
                size: 16,
                color:
                    DatabaseService.categoryColors[selectedCategory.id] ??
                    Colors.white,
              ),
              const SizedBox(width: 6),
              Text(
                selectedCategory.name,
                style: const TextStyle(
                  color: Color(0xFF00E676),
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ] else ...[
              const Text(
                'Category',
                style: TextStyle(color: Colors.white, fontSize: 13),
              ),
            ],
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down,
              color: isSelected ? const Color(0xFF00E676) : Colors.grey,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}

class _SlidableTransactionTile extends StatefulWidget {
  final Expense expense;
  final Category? category;
  final IconData iconData;
  final double runningBalance;
  final VoidCallback onDelete;

  const _SlidableTransactionTile({
    super.key,
    required this.expense,
    required this.category,
    required this.iconData,
    required this.runningBalance,
    required this.onDelete,
  });

  @override
  State<_SlidableTransactionTile> createState() =>
      _SlidableTransactionTileState();
}

class _SlidableTransactionTileState extends State<_SlidableTransactionTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _dragExtent = 0.0;
  final double _menuWidth = 140.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _controller.addListener(() {
      setState(() {
        _dragExtent = _controller.value * -_menuWidth;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _close() {
    _controller.animateTo(0.0, curve: Curves.easeOut);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 4.0),
      height: 72,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Background options (revealed when slid)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF09090B),
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.only(right: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Cancel / X button
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.05),
                      foregroundColor: Colors.grey,
                      elevation: 0,
                      minimumSize: const Size(44, 44),
                      maximumSize: const Size(44, 44),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.1),
                          width: 1,
                        ),
                      ),
                      padding: EdgeInsets.zero,
                    ),
                    onPressed: _close,
                    child: const Icon(Icons.close, size: 20),
                  ),
                  const SizedBox(width: 12),
                  // Delete button
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent.withValues(alpha: 0.15),
                      foregroundColor: Colors.redAccent,
                      elevation: 0,
                      minimumSize: const Size(44, 44),
                      maximumSize: const Size(44, 44),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: Colors.redAccent.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      padding: EdgeInsets.zero,
                    ),
                    onPressed: () {
                      _close();
                      widget.onDelete();
                    },
                    child: const Icon(Icons.delete, size: 20),
                  ),
                ],
              ),
            ),
          ),

          // Main ListTile (slides on top)
          GestureDetector(
            onHorizontalDragUpdate: (details) {
              setState(() {
                _dragExtent += details.primaryDelta!;
                if (_dragExtent > 0) {
                  _dragExtent = 0; // Don't allow sliding right
                }
                if (_dragExtent < -_menuWidth) {
                  _dragExtent = -_menuWidth; // Limit slide left
                }
              });
            },
            onHorizontalDragEnd: (details) {
              _controller.value = _dragExtent / -_menuWidth;
              if (_dragExtent < -_menuWidth / 2) {
                // Open menu
                _controller.animateTo(1.0, curve: Curves.easeOut);
              } else {
                // Close menu
                _controller.animateTo(0.0, curve: Curves.easeOut);
              }
            },
            child: Transform.translate(
              offset: Offset(_dragExtent, 0),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF141416),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.03),
                  ),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFF09090B),
                    child: Icon(
                      widget.iconData,
                      color: widget.expense.isIncome
                          ? const Color(0xFF00E676)
                          : (DatabaseService.categoryColors[widget
                                    .expense
                                    .categoryId] ??
                                Colors.white),
                    ),
                  ),
                  title: Text(
                    widget.category?.name ?? 'Unknown',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: widget.expense.note != null
                      ? Text(
                          widget.expense.note!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                          ),
                        )
                      : null,
                  trailing: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.expense.isFromSavings) ...[
                            const Icon(
                              Icons.savings_outlined,
                              color: Color(0xFF00E676),
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                          ],
                          Text(
                            widget.expense.isIncome
                                ? '+${NumberFormat.currency(symbol: '₹').format(widget.expense.amount)}'
                                : '-${NumberFormat.currency(symbol: '₹').format(widget.expense.amount)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: widget.expense.isIncome
                                  ? const Color(0xFF00E676)
                                  : Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        NumberFormat.currency(
                          symbol: '₹',
                        ).format(widget.runningBalance),
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
