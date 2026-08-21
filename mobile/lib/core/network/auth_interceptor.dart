import 'package:dio/dio.dart';
import 'package:mobile/core/constants/api_endpoints.dart';
import 'package:mobile/core/utils/storage_service.dart';

class AuthInterceptor extends Interceptor {
  final Dio dio;

  AuthInterceptor({required this.dio});

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await StorageService.getAccessToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    return handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401 && err.requestOptions.path != ApiEndpoints.login && err.requestOptions.path != ApiEndpoints.refresh) {
      final refreshToken = await StorageService.getRefreshToken();
      if (refreshToken != null && refreshToken.isNotEmpty) {
        try {
          final refreshDio = Dio(BaseOptions(baseUrl: ApiEndpoints.baseUrl));
          final res = await refreshDio.post(
            ApiEndpoints.refresh,
            data: {'refresh': refreshToken},
          );

          if (res.statusCode == 200 && res.data != null) {
            final newAccess = res.data['access'] as String;
            await StorageService.saveAccessToken(newAccess);

            // Retry original request with new token
            final opts = err.requestOptions;
            opts.headers['Authorization'] = 'Bearer $newAccess';
            final cloneReq = await dio.fetch(opts);
            return handler.resolve(cloneReq);
          }
        } catch (_) {
          await StorageService.clearAll();
        }
      }
    }
    return handler.next(err);
  }
}
