import 'dart:convert' as json_convert;

import 'package:dio/dio.dart';

import '../../../../services/api_service.dart';
import '../../domain/entities/customer.dart';

/// CustomerRepository - Data Layer
///
/// Handles data fetching from Odoo API
/// Endpoint: GET /get_customer
class CustomerRepository {
  final ApiService _apiService;

  CustomerRepository({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  /// Fetch customers from Odoo API
  ///
  /// API Spec:
  /// - Endpoint: GET /get_customer
  /// - Headers: db, api-key
  /// - Response: Direct array (NOT wrapped)
  Future<List<Customer>> getCustomers({
    required String db,
    required String apiKey,
  }) async {
    try {
      print('🔄 [CUSTOMER_REPO] Fetching customers...');
      print('   [CUSTOMER_REPO] Database: $db');
      print('   [CUSTOMER_REPO] API Key: ${apiKey.substring(0, 8)}...');

      final response = await _apiService.dio.get(
        '/get_customer',
        options: Options(
          headers: {
            'db': db,
            'api-key': apiKey,
          },
        ),
      );

      print('   [CUSTOMER_REPO] Response received');
      print('   [CUSTOMER_REPO] Response type: ${response.data.runtimeType}');

      // Preview response (first 300 chars)
      final responseStr = response.data.toString();
      final preview = responseStr.length > 300
          ? '${responseStr.substring(0, 300)}...'
          : responseStr;
      print('   [CUSTOMER_REPO] Response preview: $preview');

      // Handle different response formats
      dynamic data = response.data;

      // If response is String, parse as JSON
      if (data is String) {
        print('   [CUSTOMER_REPO] Response is String, parsing JSON...');
        try {
          data = json_convert.jsonDecode(data);
          print('   [CUSTOMER_REPO] JSON parsed. Type: ${data.runtimeType}');
        } catch (e) {
          print('   [CUSTOMER_REPO] JSON parse failed: $e');
          throw Exception(
              'API mengembalikan format tidak valid. Response: $preview');
        }
      }

      // Response should be direct array (like Product API)
      if (data is List) {
        final customers = data
            .map((json) => Customer.fromJson(json as Map<String, dynamic>))
            .toList();

        print('✅ [CUSTOMER_REPO] Parsed ${customers.length} customers');
        return customers;
      }
      // Handle wrapped response format (Success/Message/Data)
      else if (data is Map<String, dynamic>) {
        print('   [CUSTOMER_REPO] Response is Map, checking format...');

        if (data.containsKey('Success') && data['Success'] == true) {
          if (data['Data'] is List) {
            final customers = (data['Data'] as List)
                .map((json) => Customer.fromJson(json as Map<String, dynamic>))
                .toList();
            print(
                '✅ [CUSTOMER_REPO] Parsed ${customers.length} customers from wrapped response');
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
            'Unexpected response format: ${data.runtimeType}. Response: $preview');
      }
    } catch (e, stackTrace) {
      print('❌ [CUSTOMER_REPO] Error: $e');
      print('   Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Create customer (for future implementation)
  Future<Customer> createCustomer({
    required String db,
    required String apiKey,
    required Map<String, dynamic> data,
  }) async {
    try {
      print('🔄 [CUSTOMER_REPO] Creating customer...');
      print('   [CUSTOMER_REPO] Data: $data');

      final response = await _apiService.dio.post(
        '/create_customer',
        options: Options(
          headers: {
            'db': db,
            'api-key': apiKey,
            'Content-Type': 'application/json',
          },
        ),
        data: data,
      );

      print('✅ [CUSTOMER_REPO] Customer created');
      print('   [CUSTOMER_REPO] Response type: ${response.data.runtimeType}');
      print('   [CUSTOMER_REPO] Response: ${response.data}');

      // Handle different response formats
      dynamic responseData = response.data;

      // If response is String, parse as JSON
      if (responseData is String) {
        print('   [CUSTOMER_REPO] Response is String, parsing JSON...');
        try {
          responseData = json_convert.jsonDecode(responseData);
          print(
              '   [CUSTOMER_REPO] JSON parsed. Type: ${responseData.runtimeType}');
        } catch (e) {
          print('   [CUSTOMER_REPO] JSON parse failed: $e');
          throw Exception('API mengembalikan format tidak valid');
        }
      }

      // Response wrapped in Success/Message/Data
      if (responseData is Map<String, dynamic>) {
        print('   [CUSTOMER_REPO] Success: ${responseData['Success']}');
        print('   [CUSTOMER_REPO] Message: ${responseData['Message']}');

        if (responseData['Success'] == true) {
          final customerData = responseData['Data'] as Map<String, dynamic>;
          print('   [CUSTOMER_REPO] Customer data: $customerData');
          return Customer.fromJson(customerData);
        } else {
          final errorMessage =
              responseData['Message'] ?? 'Failed to create customer';
          print('   [CUSTOMER_REPO] API Error: $errorMessage');
          throw Exception(errorMessage);
        }
      } else {
        throw Exception(
            'Unexpected response format: ${responseData.runtimeType}');
      }
    } catch (e, stackTrace) {
      print('❌ [CUSTOMER_REPO] Create error: $e');
      print('   Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Edit customer (for future implementation)
  Future<Customer> editCustomer({
    required String db,
    required String apiKey,
    required int id,
    required Map<String, dynamic> data,
  }) async {
    try {
      print('🔄 [CUSTOMER_REPO] Editing customer $id...');

      final response = await _apiService.dio.post(
        '/edit_customer',
        options: Options(
          headers: {
            'db': db,
            'api-key': apiKey,
            'Content-Type': 'application/json',
          },
        ),
        data: {
          'id': id,
          ...data,
        },
      );

      print('✅ [CUSTOMER_REPO] Customer updated');

      // Response wrapped in Success/Message/Data
      if (response.data['Success'] == true) {
        return Customer.fromJson(response.data['Data']);
      } else {
        throw Exception(
            response.data['Message'] ?? 'Failed to update customer');
      }
    } catch (e) {
      print('❌ [CUSTOMER_REPO] Edit error: $e');
      rethrow;
    }
  }
}
