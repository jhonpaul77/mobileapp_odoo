// services/sales_service.dart
import 'package:dio/dio.dart';

import '../config/api_config.dart';
import '../models/sales/sales.dart';
import '../models/sales/sales_response.dart';
import 'api_service.dart';

class SalesService {
  final _api = ApiService().dio;

  // ✅ ODOO: Get all sale orders
  ///
  /// **Endpoint**: `/get_sale_order`
  /// **Method**: `GET`
  /// **Headers**:
  /// ```
  /// db: demotest
  /// api-key: {api_key}
  /// ```
  ///
  /// **Response**: Direct array of sale orders
  /// ```json
  /// [
  ///   {
  ///     "id": 1,
  ///     "name": "SO001",
  ///     "partner_id": 123,
  ///     "partner_name": "Customer Name",
  ///     "date_order": "2026-07-29",
  ///     "state": "sale",
  ///     "amount_total": 1000000.0,
  ///     "order_line": [...]
  ///   }
  /// ]
  /// ```
  Future<Map<String, dynamic>> getSaleOrders() async {
    try {
      print('🔍 [SALES] Fetching sale orders from Odoo...');
      print('🔍 [SALES] URL: ${ApiConfig.baseUrl}${ApiConfig.getSaleOrder}');

      final response = await _api.get(ApiConfig.getSaleOrder);

      print('🔍 [SALES] Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        // Response is direct array (like products and customers)
        final orders = response.data as List;
        print('✅ [SALES] Fetched ${orders.length} sale orders');

        return {
          'Success': true,
          'Message': 'Sale orders fetched successfully',
          'Data': {
            'items': orders,
            'total': orders.length,
          },
        };
      } else {
        print('⚠️ [SALES] Unexpected status: ${response.statusCode}');
        return {
          'Success': false,
          'Message': 'Failed to fetch sale orders',
          'Data': {'items': [], 'total': 0},
        };
      }
    } on DioException catch (e) {
      print('❌ [SALES] Fetch error: ${e.message}');
      print('❌ [SALES] Status: ${e.response?.statusCode}');

      return {
        'Success': false,
        'Message': e.response?.data['Message'] ??
            'Failed to fetch sale orders: ${e.message}',
        'Data': {'items': [], 'total': 0},
      };
    } catch (e) {
      print('❌ [SALES] Unexpected error: $e');
      return {
        'Success': false,
        'Message': 'Unexpected error: $e',
        'Data': {'items': [], 'total': 0},
      };
    }
  }

  // ✅ ODOO: Get single sale order by ID (client-side filter)
  Future<Map<String, dynamic>> getSaleOrderById(int orderId) async {
    try {
      final result = await getSaleOrders();

      if (result['Success'] == true) {
        final orders = result['Data']['items'] as List;
        final order = orders.firstWhere(
          (o) => o['id'] == orderId,
          orElse: () => null,
        );

        if (order != null) {
          return {
            'Success': true,
            'Message': 'Sale order found',
            'Data': order,
          };
        } else {
          return {
            'Success': false,
            'Message': 'Sale order not found',
          };
        }
      }

      return result;
    } catch (e) {
      print('❌ [SALES] Get by ID error: $e');
      return {
        'Success': false,
        'Message': 'Failed to get sale order: $e',
      };
    }
  }

  // ✅ LEGACY: Create sales
  Future<SalesResponse> createSales(Sales data) async {
    try {
      final response = await _api.post(
        ApiConfig.sales,
        data: data.toJson(),
      );

      return SalesResponse.fromJson(response.data);
    } on DioException catch (e) {
      return SalesResponse(
        success: false,
        message: e.response?.data['Message'] ?? e.message ?? 'Error',
      );
    } catch (e) {
      return SalesResponse(success: false, message: e.toString());
    }
  }
}
