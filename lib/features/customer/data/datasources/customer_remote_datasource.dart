import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../../config/api_config.dart';
import '../../../../services/api_service.dart';
import '../models/customer_model.dart';

/// Customer Remote DataSource
///
/// Handles all API calls related to customers.
/// Communicates with Odoo ERP API.
/// Implements pagination to fetch all customers.
class CustomerRemoteDataSource {
  final Dio _dio;

  CustomerRemoteDataSource({Dio? dio}) : _dio = dio ?? ApiService().dio;

  /// Fetches all customers from Odoo API with pagination
  ///
  /// Uses pagination to fetch all customers since API has default limit.
  /// Loops through pages until no more data returned.
  /// 
  /// Returns list of CustomerModel from API response.
  /// API Response format: Direct array OR wrapped format
  /// 
  /// Optional [onProgressUpdate] callback is called after each page is fetched
  /// with (currentCount, totalFetched) to show real-time progress
  Future<List<CustomerModel>> getCustomers({
    required String db,
    required String apiKey,
    int? limit,
    Function(int currentCount, int totalFetched)? onProgressUpdate,
  }) async {
    try {
      print('🔄 [CUSTOMER_DS] Fetching ALL customers with pagination...');
      print('   DB: $db');
      print('   API Key: ${apiKey.substring(0, 8)}...');

      final allCustomers = <CustomerModel>[];
      const pageSize = 2000; // Try limit=2000 (between 1005 and 1984)
      int pageNum = 1;

      // Single request with limit to get all customers at once
      print('   [CUSTOMER_DS] Fetching ALL customers in single request with limit=$pageSize');

      final headers = {
        'db': db,
        'api-key': apiKey,
        'order': 'id DESC',
        'limit': pageSize.toString(),
      };

      print('   [CUSTOMER_DS] Headers (only): db=$db, api-key=${apiKey.substring(0, 8)}..., order=id DESC, limit=$pageSize');

      final response = await _dio.get(
        ApiConfig.getCustomer,
        options: Options(
          headers: headers,
          extra: {'skipAuthInterceptor': true}, // Skip the TokenInterceptor
        ),
      );

      print('✅ [CUSTOMER_DS] Page $pageNum received: ${response.statusCode}');
      print('   [CUSTOMER_DS] Request URL: ${response.requestOptions.uri}');

      // Handle different response formats
      dynamic data = response.data;

      // If response is String, parse as JSON
      if (data is String) {
        print('   [CUSTOMER_DS] Parsing JSON string...');
        data = jsonDecode(data);
      }

      List<dynamic> itemsList = [];

      // Response as direct array (like Product API)
      if (data is List) {
        itemsList = data;
      }
      // Response wrapped in Success/Message/Data
      else if (data is Map<String, dynamic>) {
        if (data.containsKey('Success') && data['Success'] == true) {
          if (data['Data'] is List) {
            itemsList = data['Data'] as List;
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
            'Unexpected response format: ${data.runtimeType}');
      }

      // Convert to models
      final pageCustomers = itemsList
          .map((json) {
        try {
          return CustomerModel.fromJson(json as Map<String, dynamic>);
        } catch (e) {
          print('❌ [CUSTOMER_DS] Error parsing item: $e');
          print('   Item data: $json');
          return null;
        }
      })
          .whereType<CustomerModel>()
          .toList();
      
      print(
          '   ✅ [CUSTOMER_DS] Received: ${pageCustomers.length} items (parsed from ${itemsList.length} total)');
      
      if (pageCustomers.length < itemsList.length) {
        print('   ⚠️ [CUSTOMER_DS] Failed to parse ${itemsList.length - pageCustomers.length} items');
      }
      
      allCustomers.addAll(pageCustomers);

      // Call progress callback
      onProgressUpdate?.call(pageNum, allCustomers.length);

      print(
          '✅ [CUSTOMER_DS] Pagination complete. Total customers: ${allCustomers.length}');
      return allCustomers;
    } on DioException catch (e) {
      print('❌ [CUSTOMER_DS] Dio error: ${e.message}');
      print('   Response: ${e.response?.data}');
      print('   Request URL: ${e.requestOptions.uri}');
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
  Future<CustomerModel> createCustomer({
    required String db,
    required String apiKey,
    required Map<String, dynamic> data,
  }) async {
    try {
      print('🔄 [CUSTOMER_DS] Creating customer...');
      print('   DB: $db');
      print('   Data: $data');

      final headers = ApiConfig.odooApiHeaders(
        db: db,
        apiKey: apiKey,
      );

      final response = await _dio.post(
        ApiConfig.createCustomer,
        options: Options(
          headers: headers,
          contentType: Headers.jsonContentType,
        ),
        data: data,
      );

      print('✅ [CUSTOMER_DS] Response received: ${response.statusCode}');
      print('📦 [CUSTOMER_DS] Response data: ${response.data}');

      // Handle different response formats
      dynamic responseData = response.data;

      if (responseData is String) {
        print('   [CUSTOMER_DS] Response is String, parsing JSON...');
        try {
          responseData = jsonDecode(responseData);
          print('   [CUSTOMER_DS] Parsed to: $responseData');
        } catch (e) {
          print('   ⚠️ [CUSTOMER_DS] Failed to parse JSON: $e');
          throw Exception('Invalid response format from server');
        }
      }

      // Now responseData should be a Map
      if (responseData is Map<String, dynamic>) {
        print('   [CUSTOMER_DS] Response is Map');
        
        // Check if response has Success field
        if (responseData.containsKey('Success')) {
          if (responseData['Success'] == true) {
            final customerData = responseData['Data'] as Map<String, dynamic>;
            print('✅ [CUSTOMER_DS] Success response, extracting Data');
            return CustomerModel.fromJson(customerData);
          } else {
            throw Exception(
                responseData['Message'] ?? 'Failed to create customer');
          }
        }
        // If no Success field, assume the response IS the customer data directly
        else if (responseData.containsKey('id')) {
          print('✅ [CUSTOMER_DS] Direct customer response (has id)');
          return CustomerModel.fromJson(responseData);
        }
        // Try to parse as customer anyway
        else {
          print('✅ [CUSTOMER_DS] Trying to parse as CustomerModel');
          return CustomerModel.fromJson(responseData);
        }
      } else {
        throw Exception(
            'Unexpected response format: ${responseData.runtimeType}');
      }
    } on DioException catch (dioError) {
      // Extract error message dari response text jika ada
      String errorMsg = 'Gagal membuat customer';
      
      if (dioError.response?.data != null) {
        final responseData = dioError.response!.data;
        
        // Jika response text (string)
        if (responseData is String && responseData.isNotEmpty) {
          final rawMsg = responseData.trim();
          
          // Parse pesan dari server dan buat lebih user-friendly
          if (rawMsg.contains('phone') && rawMsg.contains('already')) {
            errorMsg = '⚠️ Nomor telepon sudah terdaftar di sistem';
          } else if (rawMsg.contains('email') && rawMsg.contains('already')) {
            errorMsg = '⚠️ Email sudah terdaftar di sistem';
          } else if (rawMsg.contains('name') && rawMsg.contains('required')) {
            errorMsg = '⚠️ Nama customer wajib diisi';
          } else if (rawMsg.contains('already')) {
            errorMsg = '⚠️ Data sudah terdaftar: $rawMsg';
          } else if (rawMsg.isNotEmpty) {
            // Gunakan pesan asli dari server jika tidak cocok pattern di atas
            errorMsg = '⚠️ $rawMsg';
          }
          
          print('❌ [CUSTOMER_DS] Create error (from response text): $errorMsg');
        }
        // Jika response data (map)
        else if (responseData is Map<String, dynamic>) {
          final msg = responseData['message'] ?? 
                     responseData['Message'] ?? 
                     responseData['error'] ?? 
                     'Gagal membuat customer';
          
          // Parse message dari map juga
          if (msg.toString().contains('phone')) {
            errorMsg = '⚠️ Nomor telepon sudah terdaftar di sistem';
          } else if (msg.toString().contains('email')) {
            errorMsg = '⚠️ Email sudah terdaftar di sistem';
          } else {
            errorMsg = '⚠️ $msg';
          }
          
          print('❌ [CUSTOMER_DS] Create error (from response data): $errorMsg');
        }
      } else {
        // DioException tapi tidak ada response data
        if (dioError.message?.contains('Connection refused') ?? false) {
          errorMsg = '❌ Tidak dapat terhubung ke server. Periksa koneksi internet Anda';
        } else if (dioError.message?.contains('timed out') ?? false) {
          errorMsg = '⏱️ Koneksi timeout. Server tidak merespons, coba lagi';
        } else {
          errorMsg = '❌ Gagal membuat customer: ${dioError.message}';
        }
        print('❌ [CUSTOMER_DS] DioException (no response): $errorMsg');
      }
      
      throw Exception(errorMsg);
    } catch (e) {
      print('❌ [CUSTOMER_DS] Create error: $e');
      final errorMsg = '❌ Gagal membuat customer: $e';
      throw Exception(errorMsg);
    }
  }

  /// Edits an existing customer in Odoo API
  ///
  /// Returns CustomerModel of the updated customer.
  Future<CustomerModel> editCustomer({
    required String db,
    required String apiKey,
    required int id,
    required Map<String, dynamic> data,
  }) async {
    try {
      print('🔄 [CUSTOMER_DS] Editing customer $id...');
      print('   DB: $db');
      print('   Data: $data');

      final headers = ApiConfig.odooApiHeaders(
        db: db,
        apiKey: apiKey,
      );

      final response = await _dio.post(
        ApiConfig.editCustomer,
        options: Options(
          headers: headers,
          contentType: Headers.jsonContentType,
        ),
        data: {
          'id': id,
          ...data,
        },
      );

      print('✅ [CUSTOMER_DS] Response received: ${response.statusCode}');
      print('📦 [CUSTOMER_DS] Response data: ${response.data}');

      // Handle different response formats
      dynamic responseData = response.data;

      if (responseData is String) {
        print('   [CUSTOMER_DS] Parsing JSON string...');
        responseData = jsonDecode(responseData);
      }

      if (responseData is Map<String, dynamic>) {
        // Check for Success flag
        if (responseData.containsKey('Success')) {
          if (responseData['Success'] == true) {
            // Success response - check for Data field
            if (responseData.containsKey('Data')) {
              final customerData = responseData['Data'];
              if (customerData is Map<String, dynamic>) {
                print('✅ [CUSTOMER_DS] Successfully parsed customer data');
                return CustomerModel.fromJson(customerData);
              } else {
                print('⚠️ [CUSTOMER_DS] Data field is not a Map: ${customerData.runtimeType}');
                throw Exception('Data field has unexpected format');
              }
            } else {
              // Some APIs might not return Data field but just Success: true
              print('✅ [CUSTOMER_DS] Success: true (no Data field, using original customer)');
              // Return a minimal customer model with just the ID
              return CustomerModel(
                id: id,
                name: data['name'] as String? ?? 'Updated',
                email: data['email'] as String?,
                phone: data['phone'] as String?,
                userId: null,
                street: data['street'] as String?,
                street2: data['street2'] as String?,
                districtId: data['district_id'] as int?,
                cityId: data['city_id'] as int?,
                stateId: data['state_id'] as int?,
                zip: data['zip'] as String?,
                countryId: data['country_id'] as int?,
              );
            }
          } else {
            // Success: false - API error
            final message = responseData['Message'] ?? 'Failed to update customer';
            print('❌ [CUSTOMER_DS] API returned Success: false - $message');
            throw Exception(message);
          }
        } else {
          // No Success field - try to parse as direct customer data
          print('⚠️ [CUSTOMER_DS] No Success field found, treating response as direct customer data');
          try {
            return CustomerModel.fromJson(responseData);
          } catch (parseError) {
            print('❌ [CUSTOMER_DS] Failed to parse response as customer: $parseError');
            throw Exception('Unexpected API response format: $responseData');
          }
        }
      } else {
        throw Exception(
            'Unexpected response format: ${responseData.runtimeType}');
      }
    } on DioException catch (e) {
      print('❌ [CUSTOMER_DS] Dio error: ${e.message}');
      print('   Status code: ${e.response?.statusCode}');
      print('   Response: ${e.response?.data}');
      throw Exception('API request failed: ${e.response?.data ?? e.message}');
    } catch (e) {
      print('❌ [CUSTOMER_DS] Edit error: $e');
      throw Exception('Failed to edit customer: $e');
    }
  }
}
