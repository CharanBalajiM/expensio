part of 'savings_bloc.dart';

abstract class SavingsEvent {}

class LoadSavings extends SavingsEvent {}

class UpdateTargetAmount extends SavingsEvent {
  final double amount;
  UpdateTargetAmount(this.amount);
}

class UpdateSavedAmount extends SavingsEvent {
  final double amount;
  UpdateSavedAmount(this.amount);
}

class UpdateInitialBalance extends SavingsEvent {
  final double amount;
  UpdateInitialBalance(this.amount);
}
