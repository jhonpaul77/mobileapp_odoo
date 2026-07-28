import 'dart:convert';

import 'package:dio/dio.dart';

import '../config/api_config.dart';
import '../models/auth/auth_response.dart';
import '../models/auth/user.dart';
import 'api_service.dart';
import 'secure_storage_service.dart';

class AuthService {
  final _api = ApiService().dio;
  final _storage = SecureStorageService();

  // ========================================
  // 🔐 ODOO AUTHENTICATION
  // ========================================

  /// Login menggunakan Odoo Connect API
  /// @param db - Database name (e.g., "demotest")
  /// @param username - Username/login (e.g., "jiman")
  /// @param password - Password (e.g., "merdeka")
  Future<AuthResponse> signIn(
      String db, String username, String password) async {
    try {
      print('🔄 [AUTH] Attempting Odoo login...');
      print('   DB: $db, User: $username');

      final response = await _api.get(
        ApiConfig.odooConnect,
        options: Options(
          headers: ApiConfig.odooAuthHeaders(
            db: db,
            login: username,
            password: password,
          ),
        ),
      );

      print('✅ [AUTH] Response received: ${response.statusCode}');
      print('📦 [AUTH] Response type: ${response.data.runtimeType}');
      print('📦 [AUTH] Response data: ${response.data}');

      // ✅ Parse response - handle both String and Map
      Map<String, dynamic> jsonData;
      if (response.data is String) {
        // Response is JSON string, parse it
        print('🔄 [AUTH] Parsing JSON string response...');
        jsonData = json.decode(response.data);
      } else if (response.data is Map<String, dynamic>) {
        // Response is already a Map
        jsonData = response.data;
      } else {
        throw Exception(
            'Unexpected response type: ${response.data.runtimeType}');
      }

      print('✅ [AUTH] Parsed JSON: $jsonData');

      final authResponse = AuthResponse.fromJson(jsonData);

      if (authResponse.success && authResponse.data != null) {
        // Simpan tokens
        await _storage.saveTokens(
          authResponse.data!.accessToken,
          authResponse.data!.refreshToken,
        );

        // Simpan user data dengan database name untuk future requests
        final userData = {
          'username': username,
          'odoo_db': db, // ✅ Key yang benar: 'odoo_db'
          // Add more fields as they come from Odoo response
        };
        await _storage.saveUserData(userData);

        // Set token di API Service
        ApiService().setAuthToken(authResponse.data!.accessToken);

        print('✅ [AUTH] Login successful');
        print('   Saved DB: $db');
      } else {
        print('❌ [AUTH] Login failed: ${authResponse.message}');
      }

      return authResponse;
    } on DioException catch (e) {
      print('❌ [AUTH] Login failed: ${e.message}');
      print('   Response: ${e.response?.data}');
      return AuthResponse(
        success: false,
        message: e.response?.data['Message'] ?? e.message ?? 'Login failed',
      );
    } catch (e) {
      print('❌ [AUTH] Unexpected error: $e');
      return AuthResponse(
        success: false,
        message: 'Unexpected error: $e',
      );
    }
  }

// ✅ Refresh Access Token
  // Note: Update this when Odoo refresh token endpoint is discovered
  Future<bool> refreshAccessToken() async {
    try {
      final accessToken = await _storage.getAccessToken();
      final refreshToken = await _storage.getRefreshToken();

      if (accessToken == null || refreshToken == null) {
        print('❌ [AUTH] Missing access or refresh token');
        return false;
      }

      print('🔄 [AUTH] Refreshing token...');
      print('⚠️  [AUTH] Note: Odoo refresh endpoint TBD - using placeholder');

      // Pakai Dio baru tanpa interceptor biar ga loop
      final dio = Dio(BaseOptions(baseUrl: ApiConfig.baseUrl));

      final response = await dio.post(
        ApiConfig.refreshToken, // TBD: Update when Odoo endpoint known
        data: {'refresh_token': refreshToken},
        options: Options(
          headers: {
            'accept': 'application/json',
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $accessToken',
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
