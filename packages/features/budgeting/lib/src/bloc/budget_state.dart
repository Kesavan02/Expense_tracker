import '../models/budget_model.dart';

abstract class BudgetState {
  const BudgetState();
}

class BudgetInitial extends BudgetState {}

class BudgetLoading extends BudgetState {}

class BudgetLoaded extends BudgetState {
  final List<BudgetModel> budgets;
  const BudgetLoaded({required this.budgets});
}

class BudgetError extends BudgetState {
  final String message;
  const BudgetError(this.message);
}
