import 'package:dio/dio.dart';
import 'package:mobile/core/constants/api_endpoints.dart';
import 'package:mobile/core/network/api_exception.dart';
import 'package:mobile/core/network/auth_interceptor.dart';

class ApiClient {
  late final Dio dio;

  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  static ApiClient get instance => _instance;

  ApiClient._internal() {
    dio = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    dio.interceptors.add(AuthInterceptor(dio: dio));
  }

  ApiException _handleError(DioException e) {
    String message = 'An unexpected network error occurred.';
    if (e.response != null && e.response?.data != null) {
      final data = e.response?.data;
      if (data is Map) {
        if (data.containsKey('error')) {
          message = data['error'].toString();
        } else if (data.containsKey('detail')) {
          message = data['detail'].toString();
        } else if (data.containsKey('message')) {
          message = data['message'].toString();
        } else {
          message = data.values.map((v) => v is List ? v.join(', ') : v.toString()).join('\n');
        }
      } else if (data is String) {
        message = data;
      }
    } else if (e.type == DioExceptionType.connectionTimeout || e.type == DioExceptionType.receiveTimeout) {
      message = 'Connection timed out. Please check your internet connection.';
    } else if (e.type == DioExceptionType.connectionError) {
      message = 'Could not connect to Vewra server. Please make sure backend is running.';
    }

    return ApiException(
      message: message,
      statusCode: e.response?.statusCode,
      data: e.response?.data,
    );
  }

  // Instance methods
  Future<dynamic> get(String path, {Map<String, dynamic>? queryParameters}) async {
    try {
      final response = await dio.get(path, queryParameters: queryParameters);
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<dynamic> post(String path, {dynamic data}) async {
    try {
      final response = await dio.post(path, data: data);
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<dynamic> patch(String path, {dynamic data}) async {
    try {
      final response = await dio.patch(path, data: data);
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<dynamic> put(String path, {dynamic data}) async {
    try {
      final response = await dio.put(path, data: data);
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<dynamic> delete(String path) async {
    try {
      final response = await dio.delete(path);
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
}
