import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../repositories/transaction_repository.dart';
import '../models/transaction_model.dart';
import 'transactions_event.dart';
import 'transactions_state.dart';

class TransactionsBloc extends Bloc<TransactionsEvent, TransactionsState> {
  final TransactionRepository _transactionRepository;
  StreamSubscription? _transactionsSubscription;
  StreamSubscription? _categoriesSubscription;

  TransactionsBloc({required TransactionRepository transactionRepository})
    : _transactionRepository = transactionRepository,
      super(TransactionsInitial()) {
    on<LoadTransactions>(_onLoadTransactions);
    on<TransactionsUpdated>(_onTransactionsUpdated);
    on<LoadCategories>(_onLoadCategories);
    on<CategoriesUpdated>(_onCategoriesUpdated);
    on<AddTransactionRequested>(_onAddTransactionRequested);
    on<DeleteTransactionsRequested>(_onDeleteTransactionsRequested);
  }

  // ── All-time totals helper ─────────────────────────────────────────────────
  ({double income, double expenses}) _computeTotals(
    List<TransactionModel> transactions,
  ) {
    double income = 0;
    double expenses = 0;
    for (final tx in transactions) {
      if (tx.type == 'income') {
        income += tx.amount;
      } else {
        expenses += tx.amount;
      }
    }
    return (income: income, expenses: expenses);
  }

  Future<void> _onLoadTransactions(
    LoadTransactions event,
    Emitter<TransactionsState> emit,
  ) async {
    if (!event.silent) {
      emit(TransactionsLoading());
    }
    await _transactionsSubscription?.cancel();
    _transactionsSubscription = _transactionRepository.getTransactions().listen(
      (transactions) {
        add(TransactionsUpdated(transactions));
      },
    );
  }

  void _onTransactionsUpdated(
    TransactionsUpdated event,
    Emitter<TransactionsState> emit,
  ) {
    final transactions = event.transactions;
    final totals = _computeTotals(transactions);

    if (state is TransactionsLoaded) {
      emit(
        (state as TransactionsLoaded).copyWith(
          transactions: transactions,
          totalIncome: totals.income,
          totalExpenses: totals.expenses,
          balance: totals.income - totals.expenses,
        ),
      );
    } else {
      emit(
        TransactionsLoaded(
          transactions: transactions,
          totalIncome: totals.income,
          totalExpenses: totals.expenses,
          balance: totals.income - totals.expenses,
        ),
      );
    }
  }

  Future<void> _onLoadCategories(
    LoadCategories event,
    Emitter<TransactionsState> emit,
  ) async {
    await _categoriesSubscription?.cancel();
    _categoriesSubscription = _transactionRepository.getCategories().listen((
      categories,
    ) {
      add(CategoriesUpdated(categories));
    });
  }

  void _onCategoriesUpdated(
    CategoriesUpdated event,
    Emitter<TransactionsState> emit,
  ) {
    if (state is TransactionsLoaded) {
      emit(
        (state as TransactionsLoaded).copyWith(categories: event.categories),
      );
    }
  }

  Future<void> _onAddTransactionRequested(
    AddTransactionRequested event,
    Emitter<TransactionsState> emit,
  ) async {
    try {
      final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
      final newTransaction = TransactionModel(
        id: tempId,
        amount: event.amount,
        type: event.type,
        category: event.category,
        description: event.description,
        date: event.date,
      );

      // Optimistic update
      if (state is TransactionsLoaded) {
        final currentState = state as TransactionsLoaded;
        final updatedTransactions = List<TransactionModel>.from(
          currentState.transactions,
        )..insert(0, newTransaction);
        updatedTransactions.sort((a, b) => b.date.compareTo(a.date));

        final totals = _computeTotals(updatedTransactions);
        emit(
          currentState.copyWith(
            transactions: updatedTransactions,
            totalIncome: totals.income,
            totalExpenses: totals.expenses,
            balance: totals.income - totals.expenses,
          ),
        );
      }

      await _transactionRepository.addTransaction(newTransaction);

      // Silent reload to get real ID and synced status eventually
      add(const LoadTransactions(silent: true));
    } catch (e) {
      emit(TransactionsError(e.toString()));
      add(const LoadTransactions(silent: true));
    }
  }

  Future<void> _onDeleteTransactionsRequested(
    DeleteTransactionsRequested event,
    Emitter<TransactionsState> emit,
  ) async {
    try {
      if (state is TransactionsLoaded) {
        final currentState = state as TransactionsLoaded;
        final updatedTransactions = currentState.transactions
            .where((tx) => !event.transactionIds.contains(tx.id))
            .toList();

        final totals = _computeTotals(updatedTransactions);
        emit(
          currentState.copyWith(
            transactions: updatedTransactions,
            totalIncome: totals.income,
            totalExpenses: totals.expenses,
            balance: totals.income - totals.expenses,
          ),
        );
      }

      await _transactionRepository.deleteTransactions(event.transactionIds);
      add(const LoadTransactions(silent: true));
    } catch (e) {
      emit(TransactionsError(e.toString()));
      add(const LoadTransactions(silent: true));
    }
  }

  @override
  Future<void> close() {
    _transactionsSubscription?.cancel();
    _categoriesSubscription?.cancel();
    return super.close();
  }
}
