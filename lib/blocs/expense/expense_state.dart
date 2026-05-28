part of 'expense_bloc.dart';

final class ExpenseState {
  final bool isLoading;
  final String? errorMessage;
  final List<Expense> expenses;

  ExpenseState({
    this.isLoading = false,
    this.errorMessage,
    this.expenses = const [],
  });

  ExpenseState copyWith({
    bool? isLoading,
    String? errorMessage,
    List<Expense>? expenses,
  }) {
    return ExpenseState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      expenses: expenses ?? this.expenses,
    );
  }
}
