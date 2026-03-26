import 'package:hive/hive.dart';
import 'package:transactions/transactions.dart';

part 'budget_model.g.dart';

@HiveType(typeId: 3)
class BudgetModel {
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
      id: json['_id'] ?? json['id'] ?? '',
      category: CategoryModel.fromJson(json['category']),
      amount: (json['amount'] as num).toDouble(),
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category': category.id,
      'amount': amount,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
    };
  }
}
