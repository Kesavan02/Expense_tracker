import 'package:equatable/equatable.dart';
import '../models/transaction_model.dart';
import '../models/category_model.dart';

abstract class TransactionsEvent extends Equatable {
  const TransactionsEvent();

  @override
  List<Object?> get props => [];
}

class LoadTransactions extends TransactionsEvent {
  final bool silent;

  const LoadTransactions({this.silent = false});

  @override
  List<Object?> get props => [silent];
}

class TransactionsUpdated extends TransactionsEvent {
  final List<TransactionModel> transactions;

  const TransactionsUpdated(this.transactions);

  @override
  List<Object?> get props => [transactions];
}

class LoadCategories extends TransactionsEvent {}

class CategoriesUpdated extends TransactionsEvent {
  final List<CategoryModel> categories;

  const CategoriesUpdated(this.categories);

  @override
  List<Object?> get props => [categories];
}

class AddTransactionRequested extends TransactionsEvent {
  final double amount;
  final String type;
  final CategoryModel category;
  final String description;
  final DateTime date;

  const AddTransactionRequested({
    required this.amount,
    required this.type,
    required this.category,
    required this.description,
    required this.date,
  });

  @override
  List<Object?> get props => [amount, type, category, description, date];
}

class DeleteTransactionsRequested extends TransactionsEvent {
  final List<String> transactionIds;

  const DeleteTransactionsRequested(this.transactionIds);

  @override
  List<Object?> get props => [transactionIds];
}
