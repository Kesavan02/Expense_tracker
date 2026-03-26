import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/budget_model.dart';
import '../repositories/budget_repository.dart';
import 'budget_event.dart';
import 'budget_state.dart';

class BudgetBloc extends Bloc<BudgetEvent, BudgetState> {
  final BudgetRepository _budgetRepository;
  StreamSubscription? _budgetSubscription;

  BudgetBloc({required BudgetRepository budgetRepository})
      : _budgetRepository = budgetRepository,
        super(BudgetInitial()) {
    on<LoadBudgets>(_onLoadBudgets);
    on<AddBudget>(_onAddBudget);

    // Internal events to update state from stream
    on<_UpdateBudgets>((event, emit) {
      emit(BudgetLoaded(budgets: event.budgets));
    });

    on<_HandleError>((event, emit) {
      emit(BudgetError(event.message));
    });
  }

  Future<void> _onLoadBudgets(LoadBudgets event, Emitter<BudgetState> emit) async {
    emit(BudgetLoading());
    await _budgetSubscription?.cancel();
    _budgetSubscription = _budgetRepository.getBudgets().listen(
      (budgets) => add(_UpdateBudgets(budgets)),
      onError: (error) => add(_HandleError(error.toString())),
    );
  }

  Future<void> _onAddBudget(AddBudget event, Emitter<BudgetState> emit) async {
    try {
      await _budgetRepository.addBudget(event.budget);
      // Repository handles updating the stream/cache
    } catch (e) {
      emit(BudgetError(e.toString()));
    }
  }

  @override
  Future<void> close() {
    _budgetSubscription?.cancel();
    return super.close();
  }
}

// These are internal events not exposed in budget_event.dart
class _UpdateBudgets extends BudgetEvent {
  final List<BudgetModel> budgets;
  const _UpdateBudgets(this.budgets);
}

class _HandleError extends BudgetEvent {
  final String message;
  const _HandleError(this.message);
}
