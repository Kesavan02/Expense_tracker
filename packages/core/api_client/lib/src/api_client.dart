import 'package:dio/dio.dart';

class ApiClient {
  final Dio _dio;

  ApiClient({required String baseUrl}) : _dio = Dio(BaseOptions(baseUrl: baseUrl)) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // You can inject standard headers here (e.g. Content-Type)
          options.headers['Content-Type'] = 'application/json';
          return handler.next(options);
        },
        onError: (DioException e, handler) {
          // Handle global errors, token refresh logic could go here
          return handler.next(e);
        },
      ),
    );
  }

  /// Expose the underlying Dio client to allow adding custom interceptors (like AuthInterceptor)
  Dio get dio => _dio;

  /// Perform a GET request
  Future<Response> get(String path, {Map<String, dynamic>? queryParameters, Options? options}) async {
    return _dio.get(path, queryParameters: queryParameters, options: options);
  }

  /// Perform a POST request
  Future<Response> post(String path, {dynamic data, Map<String, dynamic>? queryParameters, Options? options}) async {
    return _dio.post(path, data: data, queryParameters: queryParameters, options: options);
  }

  /// Perform a PUT request
  Future<Response> put(String path, {dynamic data, Map<String, dynamic>? queryParameters, Options? options}) async {
    return _dio.put(path, data: data, queryParameters: queryParameters, options: options);
  }

  /// Perform a DELETE request
  Future<Response> delete(String path, {dynamic data, Map<String, dynamic>? queryParameters, Options? options}) async {
    return _dio.delete(path, data: data, queryParameters: queryParameters, options: options);
  }
}
