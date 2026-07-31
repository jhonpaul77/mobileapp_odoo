import 'package:flutter/foundation.dart';
import 'package:pintarx/services/connectivity_service.dart';
import 'dart:async';

/// ConnectivityProvider - Track app-wide internet connectivity status
///
/// SIMPLE and BATTERY-EFFICIENT approach:
/// - Listens to internet_connection_checker_plus status stream
/// - Only emits when actual connection status changes
/// - NO active checking until user does something
/// - When updateCustomer() is called, it checks internet on-demand
class ConnectivityProvider extends ChangeNotifier {
  final ConnectivityService _connectivityService = ConnectivityService();
  
  bool _isOnline = true;
  StreamSubscription? _connectivitySubscription;

  bool get isOnline => _isOnline;
  bool get isOffline => !_isOnline;

  ConnectivityProvider() {
    _initialize();
  }

  void _initialize() {
    // Listen to connectivity changes only
    // This is passive - no battery cost until connection actually changes
    _connectivitySubscription = 
        _connectivityService.onConnectivityChanged.listen((isOnline) {
      if (_isOnline != isOnline) {
        _isOnline = isOnline;
        print('🌐 [CONNECTIVITY_PROVIDER] Status: ${_isOnline ? 'ONLINE ✅' : 'OFFLINE ❌'}');
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }
}
