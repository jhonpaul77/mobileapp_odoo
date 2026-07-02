import 'package:dio/dio.dart';
import '../models/auth/auth_response.dart';
import '../models/auth/user.dart';
import 'api_service.dart';
import 'secure_storage_service.dart';
import '../config/api_config.dart';
import 'package:jwt_decode/jwt_decode.dart';
import 'dart:convert';

class AuthService {
  final _api = ApiService().dio;
  final _storage = SecureStorageService();

  // ✅ Login dengan Base64 encoded "username:password"
  Future<AuthResponse> signIn(String username, String password) async {
    try {
      // Encode credentials
      final credentials = base64Encode(utf8.encode('$username:$password'));
      
      final response = await _api.post(
        ApiConfig.signIn,
        data: {'login_form': credentials},
      );

      final authResponse = AuthResponse.fromJson(response.data);
      
      if (authResponse.success && authResponse.data != null) {
        // Simpan tokens
        await _storage.saveTokens(
          authResponse.data!.accessToken,
          authResponse.data!.refreshToken,
        );

        // Decode JWT untuk ambil user data
        final decoded = Jwt.parseJwt(authResponse.data!.accessToken);
        final user = User.fromToken(decoded);
        await _storage.saveUserData(user.toJson());

        // Set token di API Service
        ApiService().setAuthToken(authResponse.data!.accessToken);
        
        print('✅ [AUTH] Login successful');
      }

      return authResponse;
    } on DioException catch (e) {
      print('❌ [AUTH] Login failed: ${e.message}');
      return AuthResponse(
        success: false,
        message: e.response?.data['Message'] ?? 'Login failed',
      );
    }
  }

// ✅ Refresh Access Token (versi fix)
Future<bool> refreshAccessToken() async {
  try {
    final accessToken = await _storage.getAccessToken();
    final refreshToken = await _storage.getRefreshToken();

    if (accessToken == null || refreshToken == null) {
      print('❌ [AUTH] Missing access or refresh token');
      return false;
    }

    print('🔄 [AUTH] Refreshing token...');

    // Pakai Dio baru tanpa interceptor biar ga loop
    final dio = Dio(BaseOptions(baseUrl: ApiConfig.baseUrl));

    final response = await dio.post(
      ApiConfig.refreshToken, // biasanya '/auth/refresh'
      data: {'refresh_token': refreshToken},
      options: Options(
        headers: {
          'accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken', // 💥 wajib dikirim
        },
      ),
    );

    if (response.statusCode == 200 && response.data['Success'] == true) {
      print('✅ [AUTH] Token refreshed successfully');

      final data = response.data['Data'];
      final newAccessToken = data['access_token'];
      final newRefreshToken = data['refresh_token'];

      // Simpan token baru
      await _storage.saveTokens(newAccessToken, newRefreshToken);

      // Update token di ApiService utama
      ApiService().setAuthToken(newAccessToken);

      // Decode ulang user dari token baru
      try {
        final decoded = Jwt.parseJwt(newAccessToken);
        final user = User.fromToken(decoded);
        await _storage.saveUserData(user.toJson());
      } catch (e) {
        print('⚠️ [AUTH] Failed to decode user from new token: $e');
      }

      return true;
    } else {
      print('❌ [AUTH] Refresh failed: ${response.data}');
      return false;
    }
  } on DioException catch (e) {
    print('❌ [AUTH] Refresh error: ${e.response?.data ?? e.message}');
    return false;
  } catch (e) {
    print('❌ [AUTH] Unexpected error during refresh: $e');
    return false;
  }
}

  // ✅ Check if user is logged in
  Future<bool> isLoggedIn() async {
    final token = await _storage.getAccessToken();
    final hasToken = token != null && token.isNotEmpty;
    print('🔍 [AUTH] Is logged in? $hasToken');
    return hasToken;
  }

  // ✅ Get current user
  Future<User?> getCurrentUser() async {
    final userData = await _storage.getUserData();
    if (userData != null) {
      return User.fromJson(userData);
    }
    return null;
  }

  // ✅ Initialize - Load token from storage and set to API
  Future<void> initialize() async {
    final accessToken = await _storage.getAccessToken();
    if (accessToken != null && accessToken.isNotEmpty) {
      ApiService().setAuthToken(accessToken);
      print('✅ [AUTH] Token loaded from storage');
    }
  }

  // ✅ Logout
  Future<void> signOut() async {
    try {
      // Optional: Panggil API signout jika ada
      final refreshToken = await _storage.getRefreshToken();
      if (refreshToken != null) {
        await _api.post(
          ApiConfig.signOut,
          data: {'refresh_token': refreshToken},
        );
      }
    } catch (e) {
      print('⚠️ [AUTH] Error during API signout: $e');
    } finally {
      // ✅ Clear ALL storage (termasuk hasSeenIntro!)
      await _storage.clearAll();
      ApiService().removeAuthToken();
      print('✅ [AUTH] User logged out - All data cleared');
    }
  }
}