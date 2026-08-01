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
      print('   Database: $db');
      print('   API Key: ${apiKey.substring(0, 12)}...');
      print('   Base URL: ${_apiService.dio.options.baseUrl}');
      print('   Endpoint: /get_sale_order');

      final response = await _apiService.dio.get(
        '/get_sale_order',
        options: Options(
          headers: {
            'db': db,
            'api-key': apiKey,
          },
        ),
      );

      print('✅ [SALES_ORDER_REPO] Response received');
      print('   Status: ${response.statusCode}');
      print('   Response type: ${response.data.runtimeType}');

      // ✅ VALIDASI: Cek database dari response header
      final responseDb = response.headers.value('db') ??
          response.headers.value('DB') ??
          response.headers.value('Database');

      if (responseDb != null && responseDb != db) {
        print('⚠️ [SALES_ORDER_REPO] Database mismatch!');
        print('   Expected: $db');
        print('   Received: $responseDb');
        throw Exception('Database tidak sesuai');
      }

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
      print('');
      print('═══════════════════════════════════════════════════════════');
      print('❌ [SALES_ORDER_REPO] ERROR FETCHING SALES ORDERS');
      print('═══════════════════════════════════════════════════════════');
      
      if (e is DioException) {
        print('Error Type: DioException');
        print('Status Code: ${e.response?.statusCode}');
        print('Message: ${e.message}');
        print('Response: ${e.response?.data}');
        print('');
        print('🔐 Credentials Check:');
        print('   Database: $db');
        print('   API Key: ${apiKey.substring(0, 12)}...');
        print('   Base URL: ${_apiService.dio.options.baseUrl}');
        print('');
        
        if (e.response?.statusCode == 400) {
          print('⚠️  HTTP 400 - Invalid Credentials');
          print('   → API Key mungkin expired atau salah');
          print('   → Database name tidak sesuai');
          print('   → Coba: Login ulang untuk refresh token');
        } else if (e.response?.statusCode == 401) {
          print('⚠️  HTTP 401 - Unauthorized');
          print('   → API Key tidak valid');
          print('   → Silakan login ulang');
        } else if (e.response?.statusCode == 404) {
          print('⚠️  HTTP 404 - Endpoint tidak ditemukan');
          print('   → URL server mungkin salah');
        }
      } else {
        print('Error Type: ${e.runtimeType}');
        print('Message: $e');
      }
      
      print('═══════════════════════════════════════════════════════════');
      print('');
      print('   Stack trace: $stackTrace');
      rethrow;
    }
  }
}
