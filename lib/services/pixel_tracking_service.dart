import 'package:dio/dio.dart';
import 'config_service.dart';
import 'secure_storage_service.dart';

/// Pixel Tracking Service - POST user activity tracking data
class PixelTrackingService {
  static const String _pixelEndpoint = 'https://internal.hector.my.id/create_pixel';
  
  final _dio = Dio();
  final _configService = ConfigService();
  final _storage = SecureStorageService();

  /// Track user app open with database, user_id, and user_name
  Future<void> trackAppOpen() async {
    try {
      print('📍 [PIXEL] Tracking app open...');
      
      // Get database from config
      final database = await _configService.getDatabase();
      
      // Get user data from storage
      final userData = await _storage.getUserData();
      final userId = userData?['user_id'] as int?;
      final userName = userData?['username'] as String?;
      
      if (database.isEmpty || userId == null || userName == null) {
        print('⚠️  [PIXEL] Missing data - database: $database, user_id: $userId, user_name: $userName');
        return;
      }
      
      print('📍 [PIXEL] Sending: database=$database, user_id=$userId, user_name=$userName');
      
      final payload = {
        'database': database,
        'user_id': userId,
        'user_name': userName,
      };
      
      final response = await _dio.post(
        _pixelEndpoint,
        data: payload,
        options: Options(
          contentType: Headers.jsonContentType,
          receiveTimeout: const Duration(seconds: 10),
          sendTimeout: const Duration(seconds: 10),
        ),
      );
      
      print('✅ [PIXEL] Tracking successful: ${response.statusCode}');
      print('   Response: ${response.data}');
    } catch (e) {
      print('❌ [PIXEL] Tracking failed: $e');
      // Don't throw - this is non-critical tracking
    }
  }

  /// Track user logout
  Future<void> trackLogout() async {
    try {
      print('📍 [PIXEL] Tracking logout...');
      
      final database = await _configService.getDatabase();
      final userData = await _storage.getUserData();
      final userId = userData?['user_id'] as int?;
      final userName = userData?['username'] as String?;
      
      if (database.isEmpty || userId == null) {
        return;
      }
      
      final payload = {
        'database': database,
        'user_id': userId,
        'user_name': userName ?? 'unknown',
        'action': 'logout',
      };
      
      await _dio.post(
        _pixelEndpoint,
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
