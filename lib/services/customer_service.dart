import 'package:dio/dio.dart';
import 'package:pintarx/models/customer/customer_response.dart';

import '../config/api_config.dart';
import 'api_service.dart';
import 'config_service.dart';
import 'secure_storage_service.dart';

class CustomerService {
  final _api = ApiService().dio;

  // ✅ FETCH - Get all customers with pagination
  Future<CustomerResponse> fetchCustomers({
    int length = 10,
    int start = 0,
  }) async {
    try {
      print('🔍 [CUSTOMER] Fetching customers...');
      print(
          '🔍 [CUSTOMER] URL: ${ApiConfig.baseUrl}${ApiConfig.customerFetch}');
      print('🔍 [CUSTOMER] Params: length=$length, start=$start');

      // ✅ Fetch list customer dengan pagination
      final response = await _api.get(
        ApiConfig.customerFetch,
        queryParameters: {
          'length': length,
          'start': start,
        },
      );

      print('🔍 [CUSTOMER] Response status: ${response.statusCode}');

      final customerResponse = CustomerResponse.fromJsonList(response.data);

      if (customerResponse.success) {
        print(
            '✅ [CUSTOMER] Fetched ${customerResponse.data?.length ?? 0} customers');
      } else {
        print('⚠️ [CUSTOMER] Fetch warning: ${customerResponse.message}');
      }

      return customerResponse;
    } on DioException catch (e) {
      print('❌ [CUSTOMER] Fetch error: ${e.message}');
      print('❌ [CUSTOMER] Status: ${e.response?.statusCode}');

      return CustomerResponse(
        success: false,
        message: e.response?.data['Message'] ??
            'Failed to fetch customers: ${e.message}',
      );
    } catch (e) {
      print('❌ [CUSTOMER] Unexpected error: $e');
      return CustomerResponse(
        success: false,
        message: 'Unexpected error: $e',
      );
    }
  }

  /// Get all customers (Odoo API format - direct array)
  ///
  /// Returns standardized response format:
  /// ```dart
  /// {
  ///   'Success': bool,
  ///   'Message': String,
  ///   'Data': {
  ///     'items': List<dynamic>,
  ///     'total': int
  ///   }
  /// }
  /// ```
  Future<Map<String, dynamic>> getCustomers() async {
    try {
      print('🔍 [CUSTOMER] Getting customers from Odoo API...');

      // Import yang diperlukan
      final secureStorage = SecureStorageService();
      final configService = ConfigService();

      // Get db dan api-key dari storage
      final db = await configService.getDatabase();
      final apiKey = await secureStorage.getAccessToken();

      if (apiKey == null || apiKey.isEmpty) {
        print('❌ [CUSTOMER] No API key found - user not logged in');
        return {
          'Success': false,
          'Message': 'Not authenticated - please login first',
          'Data': {
            'items': [],
            'total': 0,
          },
        };
      }

      print('🔍 [CUSTOMER] Using DB: $db');
      print('🔍 [CUSTOMER] Endpoint: ${ApiConfig.getCustomer}');
      print('🔍 [CUSTOMER] API Key: ${apiKey.substring(0, 10)}...');

      // Call Odoo API endpoint with required headers
      final response = await _api.get(
        ApiConfig.getCustomer,
        options: Options(
          headers: {
            'db': db,
            'api-key': apiKey,
          },
        ),
      );

      print('✅ [CUSTOMER] Response received');
      print('   Response type: ${response.data.runtimeType}');
      print('   Response data: ${response.data}');

      // Handle response - bisa berupa List langsung atau wrapped object
      List<dynamic> customers = [];

      if (response.data is List) {
        // Direct array response
        customers = response.data as List;
        print('   Format: Direct array with ${customers.length} items');
      } else if (response.data is Map) {
        // Wrapped response
        final dataMap = response.data as Map<String, dynamic>;
        if (dataMap.containsKey('data')) {
          customers = dataMap['data'] as List;
        } else if (dataMap.containsKey('Data')) {
          customers = dataMap['Data'] as List;
        } else if (dataMap.containsKey('items')) {
          customers = dataMap['items'] as List;
        }
        print('   Format: Wrapped object with ${customers.length} items');
      }

      print('✅ [CUSTOMER] Loaded ${customers.length} customers');

      return {
        'Success': true,
        'Message': 'Success',
        'Data': {
          'items': customers,
          'total': customers.length,
        },
      };
    } on DioException catch (e) {
      print('❌ [CUSTOMER] DioException: ${e.message}');
      print('❌ [CUSTOMER] Status code: ${e.response?.statusCode}');
      print('❌ [CUSTOMER] Response data: ${e.response?.data}');

      String errorMessage = 'Network error';

      if (e.response?.data != null) {
        if (e.response!.data is Map) {
          final errorMap = e.response!.data as Map<String, dynamic>;
          errorMessage = errorMap['Message'] ??
              errorMap['message'] ??
              errorMap['error'] ??
              'API error: ${e.response?.statusCode}';
        } else {
          errorMessage = e.response!.data.toString();
        }
      }

      return {
        'Success': false,
        'Message': errorMessage,
        'Data': {
          'items': [],
          'total': 0,
        },
      };
    } catch (e, stackTrace) {
      print('❌ [CUSTOMER] Unexpected error: $e');
      print('❌ [CUSTOMER] Stack trace: $stackTrace');
      return {
        'Success': false,
        'Message': 'Unexpected error: $e',
        'Data': {
          'items': [],
          'total': 0,
        },
      };
    }
  }

  // ✅ GET - Get single customer by ID
  // Future<CustomerResponse> getCustomerDetail(String customerId) async {
  //   try {
  //     print('🔍 [CUSTOMER] Getting detail for: $customerId');

  //     // Coba endpoint dengan path param
  //     final response = await _api.get(
  //       '${ApiConfig.customerFetch}/$customerId',
  //     );

  //     final customerResponse = CustomerResponse.fromJsonSingle(response.data);

  //     if (customerResponse.success) {
  //       print('✅ [CUSTOMER] Detail loaded: ${customerResponse.singleData?.nama}');
  //     }

  //     return customerResponse;
  //   } on DioException catch (e) {
  //     print('❌ [CUSTOMER] Detail error: ${e.message}');
  //     print('❌ [CUSTOMER] Status: ${e.response?.statusCode}');

  //     // Jika 403/404, return error dengan pesan yang jelas
  //     if (e.response?.statusCode == 403 || e.response?.statusCode == 404) {
  //       return CustomerResponse(
  //         success: false,
  //         message: 'Endpoint detail customer tidak tersedia atau tidak memiliki akses',
  //       );
  //     }

  //     return CustomerResponse(
  //       success: false,
  //       message: e.response?.data['Message'] ?? 'Failed to get customer detail',
  //     );
  //   }
  // }
// ✅ GET - Get single customer by ID
  Future<CustomerResponse> getCustomerDetail(String customerId) async {
    try {
      print('🔍 [CUSTOMER] Getting detail for: $customerId');

      final response = await _api.get(
        '${ApiConfig.customerGet}/$customerId',
      );

      print('🔍 [CUSTOMER] Response status: ${response.statusCode}');
      print('🔍 [CUSTOMER] Response data: ${response.data}');

      if (response.statusCode == 200 && response.data["Success"] == true) {
        return CustomerResponse.fromJsonSingle(response.data);
      } else {
        return CustomerResponse(
          success: false,
          message: response.data["Message"] ?? 'Gagal mengambil data',
        );
      }
    } on DioException catch (e) {
      print('❌ [CUSTOMER] Detail error: ${e.message}');
      return CustomerResponse(
        success: false,
        message:
            e.response?.data["Message"] ?? 'Terjadi kesalahan (DioException)',
      );
    } catch (e) {
      print('❌ [CUSTOMER] Unexpected error: $e');
      return CustomerResponse(
        success: false,
        message: 'Unexpected error: $e',
      );
    }
  }

  // ✅ CREATE - Add new customer
  Future<CustomerResponse> createCustomer({
    required String nama,
    required String email,
    required String noTelp,
    required bool isActive,
    String? catatan,
  }) async {
    try {
      print('🔍 [CUSTOMER] Creating customer: $nama');
      print(
          '🔍 [CUSTOMER] URL: ${ApiConfig.baseUrl}${ApiConfig.customerCreate}');

      final response = await _api.post(
        ApiConfig.customerCreate,
        data: {
          'nama': nama,
          'email': email,
          'no_telp': noTelp,
          'is_active': isActive,
          'catatan': catatan?.isNotEmpty == true ? catatan : '-',
        },
      );

      print('🔍 [CUSTOMER] Create response: ${response.data}');

      final customerResponse = CustomerResponse.fromJsonSingle(response.data);

      if (customerResponse.success) {
        print('✅ [CUSTOMER] Created successfully');
      } else {
        print('⚠️ [CUSTOMER] Create warning: ${customerResponse.message}');
      }

      return customerResponse;
    } on DioException catch (e) {
      print('❌ [CUSTOMER] Create error: ${e.message}');
      print('❌ [CUSTOMER] Status: ${e.response?.statusCode}');

      return CustomerResponse(
        success: false,
        message: e.response?.data['Message'] ??
            'Failed to create customer: ${e.message}',
      );
    } catch (e) {
      print('❌ [CUSTOMER] Unexpected error: $e');
      return CustomerResponse(
        success: false,
        message: 'Unexpected error: $e',
      );
    }
  }

  // ✅ UPDATE - Edit existing customer
  Future<CustomerResponse> updateCustomer({
    required String id,
    required String nama,
    required String email,
    required String noTelp,
    required bool isActive,
    String? catatan,
  }) async {
    try {
      print('🔍 [CUSTOMER] Updating customer: $id');
      print(
          '🔍 [CUSTOMER] URL: ${ApiConfig.baseUrl}${ApiConfig.customerUpdate}');

      final response = await _api.put(
        ApiConfig.customerUpdate,
        data: {
          'id': id,
          'nama': nama,
          'email': email,
          'no_telp': noTelp,
          'is_active': isActive,
          'catatan': catatan?.isNotEmpty == true ? catatan : '-',
        },
      );

      print('🔍 [CUSTOMER] Update response: ${response.data}');

      final customerResponse = CustomerResponse.fromJsonSingle(response.data);

      if (customerResponse.success) {
        print('✅ [CUSTOMER] Updated successfully');
      } else {
        print('⚠️ [CUSTOMER] Update warning: ${customerResponse.message}');
      }

      return customerResponse;
    } on DioException catch (e) {
      print('❌ [CUSTOMER] Update error: ${e.message}');
      print('❌ [CUSTOMER] Status: ${e.response?.statusCode}');

      return CustomerResponse(
        success: false,
        message: e.response?.data['Message'] ??
            'Failed to update customer: ${e.message}',
      );
    } catch (e) {
      print('❌ [CUSTOMER] Unexpected error: $e');
      return CustomerResponse(
        success: false,
        message: 'Unexpected error: $e',
      );
    }
  }

  // ✅ GET SINGLE CUSTOMER - Odoo API format
  /// Get single customer by ID from Odoo `/get_customer/{id}` endpoint
  /// 
  /// **Returns**: Customer object with all details
  Future<Map<String, dynamic>> getCustomerDetailOdoo({
    required int customerId,
  }) async {
    try {
      print('🔍 [CUSTOMER] Getting customer detail #$customerId from Odoo API...');

      final secureStorage = SecureStorageService();
      final configService = ConfigService();

      final db = await configService.getDatabase();
      final apiKey = await secureStorage.getAccessToken();

      if (apiKey == null || apiKey.isEmpty) {
        print('❌ [CUSTOMER] No API key found');
        return {
          'Success': false,
          'Message': 'Not authenticated - please login first',
          'Data': null,
        };
      }

      print('🔍 [CUSTOMER] Using DB: $db');
      print('🔍 [CUSTOMER] Endpoint: ${ApiConfig.getCustomer}/$customerId');

      final response = await _api.get(
        '${ApiConfig.getCustomer}/$customerId',
        options: Options(
          headers: {
            'db': db,
            'api-key': apiKey,
          },
        ),
      );

      print('✅ [CUSTOMER] Response received');
      print('   Response status: ${response.statusCode}');
      print('   Response data: ${response.data}');

      if (response.statusCode == 200) {
        return {
          'Success': true,
          'Message': 'Success',
          'Data': response.data,
        };
      } else {
        return {
          'Success': false,
          'Message': 'Failed to get customer detail',
          'Data': null,
        };
      }
    } on DioException catch (e) {
      print('❌ [CUSTOMER] DioException: ${e.message}');
      print('❌ [CUSTOMER] Status code: ${e.response?.statusCode}');
      print('❌ [CUSTOMER] Response data: ${e.response?.data}');

      return {
        'Success': false,
        'Message': e.response?.data['Message'] ??
            e.response?.data['message'] ??
            'Failed to get customer detail: ${e.message}',
        'Data': null,
      };
    } catch (e) {
      print('❌ [CUSTOMER] Unexpected error: $e');
      return {
        'Success': false,
        'Message': 'Unexpected error: $e',
        'Data': null,
      };
    }
  }
  /// Edit customer via Odoo `/edit_customer` endpoint
  /// 
  /// **Endpoint**: `/edit_customer`
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
  ///   "id": 32763,
  ///   "name": "Customer Name",
  ///   "email": "email@example.com",
  ///   "phone": "+62 812-3456-7890",
  ///   "street": "Address Line 1",
  ///   "street2": "Address Line 2",
  ///   "zip": "12345",
  ///   "state_id": 1,
  ///   "city_id": 2,
  ///   "district_id": 3
  /// }
  /// ```
  Future<Map<String, dynamic>> editCustomerOdoo({
    required int id,
    required String name,
    String? email,
    String? phone,
    String? street,
    String? street2,
    String? zip,
    int? stateId,
    int? cityId,
    int? districtId,
  }) async {
    try {
      print('📝 [CUSTOMER] Editing customer #$id via Odoo API...');

      // Get db dan api-key dari storage
      final secureStorage = SecureStorageService();
      final configService = ConfigService();

      final db = await configService.getDatabase();
      final apiKey = await secureStorage.getAccessToken();

      if (apiKey == null || apiKey.isEmpty) {
        print('❌ [CUSTOMER] No API key found');
        return {
          'Success': false,
          'Message': 'Not authenticated - please login first',
        };
      }

      // Build request body with non-null fields
      final requestBody = {
        'id': id,
        'name': name,
        if (email != null && email.isNotEmpty) 'email': email,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
        if (street != null && street.isNotEmpty) 'street': street,
        if (street2 != null && street2.isNotEmpty) 'street2': street2,
        if (zip != null && zip.isNotEmpty) 'zip': zip,
        if (stateId != null) 'state_id': stateId,
        if (cityId != null) 'city_id': cityId,
        if (districtId != null) 'district_id': districtId,
      };

      print('📝 [CUSTOMER] Request body: $requestBody');

      final response = await _api.post(
        ApiConfig.editCustomer,
        data: requestBody,
        options: Options(
          headers: {
            'db': db,
            'api-key': apiKey,
          },
        ),
      );

      print('📝 [CUSTOMER] Response status: ${response.statusCode}');
      print('📝 [CUSTOMER] Response data: ${response.data}');

      if (response.statusCode == 200) {
        return {
          'Success': true,
          'Message': 'Customer updated successfully',
          'Data': response.data,
        };
      } else {
        return {
          'Success': false,
          'Message': 'Failed to update customer',
          'Data': response.data,
        };
      }
    } on DioException catch (e) {
      print('❌ [CUSTOMER] Edit error: ${e.message}');
      print('❌ [CUSTOMER] Response: ${e.response?.data}');

      return {
        'Success': false,
        'Message': e.response?.data['Message'] ??
            e.response?.data['message'] ??
            'Failed to edit customer: ${e.message}',
      };
    } catch (e) {
      print('❌ [CUSTOMER] Unexpected error: $e');
      return {
        'Success': false,
        'Message': 'Unexpected error: $e',
      };
    }
  }

  // ✅ DELETE - Remove customer
  Future<CustomerResponse> deleteCustomer(String customerId) async {
    try {
      print('🔍 [CUSTOMER] Deleting customer: $customerId');
      print(
          '🔍 [CUSTOMER] URL: ${ApiConfig.baseUrl}${ApiConfig.customerFetch}/$customerId');

      final response = await _api.delete(
        '${ApiConfig.customerFetch}/$customerId',
      );

      print('🔍 [CUSTOMER] Delete response: ${response.data}');

      final customerResponse = CustomerResponse.fromJsonNoData(response.data);

      if (customerResponse.success) {
        print('✅ [CUSTOMER] Deleted successfully');
      } else {
        print('⚠️ [CUSTOMER] Delete warning: ${customerResponse.message}');
      }

      return customerResponse;
    } on DioException catch (e) {
      print('❌ [CUSTOMER] Delete error: ${e.message}');
      print('❌ [CUSTOMER] Status: ${e.response?.statusCode}');

      return CustomerResponse(
        success: false,
        message: e.response?.data['Message'] ??
            'Failed to delete customer: ${e.message}',
      );
    } catch (e) {
      print('❌ [CUSTOMER] Unexpected error: $e');
      return CustomerResponse(
        success: false,
        message: 'Unexpected error: $e',
      );
    }
  }
}
