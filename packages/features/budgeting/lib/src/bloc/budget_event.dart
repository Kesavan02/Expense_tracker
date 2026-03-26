import '../models/budget_model.dart';

abstract class BudgetEvent {
  const BudgetEvent();
}

class LoadBudgets extends BudgetEvent {}

class AddBudget extends BudgetEvent {
  final BudgetModel budget;
  const AddBudget(this.budget);
}
