import 'package:dio/dio.dart';
import '../auth_service.dart';
import '../secure_storage_service.dart';

class TokenInterceptor extends Interceptor {
  final Dio dio;
  final _storage = SecureStorageService();

  TokenInterceptor(this.dio);

  bool _isAuthEndpoint(String path) {
    return path.contains('/auth/signin') ||
        path.contains('/auth/refresh') ||
        path.contains('/auth/signout');
  }

  @override
  void onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    if (_isAuthEndpoint(options.path)) return handler.next(options);

    var token = options.headers['Authorization']
        ?.toString()
        .replaceFirst('Bearer ', '');
    token ??= await _storage.getAccessToken();

    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    return handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final status = err.response?.statusCode;
    final path = err.requestOptions.path;

    if (status == 401 && !_isAuthEndpoint(path)) {
      final data = err.response?.data;
      final isExpired = data is Map &&
          (data['Data'] == 'Token is expired' ||
              data['Message']?.toString().contains('expired') == true);

      if (isExpired) {
        print('🔄 [INTERCEPTOR] Token expired, refreshing...');
        final success = await AuthService().refreshAccessToken();

        if (success) {
          final newToken = await _storage.getAccessToken();
          err.requestOptions.headers['Authorization'] = 'Bearer $newToken';
          final retry = await dio.fetch(err.requestOptions);
          return handler.resolve(retry);
        } else {
          print('❌ [INTERCEPTOR] Refresh failed → logout');
          await _storage.clearAll();
        }
      }
    }

    return handler.next(err);
  }
}
