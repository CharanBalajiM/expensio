import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/expense_model.dart';
import '../../services/database_service.dart';

part 'expense_event.dart';
part 'expense_state.dart';

class ExpenseBloc extends Bloc<ExpenseEvent, ExpenseState> {
  ExpenseBloc() : super(ExpenseState()) {
    on<LoadExpenses>(_onLoadExpenses);
    on<AddExpenseEvent>(_onAddExpense);
    on<DeleteExpenseEvent>(_onDeleteExpense);
  }

  Future<void> _onLoadExpenses(LoadExpenses event, Emitter<ExpenseState> emit) async {
    emit(state.copyWith(isLoading: true));
    try {
      final expensesList = DatabaseService.expenseBox.values.toList()
        ..sort((a, b) => b.date.compareTo(a.date));
      emit(state.copyWith(expenses: expensesList, isLoading: false));
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
    }
  }

  Future<void> _onAddExpense(AddExpenseEvent event, Emitter<ExpenseState> emit) async {
    try {
      await DatabaseService.addExpense(event.expense);
      add(LoadExpenses());
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  Future<void> _onDeleteExpense(DeleteExpenseEvent event, Emitter<ExpenseState> emit) async {
    try {
      await DatabaseService.deleteExpense(event.id);
      add(LoadExpenses());
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }
}
