import 'package:equatable/equatable.dart';
import '../models/transaction_model.dart';
import '../models/category_model.dart';

abstract class TransactionsState extends Equatable {
  const TransactionsState();

  @override
  List<Object?> get props => [];
}

class TransactionsInitial extends TransactionsState {}

class TransactionsLoading extends TransactionsState {}

class TransactionsLoaded extends TransactionsState {
  final List<TransactionModel> transactions;
  final List<CategoryModel> categories;
  final double totalIncome;
  final double totalExpenses;
  final double balance;

  const TransactionsLoaded({
    required this.transactions,
    this.categories = const [],
    required this.totalIncome,
    required this.totalExpenses,
    required this.balance,
  });

  @override
  List<Object?> get props => [transactions, categories, totalIncome, totalExpenses, balance];

  TransactionsLoaded copyWith({
    List<TransactionModel>? transactions,
    List<CategoryModel>? categories,
    double? totalIncome,
    double? totalExpenses,
    double? balance,
  }) {
    return TransactionsLoaded(
      transactions: transactions ?? this.transactions,
      categories: categories ?? this.categories,
      totalIncome: totalIncome ?? this.totalIncome,
      totalExpenses: totalExpenses ?? this.totalExpenses,
      balance: balance ?? this.balance,
    );
  }
}

class TransactionsError extends TransactionsState {
  final String message;

  const TransactionsError(this.message);

  @override
  List<Object?> get props => [message];
}
