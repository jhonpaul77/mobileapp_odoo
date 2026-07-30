import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../../config/api_config.dart';
import '../../../../services/api_service.dart';
import '../models/customer_model.dart';

/// Customer Remote DataSource
///
/// Handles all API calls related to customers.
/// Communicates with Odoo ERP API.
class CustomerRemoteDataSource {
  final Dio _dio;

  CustomerRemoteDataSource({Dio? dio}) : _dio = dio ?? ApiService().dio;

  /// Fetches all customers from Odoo API
  ///
  /// Returns list of CustomerModel from API response.
  /// API Response format: Direct array OR wrapped format
  /// Example: [{"id": 1, "name": "Customer", ...}, ...]
  ///     OR: {"Success": true, "Data": [...], "Message": "..."}
  Future<List<CustomerModel>> getCustomers({
    required String db,
    required String apiKey,
  }) async {
    try {
      print('🔄 [CUSTOMER_DS] Fetching customers...');
      print('   DB: $db');
      print('   API Key: ${apiKey.substring(0, 8)}...');

      final response = await _dio.get(
        ApiConfig.getCustomer,
        options: Options(
          headers: ApiConfig.odooApiHeaders(
            db: db,
            apiKey: apiKey,
          ),
        ),
      );

      print('✅ [CUSTOMER_DS] Response received: ${response.statusCode}');
      print('📦 [CUSTOMER_DS] Response type: ${response.data.runtimeType}');

      // Handle different response formats
      dynamic data = response.data;

      // If response is String, parse as JSON
      if (data is String) {
        print('🔄 [CUSTOMER_DS] Parsing JSON string...');
        data = jsonDecode(data);
      }

      // Response as direct array (like Product API)
      if (data is List) {
        print('✅ [CUSTOMER_DS] Customers count: ${data.length}');
        final customers = data
            .map((json) => CustomerModel.fromJson(json as Map<String, dynamic>))
            .toList();
        return customers;
      }
      // Response wrapped in Success/Message/Data
      else if (data is Map<String, dynamic>) {
        if (data.containsKey('Success') && data['Success'] == true) {
          if (data['Data'] is List) {
            final customers = (data['Data'] as List)
                .map((json) =>
                    CustomerModel.fromJson(json as Map<String, dynamic>))
                .toList();
            print(
                '✅ [CUSTOMER_DS] Customers count: ${customers.length} (wrapped format)');
            return customers;
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
            'Unexpected response format: ${data.runtimeType}. Response: $data');
      }
    } on DioException catch (e) {
      print('❌ [CUSTOMER_DS] Dio error: ${e.message}');
      print('   Response: ${e.response?.data}');
      throw Exception(
          'Failed to fetch customers: ${e.response?.data ?? e.message}');
    } catch (e) {
      print('❌ [CUSTOMER_DS] Unexpected error: $e');
      throw Exception('Unexpected error while fetching customers: $e');
    }
  }

  /// Creates a new customer in Odoo API
  ///
  /// Returns CustomerModel of the created customer.
  /// API Response format: {"id": 123} OR {"Success": true, "Data": {...}, "Message": "..."}
  Future<CustomerModel> createCustomer({
    required String db,
    required String apiKey,
    required Map<String, dynamic> data,
  }) async {
    try {
      print('🔄 [CUSTOMER_DS] Creating customer...');
      print('   Data: $data');

      final response = await _dio.post(
        ApiConfig.createCustomer,
        options: Options(
          headers: {
            ...ApiConfig.odooApiHeaders(db: db, apiKey: apiKey),
            'Content-Type': 'application/json',
          },
        ),
        data: data,
      );

      print('✅ [CUSTOMER_DS] Customer created');
      print('📦 [CUSTOMER_DS] Response type: ${response.data.runtimeType}');
      print('📦 [CUSTOMER_DS] Response data: ${response.data}');

      // Handle different response formats
      dynamic responseData = response.data;

      // If response is String, parse as JSON
      if (responseData is String) {
        print('🔄 [CUSTOMER_DS] Parsing JSON string...');
        responseData = jsonDecode(responseData);
        print('📦 [CUSTOMER_DS] Parsed response: $responseData');
      }

      // Response as simple Map with id (new format)
      if (responseData is Map<String, dynamic>) {
        print('📦 [CUSTOMER_DS] Response keys: ${responseData.keys}');

        // If response contains only 'id' (simple response), merge with request data
        if (responseData.containsKey('id') && responseData.keys.length == 1) {
          print(
              '✅ [CUSTOMER_DS] Simple response format - ID: ${responseData['id']}');
          // Merge the ID with the original request data to create full CustomerModel
          final fullData = {
            ...data,
            'id': responseData['id'],
          };
          print(
              '📦 [CUSTOMER_DS] Creating CustomerModel from merged data: $fullData');
          return CustomerModel.fromJson(fullData);
        }

        // If response has more fields, use it directly
        if (responseData.containsKey('id') &&
            responseData.containsKey('name')) {
          print('✅ [CUSTOMER_DS] Full response format');
          return CustomerModel.fromJson(responseData);
        }

        // Handle wrapped response format with Success/Message/Data
        print('📦 [CUSTOMER_DS] Success value: ${responseData['Success']}');

        // Handle Success as boolean or string
        bool isSuccess = false;
        if (responseData['Success'] is bool) {
          isSuccess = responseData['Success'] as bool;
        } else if (responseData['Success'] is String) {
          isSuccess =
              (responseData['Success'] as String).toLowerCase() == 'true';
        }

        if (isSuccess) {
          final customerData = responseData['Data'] as Map<String, dynamic>;
          return CustomerModel.fromJson(customerData);
        } else {
          final errorMsg =
              responseData['Message'] ?? 'Failed to create customer';
          print('❌ [CUSTOMER_DS] API error: $errorMsg');
          throw Exception(errorMsg);
        }
      } else {
        throw Exception(
            'Unexpected response format: ${responseData.runtimeType}. Response: $responseData');
      }
    } on DioException catch (e) {
      print('❌ [CUSTOMER_DS] Dio error: ${e.message}');
      print('   Response: ${e.response?.data}');
      throw Exception(
          'Failed to create customer: ${e.response?.data ?? e.message}');
    } catch (e) {
      print('❌ [CUSTOMER_DS] Unexpected error: $e');
      throw Exception('Unexpected error while creating customer: $e');
    }
  }

  /// Updates an existing customer in Odoo API
  ///
  /// Returns CustomerModel of the updated customer.
  /// API Response format: {"Success": true, "Data": {...}, "Message": "..."}
  Future<CustomerModel> editCustomer({
    required String db,
    required String apiKey,
    required int id,
    required Map<String, dynamic> data,
  }) async {
    try {
      print('🔄 [CUSTOMER_DS] Editing customer $id...');
      print('   Data: $data');

      final response = await _dio.post(
        ApiConfig.editCustomer,
        options: Options(
          headers: {
            ...ApiConfig.odooApiHeaders(db: db, apiKey: apiKey),
            'Content-Type': 'application/json',
          },
        ),
        data: {
          'id': id,
          ...data,
        },
      );

      print('✅ [CUSTOMER_DS] Customer updated');

      // Handle different response formats
      dynamic responseData = response.data;

      // If response is String, parse as JSON
      if (responseData is String) {
        responseData = jsonDecode(responseData);
      }

      // Response wrapped in Success/Message/Data
      if (responseData is Map<String, dynamic>) {
        if (responseData['Success'] == true) {
          final customerData = responseData['Data'] as Map<String, dynamic>;
          return CustomerModel.fromJson(customerData);
        } else {
          throw Exception(
              responseData['Message'] ?? 'Failed to update customer');
        }
      } else {
        throw Exception(
            'Unexpected response format: ${responseData.runtimeType}');
      }
    } on DioException catch (e) {
      print('❌ [CUSTOMER_DS] Dio error: ${e.message}');
      print('   Response: ${e.response?.data}');
      throw Exception(
          'Failed to edit customer: ${e.response?.data ?? e.message}');
    } catch (e) {
      print('❌ [CUSTOMER_DS] Unexpected error: $e');
      throw Exception('Unexpected error while editing customer: $e');
    }
  }
}
