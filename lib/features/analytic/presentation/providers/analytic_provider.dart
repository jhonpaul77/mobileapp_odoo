import 'package:flutter/foundation.dart';

import '../../../../services/config_service.dart';
import '../../../../services/secure_storage_service.dart';
import '../../data/datasources/analytic_remote_datasource.dart';
import '../../domain/entities/analytic.dart';

/// AnalyticProvider - Presentation Layer
class AnalyticProvider extends ChangeNotifier {
  final AnalyticRemoteDataSource _datasource;
  final SecureStorageService _storage;
  final ConfigService _configService;

  AnalyticProvider({
    AnalyticRemoteDataSource? datasource,
    SecureStorageService? storage,
    ConfigService? configService,
  })  : _datasource = datasource ?? AnalyticRemoteDataSource(),
        _storage = storage ?? SecureStorageService(),
        _configService = configService ?? ConfigService();

  List<Analytic> _analytics = [];
  List<Analytic> _filteredAnalytics = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = '';

  List<Analytic> get analytics => _filteredAnalytics.isEmpty && _searchQuery.isEmpty
      ? _analytics
      : _filteredAnalytics;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;
  bool get isEmpty => analytics.isEmpty;
  int get count => analytics.length;

  /// Fetch analytics from API
  Future<void> fetchAnalytics() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      print('🔄 [ANALYTIC_PROVIDER] Fetching analytics...');

      final config = await _configService.load();
      final database = config['database'] as String?;
      final apiKey = await _storage.getAccessToken();

      if (database == null || database.isEmpty) {
        throw Exception('Database belum diatur.');
      }

      if (apiKey == null || apiKey.isEmpty) {
        throw Exception('API key not found. Please login.');
      }

      final fetchedAnalytics = await _datasource.getAnalytics(
        db: database,
        apiKey: apiKey,
      );

      _analytics = fetchedAnalytics;
      _filteredAnalytics = fetchedAnalytics;
      _isLoading = false;

      print('✅ [ANALYTIC_PROVIDER] Analytics loaded: ${_analytics.length}');
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      print('❌ [ANALYTIC_PROVIDER] Error: $_errorMessage');
      notifyListeners();
    }
  }

  /// Search analytics by name
  void search(String query) {
    _searchQuery = query.trim().toLowerCase();

    if (_searchQuery.isEmpty) {
      _filteredAnalytics = _analytics;
    } else {
      _filteredAnalytics = _analytics
          .where((analytic) =>
              analytic.name.toLowerCase().contains(_searchQuery) ||
              analytic.id.toString().contains(_searchQuery))
          .toList();
    }

    notifyListeners();
  }

  /// Get analytic by ID
  Analytic? getAnalyticById(int id) {
    try {
      return _analytics.firstWhere((a) => a.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Clear search
  void clearSearch() {
    _searchQuery = '';
    _filteredAnalytics = _analytics;
    notifyListeners();
  }

  /// Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
