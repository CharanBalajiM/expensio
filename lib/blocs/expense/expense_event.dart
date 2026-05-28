part of 'expense_bloc.dart';

abstract class ExpenseEvent {}

class LoadExpenses extends ExpenseEvent {}

class AddExpenseEvent extends ExpenseEvent {
  final Expense expense;
  AddExpenseEvent(this.expense);
}

class DeleteExpenseEvent extends ExpenseEvent {
  final String id;
  DeleteExpenseEvent(this.id);
}
