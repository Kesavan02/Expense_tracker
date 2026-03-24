import 'package:flutter_bloc/flutter_bloc.dart';
import '../repositories/admin_repository.dart';
import 'admin_bloc_events_states.dart';

class AdminBloc extends Bloc<AdminEvent, AdminState> {
  final AdminRepository _repo;

  AdminBloc({required AdminRepository adminRepository})
      : _repo = adminRepository,
        super(AdminInitial()) {
    on<LoadAdminDashboard>(_onLoad);
    on<DeleteAdminUser>(_onDelete);
    on<AddAdminCategory>(_onAddCategory);
    on<DeleteAdminCategory>(_onDeleteCategory);
  }

  Future<void> _onLoad(LoadAdminDashboard event, Emitter<AdminState> emit) async {
    emit(AdminLoading());
    try {
      final results = await Future.wait([
        _repo.getAllUsers(),
        _repo.getStats(event.range),
        _repo.getAllCategories(),
      ]);
      emit(AdminLoaded(
        users: results[0] as dynamic,
        stats: results[1] as dynamic,
        range: event.range,
        categories: results[2] as dynamic,
      ));
    } catch (e) {
      emit(AdminError(e.toString()));
    }
  }

  Future<void> _onDelete(DeleteAdminUser event, Emitter<AdminState> emit) async {
    final currentState = state;
    if (currentState is! AdminLoaded) return;
    try {
      await _repo.deleteUser(event.userId);
      final updatedUsers = currentState.users.where((u) => u.id != event.userId).toList();
      emit(AdminLoaded(users: updatedUsers, stats: currentState.stats, range: currentState.range, categories: currentState.categories));
    } catch (e) {
      emit(AdminError(e.toString()));
    }
  }

  Future<void> _onAddCategory(AddAdminCategory event, Emitter<AdminState> emit) async {
    final currentState = state;
    if (currentState is! AdminLoaded) return;
    try {
      final newCategory = await _repo.addCategory(event.category);
      final updatedCategories = List<dynamic>.from(currentState.categories)..add(newCategory);
      emit(AdminLoaded(users: currentState.users, stats: currentState.stats, range: currentState.range, categories: updatedCategories.cast()));
    } catch (e) {
      emit(AdminError(e.toString()));
    }
  }

  Future<void> _onDeleteCategory(DeleteAdminCategory event, Emitter<AdminState> emit) async {
    final currentState = state;
    if (currentState is! AdminLoaded) return;
    try {
      await _repo.deleteCategory(event.categoryId);
      final updatedCategories = currentState.categories.where((c) => c.id != event.categoryId).toList();
      emit(AdminLoaded(users: currentState.users, stats: currentState.stats, range: currentState.range, categories: updatedCategories));
    } catch (e) {
      emit(AdminError(e.toString()));
    }
  }
}
