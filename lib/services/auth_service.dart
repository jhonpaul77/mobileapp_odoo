import 'dart:convert';

import 'package:dio/dio.dart';

import '../config/api_config.dart';
import '../models/auth/auth_response.dart';
import '../models/auth/user.dart';
import 'api_service.dart';
import 'secure_storage_service.dart';
import 'local_database/database_helper.dart';

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

      // Check if user is switching (different user logged in before)
      final previousUser = await _storage.getUserData();
      final previousUsername = previousUser?['username'] as String?;
      
      if (previousUsername != null && previousUsername != username) {
        print('⚠️ [AUTH] User switch detected ($previousUsername → $username)');
        print('🔄 [AUTH] Clearing old user data from local database...');
        await DatabaseHelper().clearAll();
        print('✅ [AUTH] Old user data cleared');
      }

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
      print('📋 [AUTH] Available fields in response: ${jsonData.keys.toList()}');

      final authResponse = AuthResponse.fromJson(jsonData);

      if (authResponse.success && authResponse.data != null) {
        // Simpan tokens
        await _storage.saveTokens(
          authResponse.data!.accessToken,
          authResponse.data!.refreshToken,
        );

        // ✅ Simpan user data dengan user_id untuk pixel tracking
        // Try to get user_id from response, fallback to hash of username
        int userId = jsonData['user_id'] as int? ?? 
                     jsonData['id'] as int? ??
                     jsonData['uid'] as int? ??
                     username.hashCode.abs(); // Fallback: hash username
        
        final userData = {
          'username': username,
          'odoo_db': db,
          'user_id': userId,
        };
        await _storage.saveUserData(userData);

        // Set token di API Service
        ApiService().setAuthToken(authResponse.data!.accessToken);

        print('✅ [AUTH] Login successful');
        print('   Saved DB: $db');
        print('   Saved Username: $username');
        print('   Saved User ID: $userId (source: ${jsonData.containsKey('user_id') ? 'user_id' : jsonData.containsKey('id') ? 'id' : jsonData.containsKey('uid') ? 'uid' : 'username_hash'})');
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
      // Step 1: Clear local database
      print('🔄 [AUTH] Clearing local database...');
      await DatabaseHelper().clearAll();
      print('✅ [AUTH] Local database cleared');

      // Step 2: Optional API signout
      final refreshToken = await _storage.getRefreshToken();
      if (refreshToken != null) {
        await _api.post(
          ApiConfig.signOut,
          data: {'refresh_token': refreshToken},
        );
      }
    } catch (e) {
      print('⚠️ [AUTH] Error during logout: $e');
    } finally {
      // Step 3: Clear storage (credentials, tokens, user data)
      await _storage.clearAll();
      ApiService().removeAuthToken();
      print('✅ [AUTH] User logged out - All data cleared (Database + Storage)');
    }
  }
}
