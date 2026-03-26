import 'package:api_client/api_client.dart';
import 'package:local_storage/local_storage.dart';
import 'package:dio/dio.dart';
import '../models/budget_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive/hive.dart';
import 'dart:async';

class BudgetRepository {
  final ApiClient _apiClient;
  final HiveService _hiveService;
  static const String _budgetBoxName = 'budgets_box';

  BudgetRepository({
    required ApiClient apiClient,
    required HiveService hiveService,
  }) : _apiClient = apiClient,
       _hiveService = hiveService;

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }

  Stream<List<BudgetModel>> getBudgets() async* {
    final box = await _hiveService.openBox<BudgetModel>(_budgetBoxName);

    // Yield current cache first
    yield box.values.toList();

    // Trigger background fetch to sync remote
    unawaited(_fetchRemoteBudgets(box));

    // Watch for subsequent changes (local additions/deletions)
    yield* box.watch().map((_) => box.values.toList());
  }

  Future<void> _fetchRemoteBudgets(Box<BudgetModel> box) async {
    try {
      final token = await _getToken();
      final response = await _apiClient.get(
        '/api/budgets',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      final List<dynamic> data = response.data['data'] ?? [];
      final remoteBudgets = data
          .map((json) => BudgetModel.fromJson(json))
          .toList();

      // Update local storage - this will trigger the watch stream
      await box.clear();
      for (final b in remoteBudgets) {
        await box.put(b.id, b);
      }
    } catch (e) {
      // API fetch failed
    }
  }

  Future<BudgetModel> addBudget(BudgetModel budget) async {
    final box = await _hiveService.openBox<BudgetModel>(_budgetBoxName);

    try {
      final token = await _getToken();
      final response = await _apiClient.post(
        '/api/budgets',
        data: budget.toJson(),
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      final newBudget = BudgetModel.fromJson(response.data['data']);
      await box.put(newBudget.id, newBudget);

      return newBudget;
    } catch (e) {
      throw Exception('Failed to add budget: $e');
    }
  }
}
