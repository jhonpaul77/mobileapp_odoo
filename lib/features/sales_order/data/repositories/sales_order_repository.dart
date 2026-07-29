import 'dart:convert' as json_convert;

import 'package:dio/dio.dart';

import '../../../../config/api_config.dart';
import '../../../../services/api_service.dart';
import '../../domain/entities/sales_order.dart';

/// SalesOrderRepository - Data Layer
class SalesOrderRepository {
  final ApiService _apiService;

  SalesOrderRepository({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  /// Fetch sales orders from Odoo API
  Future<List<SalesOrder>> getSalesOrders({
    required String db,
    required String apiKey,
  }) async {
    try {
      print('🔄 [SALES_ORDER_REPO] Fetching sales orders...');

      final response = await _apiService.dio.get(
        '/get_sale_order',
        options: Options(
          headers: {
            'db': db,
            'api-key': apiKey,
          },
        ),
      );

      print('   [SALES_ORDER_REPO] Response type: ${response.data.runtimeType}');

      dynamic data = response.data;

      // If response is String, parse as JSON
      if (data is String) {
        data = json_convert.jsonDecode(data);
      }

      // Response should be direct array
      if (data is List) {
        final orders = data
            .map((json) => SalesOrder.fromJson(json as Map<String, dynamic>))
            .toList();

        print('✅ [SALES_ORDER_REPO] Parsed ${orders.length} sales orders');
        return orders;
      }
      // Handle wrapped response
      else if (data is Map<String, dynamic>) {
        if (data.containsKey('Success') && data['Success'] == true && data['Data'] is List) {
          final orders = (data['Data'] as List)
              .map((json) => SalesOrder.fromJson(json as Map<String, dynamic>))
              .toList();
          print('✅ [SALES_ORDER_REPO] Parsed ${orders.length} sales orders');
          return orders;
        }
      }

      throw Exception('Unexpected response format: ${data.runtimeType}');
    } catch (e) {
      print('❌ [SALES_ORDER_REPO] Error: $e');
      rethrow;
    }
  }

  /// Edit (save) a sales order
  Future<bool> editSalesOrder({
    required String db,
    required String apiKey,
    required SalesOrder order,
  }) async {
    try {
      print('🔄 [SALES_ORDER_REPO] Editing sales order ID: ${order.id}');

      // Build request body
      final body = _buildEditOrderBody(order);
      print('   [SALES_ORDER_REPO] Sending body');

      final response = await _apiService.dio.post(
        ApiConfig.editSalesOrder,
        data: body,
        options: Options(
          headers: {
            'db': db,
            'api-key': apiKey,
          },
        ),
      );

      print('   [SALES_ORDER_REPO] Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        print('✅ [SALES_ORDER_REPO] Sales order saved successfully');
        return true;
      } else {
        throw Exception('API returned status ${response.statusCode}');
      }
    } catch (e) {
      print('❌ [SALES_ORDER_REPO] Error saving sales order: $e');
      rethrow;
    }
  }

  /// Build request body for edit sales order
  Map<String, dynamic> _buildEditOrderBody(SalesOrder order) {
    return {
      'id': order.id,
      'partner_id': order.customerId,
      'partner_phone': _extractPhone(order.partnerName),
      'partner_district': order.district ?? '',
      'partner_city': order.city ?? '',
      'partner_state': '',
      'date_order': order.dateOrder,
      'warehouse_id': order.warehouseId,
      'kurir_id': order.kurirId,
      'awb': order.awbNumber ?? '',
      'state': order.state,
      'order_lines': order.orderLines
          .map((line) => {
                'product_id': line.productIdValue,
                'product_uom_qty': line.productUomQty,
                'analytic_distribution': line.analyticDistribution ?? false,
                'price_unit': line.priceUnit,
              })
          .toList(),
    };
  }

  /// Extract phone from partner name format "Name (phone)"
  String _extractPhone(String? partnerName) {
    if (partnerName == null || partnerName.isEmpty) return '';
    
    final regex = RegExp(r'\(([^)]+)\)');
    final match = regex.firstMatch(partnerName);
    return match?.group(1) ?? '';
  }
}
