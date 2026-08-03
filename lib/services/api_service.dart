import 'package:dio/dio.dart';

import '../config/api_config.dart';
import 'config_service.dart';
import 'interceptors/token_interceptor.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  Dio? _dio;

  Future<void> init() async {
    if (_dio != null) {
      print('⚙️ [API] Already initialized, skipping re-init');
      return;
    }

    // ✅ Load base URL from ConfigService (saved config)
    String baseUrl = ApiConfig.baseUrl; // fallback to hardcoded default
    try {
      final configService = ConfigService();
      await configService.initialize();
      final savedUrl = await configService.getUrl();
      if (savedUrl.isNotEmpty) {
        baseUrl = savedUrl;
        print('✅ [API] Loaded base URL from config: $baseUrl');
      } else {
        print('⚠️  [API] No saved URL in config, using default: $baseUrl');
      }
    } catch (e) {
      print('⚠️  [API] Failed to load config, using default: $baseUrl');
      print('   Error: $e');
    }

    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: ApiConfig.headers,
    ));

    // Add interceptors
    _dio!.interceptors.add(TokenInterceptor(_dio!));
    _dio!.interceptors.add(LogInterceptor(
      request: true,
      requestHeader: true,
      requestBody: true,
      responseHeader: false,
      responseBody: true,
      error: true,
      logPrint: (object) {
        final log = object.toString();
        if (log.length > 800) {
          print('${log.substring(0, 800)}...[truncated]');
        } else {
          print(log);
        }
      },
    ));

    print('✅ [API] Dio initialized with interceptors');
  }

  Dio get dio {
    if (_dio == null) init();
    return _dio!;
  }

  void setAuthToken(String token) {
    dio.options.headers['Authorization'] = 'Bearer $token';
    print('🔐 [API] Auth token set');
  }

  void removeAuthToken() {
    dio.options.headers.remove('Authorization');
    print('🚫 [API] Auth token removed');
  }

  void updateBaseUrl(String newBaseUrl) {
    if (_dio != null) {
      _dio!.options.baseUrl = newBaseUrl;
      print('🔄 [API] Base URL updated to: $newBaseUrl');
    }
  }
}
