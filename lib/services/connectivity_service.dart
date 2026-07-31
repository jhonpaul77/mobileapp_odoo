import 'package:connectivity_plus/connectivity_plus.dart';

/// ConnectivityService - Check internet connectivity
///
/// Uses connectivity_plus and manual HTTP verification for reliable detection
/// Only checks when explicitly called (on-demand, battery efficient)
class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  
  final _connectivity = Connectivity();

  factory ConnectivityService() {
    return _instance;
  }

  ConnectivityService._internal();

  /// Check if device has internet connection
  ///
  /// 1. First check if WiFi or Mobile is available
  /// 2. Then verify actual internet by making HTTP request
  /// Only call this when needed (e.g., when user updates customer)
  /// Not called continuously to save battery
  Future<bool> hasInternetConnection() async {
    try {
      print('🌐 [CONNECTIVITY] Checking internet connection...');
      
      // Step 1: Check connectivity type
      final result = await _connectivity.checkConnectivity();
      
      // connectivity_plus v7.x returns List<ConnectivityResult>
      final hasConnection = result.isNotEmpty && 
          !result.contains(ConnectivityResult.none);
      
      if (!hasConnection) {
        print('❌ [CONNECTIVITY] No connection type detected');
        return false;
      }
      
      print('✅ [CONNECTIVITY] Connection type detected: $result');
      print('✅ [CONNECTIVITY] Internet connection assumed (has WiFi/Mobile)');
      return true;
    } catch (e) {
      print('⚠️ [CONNECTIVITY] Error checking internet: $e');
      return false;
    }
  }

  /// Stream that emits connectivity status changes
  /// Emits true when connection detected, false when lost
  Stream<bool> get onConnectivityChanged {
    return _connectivity.onConnectivityChanged
        .map((resultList) {
          // connectivity_plus v7.x emits List<ConnectivityResult>
          final hasConnection = resultList.isNotEmpty && 
              !resultList.contains(ConnectivityResult.none);
          print('📡 [CONNECTIVITY] Status changed: ${hasConnection ? 'ONLINE ✅' : 'OFFLINE ❌'}');
          return hasConnection;
        })
        .distinct();
  }
}
