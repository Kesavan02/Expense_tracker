import 'package:api_client/api_client.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/admin_models.dart';
import 'package:transactions/transactions.dart';

class AdminRepository {
  final ApiClient _apiClient;

  AdminRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }

  Future<List<AdminUserModel>> getAllUsers() async {
    final token = await _getToken();
    final response = await _apiClient.get(
      '/api/admin/users',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    final List<dynamic> data = response.data['data'] ?? [];
    return data.map((e) => AdminUserModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<AdminStatsModel> getStats(String range) async {
    final token = await _getToken();
    final response = await _apiClient.get(
      '/api/admin/stats',
      queryParameters: {'range': range},
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return AdminStatsModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<void> deleteUser(String userId) async {
    final token = await _getToken();
    await _apiClient.delete(
      '/api/admin/users/$userId',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }

  Future<List<CategoryModel>> getAllCategories() async {
    final token = await _getToken();
    final response = await _apiClient.get(
      '/api/admin/categories',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    final List<dynamic> data = response.data['data'] ?? [];
    return data.map((e) => CategoryModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<CategoryModel> addCategory(CategoryModel category) async {
    final token = await _getToken();
    final response = await _apiClient.post(
      '/api/admin/categories',  // Creates a global category (no user — visible to everyone)
      data: category.toJson(),
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return CategoryModel.fromJson(response.data['data']);
  }

  Future<void> deleteCategory(String categoryId) async {
    final token = await _getToken();
    await _apiClient.delete(
      '/api/admin/categories/$categoryId', // Admin-only route — bypasses ownership checks
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }
}
