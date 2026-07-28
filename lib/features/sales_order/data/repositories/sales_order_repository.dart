import 'package:dio/dio.dart';

import '../../../../services/api_service.dart';
import '../../domain/entities/sales_order.dart';

/// SalesOrderRepository - Data Layer
///
/// Handles data fetching from Odoo API
/// Endpoint: GET /get_sale_order
class SalesOrderRepository {
  final ApiService _apiService;

  SalesOrderRepository({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  /// Fetch sales orders from Odoo API
  ///
  /// API Spec:
  /// - Endpoint: GET /get_sale_order
  /// - Headers: db, api-key
  /// - Response: Direct array (NOT wrapped)
  Future<List<SalesOrder>> getSalesOrders({
    required String db,
    required String apiKey,
  }) async {
    try {
      print('🔄 [SALES_ORDER_REPO] Fetching sales orders...');
      print('   [SALES_ORDER_REPO] Database: $db');
      print('   [SALES_ORDER_REPO] API Key: ${apiKey.substring(0, 8)}...');

      final response = await _apiService.dio.get(
        '/get_sale_order',
        options: Options(
          headers: {
            'db': db,
            'api-key': apiKey,
          },
        ),
      );

      print('   [SALES_ORDER_REPO] Response received');
      print(
          '   [SALES_ORDER_REPO] Response type: ${response.data.runtimeType}');

      // Response is direct array
      if (response.data is List) {
        final orders = (response.data as List)
            .map((json) => SalesOrder.fromJson(json as Map<String, dynamic>))
            .toList();

        print('✅ [SALES_ORDER_REPO] Parsed ${orders.length} sales orders');
        return orders;
      } else {
        throw Exception(
            'Unexpected response format: ${response.data.runtimeType}');
      }
    } catch (e, stackTrace) {
      print('❌ [SALES_ORDER_REPO] Error: $e');
      print('   Stack trace: $stackTrace');
      rethrow;
    }
  }
}
