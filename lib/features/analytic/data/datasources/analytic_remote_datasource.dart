import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../../services/api_service.dart';
import '../../domain/entities/analytic.dart';

/// AnalyticRemoteDataSource - Data Layer
class AnalyticRemoteDataSource {
  final ApiService _apiService;

  // Cache analytics
  List<Analytic>? _analyticsCache;

  AnalyticRemoteDataSource({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  /// Fetch all analytics from API
  /// Endpoint: GET /get_analytic
  Future<List<Analytic>> getAnalytics({
    required String db,
    required String apiKey,
  }) async {
    // Return cache if available
    if (_analyticsCache != null) {
      print('📦 [ANALYTIC_DATASOURCE] Using cached analytics (${_analyticsCache!.length} items)');
      return _analyticsCache!;
    }

    try {
      print('🔄 [ANALYTIC_DATASOURCE] Fetching analytics...');

      final response = await _apiService.dio.get(
        '/get_analytic',
        options: Options(
          headers: {
            'db': db,
            'api-key': apiKey,
          },
        ),
      );

      print('   [ANALYTIC_DATASOURCE] Response type: ${response.data.runtimeType}');
      print('   [ANALYTIC_DATASOURCE] Response status: ${response.statusCode}');

      dynamic data = response.data;

      // If response is String, parse as JSON
      if (data is String) {
        print('   [ANALYTIC_DATASOURCE] Response is String, parsing JSON...');
        try {
          data = jsonDecode(data);
          print('   [ANALYTIC_DATASOURCE] JSON parsed. Type: ${data.runtimeType}');
        } catch (e) {
          print('   [ANALYTIC_DATASOURCE] JSON parse failed: $e');
          throw Exception('Failed to parse analytics response: $e');
        }
      }

      // Handle direct array response
      if (data is List) {
        final analytics = (data as List)
            .map((json) {
              if (json is Map<String, dynamic>) {
                return Analytic.fromJson(json);
              }
              throw Exception('Invalid item format: ${json.runtimeType}');
            })
            .toList();

        // Cache the result
        _analyticsCache = analytics;

        print('✅ [ANALYTIC_DATASOURCE] Fetched ${analytics.length} analytics');
        return analytics;
      }
      // Handle wrapped response
      else if (data is Map<String, dynamic>) {
        final mapData = data as Map<String, dynamic>;
        
        if (mapData.containsKey('Success') && mapData['Success'] == true && mapData['Data'] is List) {
          final analytics = (mapData['Data'] as List)
              .map((json) => Analytic.fromJson(json as Map<String, dynamic>))
              .toList();
          
          _analyticsCache = analytics;
          print('✅ [ANALYTIC_DATASOURCE] Fetched ${analytics.length} analytics from wrapped response');
          return analytics;
        }
      }

      throw Exception('Invalid response format for analytics: ${data.runtimeType}');
    } catch (e, stackTrace) {
      print('❌ [ANALYTIC_DATASOURCE] Error: $e');
      print('   Stack: $stackTrace');
      rethrow;
    }
  }

  /// Search analytics by name
  Future<List<Analytic>> searchAnalytics({
    required String query,
    required String db,
    required String apiKey,
  }) async {
    final all = await getAnalytics(db: db, apiKey: apiKey);

    if (query.isEmpty) {
      return all;
    }

    final searchLower = query.toLowerCase();
    return all
        .where((analytic) =>
            analytic.name.toLowerCase().contains(searchLower) ||
            analytic.id.toString().contains(searchLower))
        .toList();
  }

  /// Get analytic by ID
  Analytic? getAnalyticById(int id) {
    if (_analyticsCache == null) return null;
    try {
      return _analyticsCache!.firstWhere((a) => a.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Clear cache
  void clearCache() {
    _analyticsCache = null;
    print('🗑️ [ANALYTIC_DATASOURCE] Cache cleared');
  }
}
