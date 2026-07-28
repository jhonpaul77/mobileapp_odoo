import 'dart:convert' as json_convert;

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

      // Preview response (first 300 chars)
      final responseStr = response.data.toString();
      final preview = responseStr.length > 300
          ? '${responseStr.substring(0, 300)}...'
          : responseStr;
      print('   [SALES_ORDER_REPO] Response preview: $preview');

      // Handle different response formats
      dynamic data = response.data;

      // If response is String, parse as JSON
      if (data is String) {
        print('   [SALES_ORDER_REPO] Response is String, parsing JSON...');
        try {
          data = json_convert.jsonDecode(data);
          print('   [SALES_ORDER_REPO] JSON parsed. Type: ${data.runtimeType}');
        } catch (e) {
          print('   [SALES_ORDER_REPO] JSON parse failed: $e');
          throw Exception(
              'API mengembalikan format tidak valid. Response: $preview');
        }
      }

      // Response should be direct array
      if (data is List) {
        final orders = data
            .map((json) => SalesOrder.fromJson(json as Map<String, dynamic>))
            .toList();

        print('✅ [SALES_ORDER_REPO] Parsed ${orders.length} sales orders');
        return orders;
      }
      // Handle wrapped response format (Success/Message/Data)
      else if (data is Map<String, dynamic>) {
        print('   [SALES_ORDER_REPO] Response is Map, checking format...');

        if (data.containsKey('Success') && data['Success'] == true) {
          if (data['Data'] is List) {
            final orders = (data['Data'] as List)
                .map(
                    (json) => SalesOrder.fromJson(json as Map<String, dynamic>))
                .toList();
            print(
                '✅ [SALES_ORDER_REPO] Parsed ${orders.length} sales orders from wrapped response');
            return orders;
          } else {
            throw Exception(
                'Data field is not a List: ${data['Data'].runtimeType}');
          }
        } else if (data.containsKey('Success') && data['Success'] == false) {
          throw Exception(data['Message'] ?? 'API returned error');
        } else {
          throw Exception('Unexpected Map format. Keys: ${data.keys}');
        }
      } else {
        throw Exception(
            'Unexpected response format: ${data.runtimeType}. Response: $preview');
      }
    } catch (e, stackTrace) {
      print('❌ [SALES_ORDER_REPO] Error: $e');
      print('   Stack trace: $stackTrace');
      rethrow;
    }
  }
}
