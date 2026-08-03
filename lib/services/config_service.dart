import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import 'secure_storage_service.dart';

/// ✅ ConfigService - Mengelola konfigurasi aplikasi
///
/// Architecture:
/// 1. Default config bundled di APK: assets/config/default_config.json
/// 2. User config di device: ApplicationDocumentsDirectory/config.json
/// 3. First launch: copy default → user config
/// 4. Selanjutnya: selalu baca dari user config
/// 5. User edit: update user config file
///
/// Kenapa tidak pakai SecureStorage?
/// - Database, URL, Company, Theme = BUKAN data sensitif
/// - File JSON lebih mudah dikembangkan (banyak field)
/// - SecureStorage hanya untuk: token, PIN, biometric secret
class ConfigService {
  static final ConfigService _instance = ConfigService._internal();
  factory ConfigService() => _instance;
  ConfigService._internal();

  static const String _configFileName = 'config.json';
  static const String _defaultConfigPath = 'assets/config/default_config.json';

  /// Get path to user config file di ApplicationDocumentsDirectory
  Future<String> _getConfigFilePath() async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/$_configFileName';
  }

  /// Load default config from assets (bundled in APK)
  Future<Map<String, dynamic>> _loadDefaultConfig() async {
    try {
      final jsonString = await rootBundle.loadString(_defaultConfigPath);
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      // Fallback jika file assets tidak ada
      return {
        'database': '',
        'url': '',
        'company': '',
        'language': 'id',
        'theme': 'light',
        'api_version': '1.0',
        'timeout': 30,
        'warehouse': '',
        'printer': '',
        'currency': 'IDR',
      };
    }
  }

  /// Check if user config file exists
  Future<bool> _configFileExists() async {
    final filePath = await _getConfigFilePath();
    final file = File(filePath);
    return await file.exists();
  }

  /// Copy default config to user config (first launch only)
  Future<void> _copyDefaultToUserConfig() async {
    final defaultConfig = await _loadDefaultConfig();
    final filePath = await _getConfigFilePath();
    final file = File(filePath);

    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(defaultConfig),
      flush: true,
    );
  }

  /// Initialize config - called once on app start
  /// Jika belum ada user config, copy dari default
  Future<void> initialize() async {
    final exists = await _configFileExists();

    if (!exists) {
      // First launch - copy default config
      await _copyDefaultToUserConfig();
    }
  }

  /// Load current config from user config file
  Future<Map<String, dynamic>> load() async {
    try {
      // Ensure config exists
      final exists = await _configFileExists();
      if (!exists) {
        await _copyDefaultToUserConfig();
      }

      // Read user config file
      final filePath = await _getConfigFilePath();
      final file = File(filePath);
      final jsonString = await file.readAsString();

      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      // Fallback to default config jika error
      return await _loadDefaultConfig();
    }
  }

  /// Save config to user config file
  Future<void> save(Map<String, dynamic> config) async {
    try {
      final filePath = await _getConfigFilePath();
      final file = File(filePath);

      await file.writeAsString(
        const JsonEncoder.withIndent('  ').convert(config),
        flush: true,
      );
    } catch (e) {
      throw Exception('Failed to save config: $e');
    }
  }

  /// Update specific field in config
  Future<void> update(String key, dynamic value) async {
    final config = await load();
    config[key] = value;
    await save(config);
  }

  /// Get specific field from config
  Future<dynamic> get(String key) async {
    final config = await load();
    return config[key];
  }

  /// Reset config to default
  Future<void> resetToDefault() async {
    await _copyDefaultToUserConfig();
  }

  // ✅ Convenience getters untuk field yang sering dipakai
  Future<String> getDatabase() async {
    final value = await get('database');
    return value?.toString() ?? '';
  }

  Future<String> getUrl() async {
    final value = await get('url');
    return value?.toString() ?? '';
  }

  Future<String> getCompany() async {
    final value = await get('company');
    return value?.toString() ?? '';
  }

  Future<String> getLanguage() async {
    final value = await get('language');
    return value?.toString() ?? 'id';
  }

  Future<String> getTheme() async {
    final value = await get('theme');
    return value?.toString() ?? 'light';
  }

  Future<int> getTimeout() async {
    final value = await get('timeout');
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 30;
    return 30;
  }

  // ✅ Convenience method untuk update server settings
  // ⚠️ Auto-logout karena API key dari server lama tidak valid di server baru
  Future<void> updateServerSettings({
    required String database,
    required String url,
  }) async {
    final config = await load();
    final oldUrl = config['url'] as String?;
    
    // Check if URL changed
    if (oldUrl != null && oldUrl != url) {
      print('🔄 [CONFIG] Server URL changed!');
      print('   Old: $oldUrl');
      print('   New: $url');
      print('⚠️  [CONFIG] Auto-logout karena server berubah');
      
      // Auto clear old credentials
      final storage = SecureStorageService();
      await storage.clearAll();
      
      print('✅ [CONFIG] Old credentials cleared');
    }
    
    config['database'] = database;
    config['url'] = url;
    await save(config);
    
    print('✅ [CONFIG] Server settings updated');
    print('   Database: $database');
    print('   URL: $url');
  }
}
