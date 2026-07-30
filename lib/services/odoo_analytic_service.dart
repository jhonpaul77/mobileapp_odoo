// services/odoo_analytic_service.dart
import 'package:dio/dio.dart';

import '../config/api_config.dart';
import 'api_service.dart';

/// Service untuk mengelola Analytic Accounts dari Odoo
///
/// Analytic Account digunakan untuk tracking sales channel/platform
/// dalam sales order (e.g., "CleanerClin Shopee", "Tokopedia", dll)
class OdooAnalyticService {
  final _api = ApiService().dio;

  /// Get all analytic accounts
  ///
  /// **Endpoint**: `/get_analytic`
  /// **Method**: `GET`
  /// **Headers**:
  /// ```
  /// db: demotest
  /// api-key: {api_key}
  /// ```
  ///
  /// **Response**: Direct array of analytic accounts
  /// ```json
  /// [
  ///   {
  ///     "id": 1,
  ///     "name": "CleanerClin Shopee",
  ///     "code": "CC-SHOPEE"
  ///   },
  ///   {
  ///     "id": 2,
  ///     "name": "Tokopedia",
  ///     "code": "TOKPED"
  ///   }
  /// ]
  /// ```
  Future<Map<String, dynamic>> getAnalytics() async {
    try {
      print('🔍 [ANALYTIC] Fetching analytic accounts from Odoo...');
      print('🔍 [ANALYTIC] URL: ${ApiConfig.baseUrl}${ApiConfig.getAnalytic}');

      final response = await _api.get(ApiConfig.getAnalytic);

      print('🔍 [ANALYTIC] Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        // Response is direct array (like products and customers)
        final analytics = response.data as List;
        print('✅ [ANALYTIC] Fetched ${analytics.length} analytic accounts');

        return {
          'Success': true,
          'Message': 'Analytic accounts fetched successfully',
          'Data': analytics,
        };
      } else {
        print('⚠️ [ANALYTIC] Unexpected status: ${response.statusCode}');
        return {
          'Success': false,
          'Message': 'Failed to fetch analytic accounts',
          'Data': [],
        };
      }
    } on DioException catch (e) {
      print('❌ [ANALYTIC] Fetch error: ${e.message}');
      print('❌ [ANALYTIC] Status: ${e.response?.statusCode}');

      return {
        'Success': false,
        'Message': e.response?.data['Message'] ??
            'Failed to fetch analytic accounts: ${e.message}',
        'Data': [],
      };
    } catch (e) {
      print('❌ [ANALYTIC] Unexpected error: $e');
      return {
        'Success': false,
        'Message': 'Unexpected error: $e',
        'Data': [],
      };
    }
  }

  /// Get single analytic account by ID (client-side filter)
  Future<Map<String, dynamic>> getAnalyticById(int analyticId) async {
    try {
      final result = await getAnalytics();

      if (result['Success'] == true) {
        final analytics = result['Data'] as List;
        final analytic = analytics.firstWhere(
          (a) => a['id'] == analyticId,
          orElse: () => null,
        );

        if (analytic != null) {
          return {
            'Success': true,
            'Message': 'Analytic account found',
            'Data': analytic,
          };
        } else {
          return {
            'Success': false,
            'Message': 'Analytic account not found',
          };
        }
      }

      return result;
    } catch (e) {
      print('❌ [ANALYTIC] Get by ID error: $e');
      return {
        'Success': false,
        'Message': 'Failed to get analytic account: $e',
      };
    }
  }

  /// Get analytic accounts by name (client-side search)
  Future<Map<String, dynamic>> searchAnalytics(String query) async {
    try {
      final result = await getAnalytics();

      if (result['Success'] == true) {
        final analytics = result['Data'] as List;
        final filtered = analytics.where((a) {
          final name = (a['name'] as String?)?.toLowerCase() ?? '';
          final code = (a['code'] as String?)?.toLowerCase() ?? '';
          final searchQuery = query.toLowerCase();
          return name.contains(searchQuery) || code.contains(searchQuery);
        }).toList();

        return {
          'Success': true,
          'Message': 'Search completed',
          'Data': filtered,
        };
      }

      return result;
    } catch (e) {
      print('❌ [ANALYTIC] Search error: $e');
      return {
        'Success': false,
        'Message': 'Failed to search analytic accounts: $e',
        'Data': [],
      };
    }
  }
}
