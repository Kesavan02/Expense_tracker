import 'package:hive/hive.dart';
import 'package:equatable/equatable.dart';
import 'category_model.dart';

part 'transaction_model.g.dart';

@HiveType(typeId: 1)
class TransactionModel extends Equatable {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final double amount;
  @HiveField(2)
  final String type; // income, expense
  @HiveField(3)
  final CategoryModel category;
  @HiveField(4)
  final String description;
  @HiveField(5)
  final DateTime date;

  const TransactionModel({
    required this.id,
    required this.amount,
    required this.type,
    required this.category,
    required this.description,
    required this.date,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['_id'] as String,
      amount: (json['amount'] as num).toDouble(),
      type: json['type'] as String,
      category: CategoryModel.fromJson(json['category'] as Map<String, dynamic>),
      description: json['description'] as String? ?? '',
      date: DateTime.parse(json['date'] as String).toLocal(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'amount': amount,
      'type': type,
      'category': category.toJson(),
      'description': description,
      'date': date.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [id, amount, type, category, description, date];
}
