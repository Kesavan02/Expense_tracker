import 'package:hive/hive.dart';
import 'package:equatable/equatable.dart';
import 'package:transactions/transactions.dart';

part 'budget_model.g.dart';

@HiveType(typeId: 2)
class BudgetModel extends Equatable {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final CategoryModel category;
  @HiveField(2)
  final double amount;
  @HiveField(3)
  final DateTime startDate;
  @HiveField(4)
  final DateTime endDate;

  const BudgetModel({
    required this.id,
    required this.category,
    required this.amount,
    required this.startDate,
    required this.endDate,
  });

  factory BudgetModel.fromJson(Map<String, dynamic> json) {
    return BudgetModel(
      id: json['_id'] as String,
      category: CategoryModel.fromJson(json['category'] as Map<String, dynamic>),
      amount: (json['amount'] as num).toDouble(),
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'category': category.toJson(),
      'amount': amount,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [id, category, amount, startDate, endDate];
}
