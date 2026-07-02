import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';
import 'secure_storage_service.dart';

class BiometricService {
  static final BiometricService _instance = BiometricService._internal();
  factory BiometricService() => _instance;
  BiometricService._internal();

  final LocalAuthentication _localAuth = LocalAuthentication();
  final _storage = SecureStorageService();

  // ✅ [UPDATE] — Lebih konsisten: gabung cek support & availability
  Future<bool> isBiometricAvailable() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isSupported = await _localAuth.isDeviceSupported();
      return canCheck && isSupported;
    } on PlatformException catch (e) {
      print('Biometric check error: ${e.message}');
      return false;
    }
  }

  // ✅ [TETAP] — Dibiarkan untuk backward compatibility
  Future<bool> isDeviceSupported() async {
    try {
      return await _localAuth.isDeviceSupported();
    } on PlatformException {
      return false;
    }
  }

  // ✅ [TETAP] — Dapatkan tipe biometric
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } on PlatformException {
      return [];
    }
  }

  // ✅ [UPDATE] — lebih aman: gunakan biometricOnly = true
  Future<bool> authenticate({
    String reason = 'Gunakan biometrik untuk membuka aplikasi',
  }) async {
    try {
      final isAvailable = await isBiometricAvailable();
      if (!isAvailable) {
        print('Biometric not available');
        return false;
      }

      return await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: true, // ✅ hanya biometrik, tidak fallback ke PIN
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );
    } on PlatformException catch (e) {
      print('Biometric authentication error: ${e.code} - ${e.message}');
      return false;
    } catch (e) {
      print('Biometric error: $e');
      return false;
    }
  }

  // ✅ [TETAP] — Buat UI label dinamis
  Future<String> getBiometricTypeString() async {
    final biometrics = await getAvailableBiometrics();

    if (biometrics.contains(BiometricType.face)) {
      return 'Face ID';
    } else if (biometrics.contains(BiometricType.fingerprint)) {
      return 'Fingerprint';
    } else if (biometrics.contains(BiometricType.iris)) {
      return 'Iris';
    }
    return 'Biometric';
  }

  // ✅ [TETAP] — Integrasi ke SecureStorageService
  Future<void> setBiometricEnabled(bool enabled) async {
    await _storage.setBiometricEnabled(enabled);
  }

  Future<bool> isBiometricEnabled() async {
    return await _storage.isBiometricEnabled();
  }
}
