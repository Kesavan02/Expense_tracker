import 'package:api_client/api_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import 'package:dio/dio.dart';

class AuthRepository {
  final ApiClient _apiClient;
  
  AuthRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  Future<UserModel> login(String email, String password) async {
    try {
      final response = await _apiClient.post(
        '/api/auth/login',
        data: {'email': email, 'password': password},
      );
      final responseData = response.data;
      final userData = responseData is Map && responseData.containsKey('data') 
          ? responseData['data'] 
          : responseData;
          
      final user = UserModel.fromJson(userData);
      await _saveToken(user.token);
      return user;
    } on DioException catch (e) {
      String errorMessage = e.message ?? 'Unknown error';
      if (e.response?.data != null) {
        if (e.response!.data is Map) {
          errorMessage = e.response!.data['message'] ?? errorMessage;
        } else if (e.response!.data is String) {
          errorMessage = 'Server Error: ${e.response!.statusCode}';
        }
      }
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception('Login Failed: $e');
    }
  }

  Future<UserModel> register(String name, String email, String password, {String role = 'user'}) async {
    try {
      final response = await _apiClient.post(
        '/api/auth/register',
        data: {'name': name, 'email': email, 'password': password, 'role': role},
      );
      final responseData = response.data;
      final userData = responseData is Map && responseData.containsKey('data') 
          ? responseData['data'] 
          : responseData;
          
      final user = UserModel.fromJson(userData);
      await _saveToken(user.token);
      return user;
    } on DioException catch (e) {
      String errorMessage = e.message ?? 'Unknown error';
      if (e.response?.data != null) {
        if (e.response!.data is Map) {
          errorMessage = e.response!.data['message'] ?? errorMessage;
        } else if (e.response!.data is String) {
           errorMessage = 'Server Error: ${e.response!.statusCode}';
        }
      }
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception('Registration Failed: $e');
    }
  }
  
  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jwt_token', token);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }
  
  Future<UserModel?> getMe() async {
     try {
       final token = await getToken();
       if (token == null) return null;
       
       final response = await _apiClient.get(
        '/api/auth/me',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
       );
       
       final responseData = response.data;
       final userData = responseData is Map && responseData.containsKey('data') 
          ? responseData['data'] 
          : responseData;

       if (userData is Map<String, dynamic>) {
           return UserModel.fromJson({...userData, 'token': token});
       } else {
           return null;
       }
     } catch (_) {
       return null;
     }
  }

  Future<UserModel> updateProfile({
    String? name,
    String? avatar,
    String? currency,
    String? dateFormat,
  }) async {
    try {
      final token = await getToken();
      if (token == null) throw Exception('No token found');

      final data = <String, dynamic>{};
      if (name != null) data['name'] = name;
      if (avatar != null) data['avatar'] = avatar;
      if (currency != null) data['currency'] = currency;
      if (dateFormat != null) data['dateFormat'] = dateFormat;

      final response = await _apiClient.put(
        '/api/auth/profile',
        data: data,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      final responseData = response.data;
      final userData = responseData is Map && responseData.containsKey('data')
          ? responseData['data']
          : responseData;

      return UserModel.fromJson({...userData, 'token': token});
    } on DioException catch (e) {
      String errorMessage = e.message ?? 'Unknown error';
      if (e.response?.data != null) {
        if (e.response!.data is Map) {
          errorMessage = e.response!.data['message'] ?? errorMessage;
        } else if (e.response!.data is String) {
          errorMessage = 'Server Error: ${e.response!.statusCode}';
        }
      }
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception('Update failed: $e');
    }
  }
}
