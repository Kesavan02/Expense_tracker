import 'package:equatable/equatable.dart';
import '../models/admin_models.dart';
import 'package:transactions/transactions.dart';

// Events
abstract class AdminEvent extends Equatable {
  const AdminEvent();
  @override
  List<Object?> get props => [];
}

class LoadAdminDashboard extends AdminEvent {
  final String range;
  const LoadAdminDashboard({this.range = 'monthly'});
  @override
  List<Object?> get props => [range];
}

class DeleteAdminUser extends AdminEvent {
  final String userId;
  const DeleteAdminUser(this.userId);
  @override
  List<Object?> get props => [userId];
}

class AddAdminCategory extends AdminEvent {
  final CategoryModel category;
  const AddAdminCategory(this.category);
  @override
  List<Object?> get props => [category];
}

class DeleteAdminCategory extends AdminEvent {
  final String categoryId;
  const DeleteAdminCategory(this.categoryId);
  @override
  List<Object?> get props => [categoryId];
}

// States
abstract class AdminState extends Equatable {
  const AdminState();
  @override
  List<Object?> get props => [];
}

class AdminInitial extends AdminState {}

class AdminLoading extends AdminState {}

class AdminLoaded extends AdminState {
  final List<AdminUserModel> users;
  final AdminStatsModel stats;
  final String range;
  final List<CategoryModel> categories;

  const AdminLoaded({
    required this.users,
    required this.stats,
    required this.range,
    required this.categories,
  });

  @override
  List<Object?> get props => [users, stats, range, categories];
}

class AdminError extends AdminState {
  final String message;
  const AdminError(this.message);
  @override
  List<Object?> get props => [message];
}
