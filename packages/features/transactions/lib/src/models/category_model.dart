import 'package:hive/hive.dart';
import 'package:equatable/equatable.dart';

part 'category_model.g.dart';

@HiveType(typeId: 0)
class CategoryModel extends Equatable {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String name;
  @HiveField(2)
  final String type; // income, expense
  @HiveField(3)
  final String icon;
  @HiveField(4)
  final String color;

  const CategoryModel({
    required this.id,
    required this.name,
    required this.type,
    required this.icon,
    required this.color,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['_id'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      icon: json['icon'] as String? ?? 'default_icon',
      color: json['color'] as String? ?? '#000000',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'type': type,
      'icon': icon,
      'color': color,
    };
  }

  @override
  List<Object?> get props => [id, name, type, icon, color];
}
