part of 'savings_bloc.dart';

final class SavingsState {
  final bool isLoading;
  final String? errorMessage;
  final double targetAmount;
  final double savedAmount;
  final double initialBalance;

  SavingsState({
    this.isLoading = false,
    this.errorMessage,
    this.targetAmount = 1000.0,
    this.savedAmount = 0.0,
    this.initialBalance = 0.0,
  });

  SavingsState copyWith({
    bool? isLoading,
    String? errorMessage,
    double? targetAmount,
    double? savedAmount,
    double? initialBalance,
  }) {
    return SavingsState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      targetAmount: targetAmount ?? this.targetAmount,
      savedAmount: savedAmount ?? this.savedAmount,
      initialBalance: initialBalance ?? this.initialBalance,
    );
  }
}
