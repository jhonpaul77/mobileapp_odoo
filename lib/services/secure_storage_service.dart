import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

class SecureStorageService {
  static final SecureStorageService _instance =
      SecureStorageService._internal();
  factory SecureStorageService() => _instance;
  SecureStorageService._internal();

  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  // Keys
  static const String _keyAccessToken = 'access_token';
  static const String _keyRefreshToken = 'refresh_token';
  static const String _keyUserData = 'user_data';
  static const String _keyPin = 'user_pin';
  static const String _keyBiometricEnabled = 'biometric_enabled';
  static const String _keyIsFirstLogin = 'is_first_login';
  static const String _keyHasSeenIntro = 'has_seen_intro'; // ✅ BARU

  // === TOKEN MANAGEMENT ===
  Future<void> saveTokens(String accessToken, String refreshToken) async {
    await _storage.write(key: _keyAccessToken, value: accessToken);
    await _storage.write(key: _keyRefreshToken, value: refreshToken);
  }

  Future<String?> getAccessToken() async {
    return await _storage.read(key: _keyAccessToken);
  }

  Future<String?> getRefreshToken() async {
    return await _storage.read(key: _keyRefreshToken);
  }

  // === USER DATA ===
  Future<void> saveUserData(Map<String, dynamic> userData) async {
    await _storage.write(key: _keyUserData, value: jsonEncode(userData));
  }

  Future<Map<String, dynamic>?> getUserData() async {
    final data = await _storage.read(key: _keyUserData);
    if (data != null) {
      return jsonDecode(data);
    }
    return null;
  }

  // === PIN MANAGEMENT ===
  String _hashPin(String pin) {
    final bytes = utf8.encode(pin);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<void> savePin(String pin) async {
    final hashedPin = _hashPin(pin);
    await _storage.write(key: _keyPin, value: hashedPin);
    await _storage.write(key: _keyIsFirstLogin, value: 'false');
  }

  Future<bool> verifyPin(String pin) async {
    final savedPin = await _storage.read(key: _keyPin);
    if (savedPin == null) return false;
    return savedPin == _hashPin(pin);
  }

  Future<bool> isPinSet() async {
    final pin = await _storage.read(key: _keyPin);
    return pin != null;
  }

  Future<String?> getPin() async {
    return await _storage.read(key: _keyPin);
  }

  // === BIOMETRIC ===
  Future<void> setBiometricEnabled(bool enabled) async {
    await _storage.write(key: _keyBiometricEnabled, value: enabled.toString());
  }

  Future<bool> isBiometricEnabled() async {
    final value = await _storage.read(key: _keyBiometricEnabled);
    return value == 'true';
  }

  // === FIRST LOGIN CHECK ===
  Future<bool> isFirstLogin() async {
    final value = await _storage.read(key: _keyIsFirstLogin);
    return value == null || value == 'true';
  }

  // === INTRO CHECK ✅ BARU ===
  Future<void> setHasSeenIntro(bool seen) async {
    await _storage.write(key: _keyHasSeenIntro, value: seen.toString());
  }

  Future<bool> getHasSeenIntro() async {
    final value = await _storage.read(key: _keyHasSeenIntro);
    return value == 'true';
  }

  // === CLEAR ALL ===
  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
