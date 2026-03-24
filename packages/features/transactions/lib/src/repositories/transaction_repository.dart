import 'package:api_client/api_client.dart';
import 'package:local_storage/local_storage.dart';
import 'package:dio/dio.dart';
import '../models/transaction_model.dart';
import '../models/category_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TransactionRepository {
  final ApiClient _apiClient;
  final HiveService _hiveService;
  static const String _transactionBoxName = 'transactions_box';
  static const String _categoryBoxName = 'categories_box';

  TransactionRepository({
    required ApiClient apiClient,
    required HiveService hiveService,
  })  : _apiClient = apiClient,
        _hiveService = hiveService;

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }

  /// Get transactions following the stale-while-revalidate pattern
  Stream<List<TransactionModel>> getTransactions() async* {
    final box = await _hiveService.openBox<TransactionModel>(_transactionBoxName);
    
    // 1. Yield local data immediately
    final cached = box.values.toList();
    yield cached;

    // 2. Fetch from API and update cache
    try {
      final token = await _getToken();
      final response = await _apiClient.get(
        '/api/transactions',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      
      final List<dynamic> data = response.data['data'] ?? [];
      final remoteTransactions = data.map((json) => TransactionModel.fromJson(json)).toList();

      // Clear and update box
      await box.clear();
      await box.addAll(remoteTransactions);

      yield remoteTransactions;
    } catch (e) {
      // API fetch failed, we already yielded cached data.
    }
  }

  /// Get categories following similar pattern
  Stream<List<CategoryModel>> getCategories() async* {
    final box = await _hiveService.openBox<CategoryModel>(_categoryBoxName);
    
    final cached = box.values.toList();
    yield cached;

    try {
      final token = await _getToken();
      final response = await _apiClient.get(
        '/api/categories',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      
      final List<dynamic> data = response.data['data'] ?? [];
      final remoteCategories = data.map((json) => CategoryModel.fromJson(json)).toList();

      await box.clear();
      await box.addAll(remoteCategories);

      yield remoteCategories;
    } catch (e) {
      // API fetch failed
    }
  }

  Future<void> deleteTransactions(List<String> ids) async {
    final box = await _hiveService.openBox<TransactionModel>(_transactionBoxName);
    
    // Optimistic Save to local Hive
    await box.deleteAll(ids);
    
    try {
      final token = await _getToken();
      
      final requests = ids.map((id) {
        if (!id.startsWith('temp_')) {
          return _apiClient.delete(
            '/api/transactions/$id',
            options: Options(headers: {'Authorization': 'Bearer $token'}),
          );
        }
        return Future.value();
      });

      await Future.wait(requests);
    } catch (e) {
      // Ignored for offline-first optimistic deletion
    }
  }

  Future<TransactionModel> addTransaction(TransactionModel transaction) async {
    final box = await _hiveService.openBox<TransactionModel>(_transactionBoxName);
    
    // Optimistic Save to local Hive
    await box.put(transaction.id, transaction);
    
    try {
      final token = await _getToken();
      final data = transaction.toJson();
      data.remove('_id'); // Remove local temp ID before sending to server

      final response = await _apiClient.post(
        '/api/transactions',
        data: data,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      
      final newTransaction = TransactionModel.fromJson(response.data['data']);
      
      // Remove temp from local storage and add real one
      await box.delete(transaction.id);
      await box.put(newTransaction.id, newTransaction);
      
      return newTransaction;
    } catch (e) {
      // Background sync failed, keep it in offline cache.
      return transaction;
    }
  }
}
