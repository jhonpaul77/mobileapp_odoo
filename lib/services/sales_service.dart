// services/sales_service.dart
import 'dart:convert';

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
      print('🔍 [SALES] Response data type: ${response.data.runtimeType}');

      if (response.statusCode == 200) {
        // Handle case where API returns JSON string instead of parsed JSON
        dynamic ordersData = response.data;

        // If response is a String, try to parse it as JSON
        if (ordersData is String) {
          print('⚠️ [SALES] Response is String, parsing as JSON...');
          try {
            ordersData = jsonDecode(ordersData);
            print(
                '✅ [SALES] JSON parsed successfully, type: ${ordersData.runtimeType}');
          } catch (e) {
            print('❌ [SALES] Failed to parse JSON: $e');
            return {
              'Success': false,
              'Message': 'Invalid JSON response from API',
              'Data': {'items': [], 'total': 0},
            };
          }
        }

        // Now ordersData should be a List
        if (ordersData is! List) {
          print('❌ [SALES] Response is not a List: ${ordersData.runtimeType}');
          return {
            'Success': false,
            'Message': 'Invalid response format from API',
            'Data': {'items': [], 'total': 0},
          };
        }

        final orders = ordersData;
        print('✅ [SALES] Fetched ${orders.length} sale orders');

        // Debug: Print structure of first 2 orders to see actual fields
        if (orders.isNotEmpty) {
          print('🔍 [SALES] Sample order 1 structure:');
          final order1 = orders[0] as Map<String, dynamic>;
          print('   Fields: ${order1.keys.toList()}');
          print('   ID: ${order1['id']}');
          print('   Name: ${order1['name']}');
          print(
              '   partner_id: ${order1['partner_id']} (type: ${order1['partner_id']?.runtimeType})');
          print('   partner_name: ${order1['partner_name']}');

          if (orders.length > 1) {
            print('🔍 [SALES] Sample order 2:');
            final order2 = orders[1] as Map<String, dynamic>;
            print(
                '   partner_id: ${order2['partner_id']} (type: ${order2['partner_id']?.runtimeType})');
          }
        }

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

  // ✅ ODOO: Create sale order
  ///
  /// **Endpoint**: `/create_sale_order`
  /// **Method**: `POST`
  /// **Headers**:
  /// ```
  /// db: demotest
  /// api-key: {api_key}
  /// Content-Type: application/json
  /// ```
  ///
  /// **Request Body**:
  /// ```json
  /// {
  ///   "partner_name": "Customer Name",
  ///   "partner_phone": "+62 812-3456-7890",
  ///   "partner_street": "Address Line 1",
  ///   "partner_street2": "Address Line 2",
  ///   "partner_district": "District Name",
  ///   "partner_city": "City Name",
  ///   "partner_state": "State/Province Name",
  ///   "date_order": "2026-07-29",
  ///   "warehouse_id": 1,
  ///   "kurir_id": 20,
  ///   "awb": "ABC123456",
  ///   "notes": "Order notes",
  ///   "state": "confirm",
  ///   "order_lines": [
  ///     {
  ///       "product_id": 2050,
  ///       "product_uom_qty": 2.0,
  ///       "analytic_distribution": "Channel Name",
  ///       "price_unit": 215000.0
  ///     }
  ///   ]
  /// }
  /// ```
  ///
  /// **Response**: Success/Error message with created order data
  Future<Map<String, dynamic>> createSaleOrder({
    required String partnerName,
    required String partnerPhone,
    required String partnerStreet,
    String? partnerStreet2,
    required String partnerDistrict,
    required String partnerCity,
    required String partnerState,
    required String dateOrder, // Format: "YYYY-MM-DD"
    int? warehouseId, // Optional, API will use default
    int? kurirId,
    String? awb,
    String? notes,
    String state = 'draft', // draft, sent, sale, done, cancel
    required List<Map<String, dynamic>> orderLines,
  }) async {
    try {
      print('📝 [SALES] Creating sale order...');
      print('📝 [SALES] Partner: $partnerName');
      print('📝 [SALES] Order lines: ${orderLines.length} items');

      // Validate order lines
      if (orderLines.isEmpty) {
        return {
          'Success': false,
          'Message': 'Order lines cannot be empty',
        };
      }

      // Build request body
      final requestBody = {
        'partner_name': partnerName,
        'partner_phone': partnerPhone,
        'partner_street': partnerStreet,
        'partner_street2': partnerStreet2 ?? '',
        'partner_district': partnerDistrict,
        'partner_city': partnerCity,
        'partner_state': partnerState,
        'date_order': dateOrder,
        if (warehouseId != null) 'warehouse_id': warehouseId,
        'kurir_id': kurirId ?? false,
        'awb': awb ?? false,
        'notes': notes ?? '',
        'state': state,
        'order_lines': orderLines,
      };

      print('📝 [SALES] Request body: $requestBody');

      final response = await _api.post(
        ApiConfig.createSaleOrder,
        data: requestBody,
      );

      print('📝 [SALES] Response status: ${response.statusCode}');
      print('📝 [SALES] Response data: ${response.data}');
      print('📝 [SALES] Response data type: ${response.data.runtimeType}');

      if (response.statusCode == 200) {
        // Parse response - bisa berupa String JSON atau Map
        dynamic parsedData = response.data;

        if (response.data is String) {
          try {
            parsedData = json.decode(response.data);
            print('📝 [SALES] Parsed JSON: $parsedData');
          } catch (e) {
            print('⚠️ [SALES] Failed to parse JSON: $e');
            // If can't parse, return raw string
            parsedData = {'message': response.data};
          }
        }

        return {
          'Success': true,
          'Message': 'Sale order created successfully',
          'Data': parsedData,
        };
      } else {
        return {
          'Success': false,
          'Message': 'Failed to create sale order',
          'Data': response.data,
        };
      }
    } on DioException catch (e) {
      print('❌ [SALES] Create error: ${e.message}');
      print('❌ [SALES] Response: ${e.response?.data}');

      return {
        'Success': false,
        'Message': e.response?.data['Message'] ??
            e.response?.data['message'] ??
            'Failed to create sale order: ${e.message}',
      };
    } catch (e) {
      print('❌ [SALES] Unexpected error: $e');
      return {
        'Success': false,
        'Message': 'Unexpected error: $e',
      };
    }
  }

  // ✅ ODOO: Edit sale order
  ///
  /// **Endpoint**: `/edit_sale_order`
  /// **Method**: `POST`
  /// **Headers**:
  /// ```
  /// db: demotest
  /// api-key: {api_key}
  /// Content-Type: application/json
  /// ```
  ///
  /// **Request Body**:
  /// ```json
  /// {
  ///   "id": 4223,
  ///   "partner_id": 32763,
  ///   "partner_phone": "+62 812-3456-7890",
  ///   "partner_district": "District Name",
  ///   "partner_city": "City Name",
  ///   "partner_state": "State/Province Name",
  ///   "date_order": "2026-07-29",
  ///   "warehouse_id": 1,
  ///   "kurir_id": 20,
  ///   "awb": "ABC123456",
  ///   "state": "confirm",
  ///   "order_lines": [...]
  /// }
  /// ```
  ///
  /// **Note**: Uses `partner_id` (not `partner_name`) for existing customer
  ///
  /// **Response**: Success/Error message with updated order data
  Future<Map<String, dynamic>> editSaleOrder({
    required int id,
    required int partnerId,
    required String partnerPhone,
    required String partnerDistrict,
    required String partnerCity,
    required String partnerState,
    required String dateOrder, // Format: "YYYY-MM-DD"
    required int warehouseId,
    int? kurirId,
    String? awb,
    String? state,
    required List<Map<String, dynamic>> orderLines,
  }) async {
    try {
      print('📝 [SALES] Editing sale order #$id...');
      print('📝 [SALES] Partner ID: $partnerId');
      print('📝 [SALES] Order lines: ${orderLines.length} items');

      // Validate order lines
      if (orderLines.isEmpty) {
        return {
          'Success': false,
          'Message': 'Order lines cannot be empty',
        };
      }

      // Build request body
      final requestBody = {
        'id': id,
        'partner_id': partnerId,
        'partner_phone': partnerPhone,
        'partner_district': partnerDistrict,
        'partner_city': partnerCity,
        'partner_state': partnerState,
        'date_order': dateOrder,
        'warehouse_id': warehouseId,
        'kurir_id': kurirId ?? false,
        'awb': awb ?? false,
        'state': state ?? 'draft',
        'order_lines': orderLines,
      };

      print('📝 [SALES] Request body: $requestBody');

      final response = await _api.post(
        ApiConfig.editSaleOrder,
        data: requestBody,
      );

      print('📝 [SALES] Response status: ${response.statusCode}');
      print('📝 [SALES] Response data: ${response.data}');

      if (response.statusCode == 200) {
        return {
          'Success': true,
          'Message': 'Sale order updated successfully',
          'Data': response.data,
        };
      } else {
        return {
          'Success': false,
          'Message': 'Failed to update sale order',
          'Data': response.data,
        };
      }
    } on DioException catch (e) {
      print('❌ [SALES] Edit error: ${e.message}');
      print('❌ [SALES] Response: ${e.response?.data}');

      return {
        'Success': false,
        'Message': e.response?.data['Message'] ??
            e.response?.data['message'] ??
            'Failed to update sale order: ${e.message}',
      };
    } catch (e) {
      print('❌ [SALES] Unexpected error: $e');
      return {
        'Success': false,
        'Message': 'Unexpected error: $e',
      };
    }
  }

  // ✅ ODOO: Confirm sale order
  ///
  /// **Endpoint**: `/confirm_order`
  /// **Method**: `PUT`
  /// **Headers**:
  /// ```
  /// db: demotest
  /// api-key: {api_key}
  /// Content-Type: application/json
  /// ```
  ///
  /// **Request Body**:
  /// ```json
  /// {
  ///   "id": 4230
  /// }
  /// ```
  ///
  /// **Response**: Success/Error message
  /// ```json
  /// {
  ///   "Success": true,
  ///   "Message": "Order confirmed",
  ///   "Data": {
  ///     "id": 4230,
  ///     "state": "confirm"
  ///   }
  /// }
  /// ```
  ///
  /// **Notes**:
  /// - Changes order state from `draft` to `confirm`
  /// - Only works on orders with `draft` state
  Future<Map<String, dynamic>> confirmOrder({required int orderId}) async {
    try {
      print('✅ [SALES] Confirming sale order #$orderId...');

      final requestBody = {
        'id': orderId,
      };

      print('📝 [SALES] Request body: $requestBody');

      final response = await _api.put(
        ApiConfig.confirmOrder,
        data: requestBody,
      );

      print('📝 [SALES] Response status: ${response.statusCode}');
      print('📝 [SALES] Response data: ${response.data}');

      if (response.statusCode == 200) {
        return {
          'Success': true,
          'Message': 'Order confirmed successfully',
          'Data': response.data,
        };
      } else {
        return {
          'Success': false,
          'Message': 'Failed to confirm order',
          'Data': response.data,
        };
      }
    } on DioException catch (e) {
      print('❌ [SALES] Confirm error: ${e.message}');
      print('❌ [SALES] Response: ${e.response?.data}');

      return {
        'Success': false,
        'Message': e.response?.data['Message'] ??
            e.response?.data['message'] ??
            'Failed to confirm order: ${e.message}',
      };
    } catch (e) {
      print('❌ [SALES] Unexpected error: $e');
      return {
        'Success': false,
        'Message': 'Unexpected error: $e',
      };
    }
  }
}
