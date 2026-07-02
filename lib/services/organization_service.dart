import 'package:dio/dio.dart';
import 'package:pintarx/models/organization/organization.dart';
import 'package:pintarx/models/organization/organization_response.dart';
import 'api_service.dart';
import '../config/api_config.dart';

class OrganizationService {
  final _api = ApiService().dio;

  // ✅ FETCH - Get all organizations with pagination
  Future<OrganizationResponse> fetchOrganizations({
    int length = 10,
    int start = 0,
  }) async {
    try {
      print('🔍 [ORGANIZATION] Fetching organizations...');
      print('🔍 [ORGANIZATION] URL: ${ApiConfig.baseUrl}${ApiConfig.organizationFetch}');
      print('🔍 [ORGANIZATION] Params: length=$length, start=$start');
      
      final response = await _api.get(
        ApiConfig.organizationFetch,
        queryParameters: {
          'length': length,
          'start': start,
        },
      );

      print('🔍 [ORGANIZATION] Response status: ${response.statusCode}');
      print('🔍 [ORGANIZATION] Response data: ${response.data}');

      final orgResponse = OrganizationResponse.fromJsonList(response.data);
      
      if (orgResponse.success) {
        print('✅ [ORGANIZATION] Fetched ${orgResponse.data?.length ?? 0} organizations');
      } else {
        print('⚠️ [ORGANIZATION] Fetch warning: ${orgResponse.message}');
      }

      return orgResponse;
    } on DioException catch (e) {
      print('❌ [ORGANIZATION] Fetch error: ${e.message}');
      print('❌ [ORGANIZATION] Status: ${e.response?.statusCode}');
      print('❌ [ORGANIZATION] Response: ${e.response?.data}');
      return OrganizationResponse(
        success: false,
        message: e.response?.data['Message'] ?? 'Failed to fetch organizations: ${e.message}',
      );
    } catch (e) {
      print('❌ [ORGANIZATION] Unexpected error: $e');
      return OrganizationResponse(
        success: false,
        message: 'Unexpected error: $e',
      );
    }
  }

  // ✅ GET - Get single organization by ID
  Future<OrganizationResponse> getOrganizationDetail(String organizationId) async {
    try {
      print('🔍 [ORGANIZATION] Getting detail for: $organizationId');
      
      final response = await _api.get(
        '${ApiConfig.organizationGet}/$organizationId',
      );

      final orgResponse = OrganizationResponse.fromJsonSingle(response.data);
      
      if (orgResponse.success) {
        print('✅ [ORGANIZATION] Detail loaded: ${orgResponse.singleData?.nama}');
      }

      return orgResponse;
    } on DioException catch (e) {
      print('❌ [ORGANIZATION] Detail error: ${e.message}');
      return OrganizationResponse(
        success: false,
        message: e.response?.data['Message'] ?? 'Failed to get organization detail',
      );
    }
  }

  // ✅ CREATE - Add new organization
  Future<OrganizationResponse> createOrganization({
    required String nama,
    required String noTelp,
    required String alamat,
    required String kecamatan,
    required String kota,
    required String provinsi,
    required String kodePos,
    required bool isActive,
    String? catatan,
  }) async {
    try {
      print('🔍 [ORGANIZATION] Creating organization: $nama');
      print('🔍 [ORGANIZATION] URL: ${ApiConfig.baseUrl}${ApiConfig.organizationCreate}');
      
      final response = await _api.post(
        ApiConfig.organizationCreate,
        data: {
          'nama': nama,
          'no_telp': noTelp,
          'alamat': alamat,
          'kecamatan': kecamatan,
          'kota': kota,
          'provinsi': provinsi,
          'kode_pos': kodePos,
          'is_active': isActive,
          'catatan': catatan?.isNotEmpty == true ? catatan : '-',
        },
      );

      print('🔍 [ORGANIZATION] Create response: ${response.data}');

      final orgResponse = OrganizationResponse.fromJsonSingle(response.data);
      
      if (orgResponse.success) {
        print('✅ [ORGANIZATION] Created successfully');
      } else {
        print('⚠️ [ORGANIZATION] Create warning: ${orgResponse.message}');
      }

      return orgResponse;
    } on DioException catch (e) {
      print('❌ [ORGANIZATION] Create error: ${e.message}');
      print('❌ [ORGANIZATION] Status: ${e.response?.statusCode}');
      print('❌ [ORGANIZATION] Response: ${e.response?.data}');
      
      return OrganizationResponse(
        success: false,
        message: e.response?.data['Message'] ?? 'Failed to create organization: ${e.message}',
      );
    } catch (e) {
      print('❌ [ORGANIZATION] Unexpected error: $e');
      return OrganizationResponse(
        success: false,
        message: 'Unexpected error: $e',
      );
    }
  }

  // ✅ UPDATE - Edit existing organization
  Future<OrganizationResponse> updateOrganization({
    required String id,
    required String nama,
    required String noTelp,
    required String alamat,
    required String kecamatan,
    required String kota,
    required String provinsi,
    required String kodePos,
    required bool isActive,
    String? catatan,
  }) async {
    try {
      print('🔍 [ORGANIZATION] Updating organization: $id');
      print('🔍 [ORGANIZATION] URL: ${ApiConfig.baseUrl}${ApiConfig.organizationUpdate}');

      final response = await _api.put(
        ApiConfig.organizationUpdate,
        data: {
          'id': id,
          'nama': nama,
          'no_telp': noTelp,
          'alamat': alamat,
          'kecamatan': kecamatan,
          'kota': kota,
          'provinsi': provinsi,
          'kode_pos': kodePos,
          'is_active': isActive,
          'catatan': catatan ?? '',
        },
      );

      print('🔍 [ORGANIZATION] Update response: ${response.data}');

      final orgResponse = OrganizationResponse.fromJsonSingle(response.data);

      if (orgResponse.success) {
        print('✅ [ORGANIZATION] Updated successfully');
      } else {
        print('⚠️ [ORGANIZATION] Update warning: ${orgResponse.message}');
      }

      return orgResponse;
    } on DioException catch (e) {
      print('❌ [ORGANIZATION] Update error: ${e.message}');
      print('❌ [ORGANIZATION] Status: ${e.response?.statusCode}');
      print('❌ [ORGANIZATION] Response: ${e.response?.data}');

      return OrganizationResponse(
        success: false,
        message: e.response?.data['Message'] ?? 'Failed to update organization: ${e.message}',
      );
    } catch (e) {
      print('❌ [ORGANIZATION] Unexpected error: $e');
      return OrganizationResponse(
        success: false,
        message: 'Unexpected error: $e',
      );
    }
  }

  // ✅ DELETE - Remove organization
  Future<OrganizationResponse> deleteOrganization(String organizationId) async {
    try {
      print('🔍 [ORGANIZATION] Deleting organization: $organizationId');
      print('🔍 [ORGANIZATION] URL: ${ApiConfig.baseUrl}${ApiConfig.organizationUpdate}/$organizationId');
      
      final response = await _api.delete(
        '${ApiConfig.organizationUpdate}/$organizationId',
      );

      print('🔍 [ORGANIZATION] Delete response: ${response.data}');

      final orgResponse = OrganizationResponse.fromJsonNoData(response.data);
      
      if (orgResponse.success) {
        print('✅ [ORGANIZATION] Deleted successfully');
      } else {
        print('⚠️ [ORGANIZATION] Delete warning: ${orgResponse.message}');
      }

      return orgResponse;
    } on DioException catch (e) {
      print('❌ [ORGANIZATION] Delete error: ${e.message}');
      print('❌ [ORGANIZATION] Status: ${e.response?.statusCode}');
      print('❌ [ORGANIZATION] Response: ${e.response?.data}');
      
      return OrganizationResponse(
        success: false,
        message: e.response?.data['Message'] ?? 'Failed to delete organization: ${e.message}',
      );
    } catch (e) {
      print('❌ [ORGANIZATION] Unexpected error: $e');
      return OrganizationResponse(
        success: false,
        message: 'Unexpected error: $e',
      );
    }
  }
}