import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../blocs/expense/expense_bloc.dart';
import '../models/expense_model.dart';
import '../services/database_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _searchQuery = '';
  String? _selectedCategoryId;

  @override
  Widget build(BuildContext context) {
    final categories = DatabaseService.categoryBox.values.toList();

    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: Column(
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

          // Category Chips Filter
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              itemCount: categories.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  final isSelected = _selectedCategoryId == null;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: ChoiceChip(
                      label: const Text('All'),
                      selected: isSelected,
                      selectedColor: const Color(0xFF00E676),
                      backgroundColor: const Color(0xFF141416),
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.black : Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      onSelected: (_) {
                        setState(() {
                          _selectedCategoryId = null;
                        });
                      },
                    ),
                  );
                }

                final category = categories[index - 1];
                final isSelected = _selectedCategoryId == category.id;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: ChoiceChip(
                    label: Text(category.name),
                    selected: isSelected,
                    selectedColor: const Color(0xFF00E676),
                    backgroundColor: const Color(0xFF141416),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.black : Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    onSelected: (_) {
                      setState(() {
                        _selectedCategoryId = category.id;
                      });
                    },
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),

          // Expense List
          Expanded(
            child: BlocBuilder<ExpenseBloc, ExpenseState>(
              builder: (context, state) {
                if (state.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                // Apply search and category filters
                var filtered = state.expenses;
                if (_selectedCategoryId != null) {
                  filtered = filtered
                      .where((e) => e.categoryId == _selectedCategoryId)
                      .toList();
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
                  final formattedDate = DateFormat.yMMMMd().format(exp.date);
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
                          final category = DatabaseService.categoryBox.get(
                            expense.categoryId,
                          );
                          final iconData = category != null
                              ? IconData(
                                  int.parse(category.iconCodePoint),
                                  fontFamily: 'MaterialIcons',
                                )
                              : Icons.receipt;

                          return Dismissible(
                            key: Key(expense.id),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20.0),
                              color: Colors.redAccent,
                              child: const Icon(
                                Icons.delete,
                                color: Colors.white,
                              ),
                            ),
                            onDismissed: (_) {
                              context.read<ExpenseBloc>().add(
                                DeleteExpenseEvent(expense.id),
                              );
                            },
                            child: Container(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 20.0,
                                vertical: 4.0,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF141416),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: const Color(0xFF09090B),
                                  child: Icon(
                                    iconData,
                                    color: DatabaseService.categoryColors[expense.categoryId] ?? Colors.white,
                                  ),
                                ),
                                title: Text(
                                  category?.name ?? 'Unknown',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: expense.note != null
                                    ? Text(
                                        expense.note!,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                        ),
                                      )
                                    : null,
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
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
