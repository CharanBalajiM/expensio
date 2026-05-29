import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/database_service.dart';

part 'savings_event.dart';
part 'savings_state.dart';

class SavingsBloc extends Bloc<SavingsEvent, SavingsState> {
  SavingsBloc() : super(SavingsState()) {
    on<LoadSavings>(_onLoadSavings);
    on<UpdateTargetAmount>(_onUpdateTargetAmount);
    on<UpdateSavedAmount>(_onUpdateSavedAmount);
    on<UpdateInitialBalance>(_onUpdateInitialBalance);
    on<ArchiveCycle>(_onArchiveCycle);
  }

  Future<void> _onLoadSavings(
    LoadSavings event,
    Emitter<SavingsState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));
    try {
      final targetRaw = DatabaseService.savingsBox.get('targetAmount');
      final savedRaw = DatabaseService.savingsBox.get('savedAmount');
      final initialRaw = DatabaseService.savingsBox.get('initialBalance');

      double target = (targetRaw is num) ? targetRaw.toDouble() : 1000.0;
      double saved = (savedRaw is num) ? savedRaw.toDouble() : 0.0;
      double initial = (initialRaw is num) ? initialRaw.toDouble() : 0.0;

      emit(
        state.copyWith(
          targetAmount: target,
          savedAmount: saved,
          initialBalance: initial,
          isLoading: false,
        ),
      );
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
    }
  }

  Future<void> _onArchiveCycle(
    ArchiveCycle event,
    Emitter<SavingsState> emit,
  ) async {
    try {
      final sweepAmount = event.currentBalance;

      final Map<String, double> historical = Map<String, double>.from(
        DatabaseService.savingsBox.get('historicalSavings') ?? {},
      );

      historical[event.monthKey] =
          (historical[event.monthKey] ?? 0.0) + sweepAmount;

      await DatabaseService.savingsBox.put('historicalSavings', historical);
      await DatabaseService.savingsBox.put(
        'lastProcessedMonth',
        event.monthKey,
      );

      final newTotalSavings = state.savedAmount + sweepAmount;
      await DatabaseService.savingsBox.put('savedAmount', newTotalSavings);
      emit(state.copyWith(savedAmount: newTotalSavings));
    } catch (e) {
      // Handle error gracefully if needed
    }
  }

  Future<void> _onUpdateTargetAmount(
    UpdateTargetAmount event,
    Emitter<SavingsState> emit,
  ) async {
    try {
      await DatabaseService.savingsBox.put('targetAmount', event.amount);
      emit(state.copyWith(targetAmount: event.amount));
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  Future<void> _onUpdateSavedAmount(
    UpdateSavedAmount event,
    Emitter<SavingsState> emit,
  ) async {
    try {
      await DatabaseService.savingsBox.put('savedAmount', event.amount);
      emit(state.copyWith(savedAmount: event.amount));
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  Future<void> _onUpdateInitialBalance(
    UpdateInitialBalance event,
    Emitter<SavingsState> emit,
  ) async {
    try {
      await DatabaseService.savingsBox.put('initialBalance', event.amount);
      emit(state.copyWith(initialBalance: event.amount));
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }
}
