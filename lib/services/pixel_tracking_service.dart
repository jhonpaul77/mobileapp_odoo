import 'package:dio/dio.dart';
import 'config_service.dart';
import 'secure_storage_service.dart';

/// Pixel Tracking Service - POST user activity tracking data
class PixelTrackingService {
  final _dio = Dio();
  final _configService = ConfigService();
  final _storage = SecureStorageService();

  /// Track user app open with database, user_id, and user_name
  Future<void> trackAppOpen() async {
    try {
      print('📍 [PIXEL] Tracking app open...');
      
      // Get pixel tracking URL from config
      print('📍 [PIXEL] Loading pixel endpoint from config...');
      final pixelEndpoint = await _configService.getPixelTrackingUrl();
      print('📍 [PIXEL] Endpoint: $pixelEndpoint');
      
      // Get database from config
      print('📍 [PIXEL] Loading database from config...');
      final database = await _configService.getDatabase();
      print('📍 [PIXEL] Database: "$database"');
      
      // Get user data from storage
      print('📍 [PIXEL] Loading user data from storage...');
      final userData = await _storage.getUserData();
      print('📍 [PIXEL] User data keys: ${userData?.keys.toList()}');
      final userName = userData?['username'] as String?;
      print('📍 [PIXEL] Username: "$userName"');
      
      if (database.isEmpty || userName == null) {
        print('⚠️  [PIXEL] Missing data - database empty: ${database.isEmpty}, username null: ${userName == null}');
        print('📍 [PIXEL] Skipping pixel tracking (not logged in or data missing)');
        return;
      }
      
      print('📍 [PIXEL] Sending: database=$database, user_id=1, user_name=$userName');
      
      final payload = {
        'database': database,
        'user_id': 1,  // ✅ Always 1
        'user_name': userName,
      };
      
      print('📍 [PIXEL] Payload: $payload');
      
      final response = await _dio.post(
        pixelEndpoint,
        data: payload,
        options: Options(
          contentType: Headers.jsonContentType,
          receiveTimeout: const Duration(seconds: 10),
          sendTimeout: const Duration(seconds: 10),
        ),
      );
      
      print('✅ [PIXEL] Tracking successful: ${response.statusCode}');
      print('✅ [PIXEL] Response: ${response.data}');
    } catch (e) {
      print('❌ [PIXEL] Tracking failed: $e');
      if (e is DioException) {
        print('❌ [PIXEL] DioException status: ${e.response?.statusCode}');
        print('❌ [PIXEL] DioException response: ${e.response?.data}');
        print('❌ [PIXEL] DioException message: ${e.message}');
      }
      // Don't throw - this is non-critical tracking
    }
  }

  /// Track user logout
  Future<void> trackLogout() async {
    try {
      print('📍 [PIXEL] Tracking logout...');
      
      final pixelEndpoint = await _configService.getPixelTrackingUrl();
      final database = await _configService.getDatabase();
      final userData = await _storage.getUserData();
      final userName = userData?['username'] as String?;
      
      if (database.isEmpty) {
        return;
      }
      
      final payload = {
        'database': database,
        'user_id': 1,  // ✅ Always 1
        'user_name': userName ?? 'unknown',
        'action': 'logout',
      };
      
      await _dio.post(
        pixelEndpoint,
        data: payload,
        options: Options(
          contentType: Headers.jsonContentType,
          receiveTimeout: const Duration(seconds: 5),
          sendTimeout: const Duration(seconds: 5),
        ),
      );
      
      print('✅ [PIXEL] Logout tracking sent');
    } catch (e) {
      print('⚠️  [PIXEL] Logout tracking failed: $e');
    }
  }
}
