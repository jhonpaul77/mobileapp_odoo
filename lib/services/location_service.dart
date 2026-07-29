import 'package:dio/dio.dart';

import '../config/api_config.dart';
import '../models/location/location_response.dart';
import 'api_service.dart';

/// LocationService - Service untuk operasi warehouse/storage location (LEGACY)
///
/// ⚠️ NOTE: This is NOT for State/City/District location!
/// For State/City/District, use OdooLocationService instead.
///
/// **LEGACY ENDPOINTS**:
/// - GET `/api/v1/location/fetch` - Get all locations with pagination
/// - GET `/api/v1/location/get/:id` - Get single location by ID
/// - POST `/api/v1/location` - Create new location
/// - PUT `/api/v1/location` - Update existing location
/// - DELETE `/api/v1/location/:id` - Delete location
class LocationService {
  final _api = ApiService().dio;

  // ✅ FETCH - Get all locations with pagination
  Future<LocationResponse> fetchLocations({
    int length = 10,
    int start = 0,
  }) async {
    try {
      print('🔍 [LOCATION] Fetching locations...');
      print(
          '🔍 [LOCATION] URL: ${ApiConfig.baseUrl}${ApiConfig.locationFetch}');
      print('🔍 [LOCATION] Params: length=$length, start=$start');

      final response = await _api.get(
        ApiConfig.locationFetch,
        queryParameters: {
          'length': length,
          'start': start,
        },
      );

      print('🔍 [LOCATION] Response status: ${response.statusCode}');

      final locationResponse = LocationResponse.fromJsonList(response.data);

      if (locationResponse.success) {
        print(
            '✅ [LOCATION] Fetched ${locationResponse.data?.length ?? 0} locations');
      } else {
        print('⚠️ [LOCATION] Fetch warning: ${locationResponse.message}');
      }

      return locationResponse;
    } on DioException catch (e) {
      print('❌ [LOCATION] Fetch error: ${e.message}');
      print('❌ [LOCATION] Status: ${e.response?.statusCode}');

      return LocationResponse(
        success: false,
        message: e.response?.data['Message'] ??
            'Failed to fetch locations: ${e.message}',
      );
    } catch (e) {
      print('❌ [LOCATION] Unexpected error: $e');
      return LocationResponse(
        success: false,
        message: 'Unexpected error: $e',
      );
    }
  }

  // ✅ GET - Get single location by ID
  Future<LocationResponse> getLocationDetail(String locationId) async {
    try {
      print('🔍 [LOCATION] Getting detail for: $locationId');
      print(
          '🔍 [LOCATION] URL: ${ApiConfig.baseUrl}${ApiConfig.locationGet}/$locationId');

      final response = await _api.get(
        '${ApiConfig.locationGet}/$locationId',
      );

      print('🔍 [LOCATION] Response status: ${response.statusCode}');
      print('🔍 [LOCATION] Response data: ${response.data}');

      if (response.statusCode == 200 && response.data["Success"] == true) {
        final locationResponse = LocationResponse.fromJsonSingle(response.data);
        print(
            '✅ [LOCATION] Detail loaded: ${locationResponse.singleData?.nama}');
        return locationResponse;
      } else {
        return LocationResponse(
          success: false,
          message: response.data["Message"] ?? 'Gagal mengambil data',
        );
      }
    } on DioException catch (e) {
      print('❌ [LOCATION] Detail error: ${e.message}');
      print('❌ [LOCATION] Status: ${e.response?.statusCode}');

      return LocationResponse(
        success: false,
        message:
            e.response?.data["Message"] ?? 'Terjadi kesalahan (DioException)',
      );
    } catch (e) {
      print('❌ [LOCATION] Unexpected error: $e');
      return LocationResponse(
        success: false,
        message: 'Unexpected error: $e',
      );
    }
  }

  // ✅ LOOKUP - Search locations
  Future<LocationResponse> lookupLocations({String? query}) async {
    try {
      print('🔍 [LOCATION] Looking up locations...');
      print(
          '🔍 [LOCATION] URL: ${ApiConfig.baseUrl}${ApiConfig.locationLookup}');

      final response = await _api.get(
        ApiConfig.locationLookup,
        queryParameters: query != null ? {'query': query} : null,
      );

      print('🔍 [LOCATION] Response status: ${response.statusCode}');

      final locationResponse = LocationResponse.fromJsonList(response.data);

      if (locationResponse.success) {
        print(
            '✅ [LOCATION] Found ${locationResponse.data?.length ?? 0} locations');
      }

      return locationResponse;
    } on DioException catch (e) {
      print('❌ [LOCATION] Lookup error: ${e.message}');

      return LocationResponse(
        success: false,
        message: e.response?.data['Message'] ??
            'Failed to lookup locations: ${e.message}',
      );
    } catch (e) {
      print('❌ [LOCATION] Unexpected error: $e');
      return LocationResponse(
        success: false,
        message: 'Unexpected error: $e',
      );
    }
  }

  // ✅ CREATE - Add new location
  Future<LocationResponse> createLocation({
    required String kode,
    required String nama,
    String? catatan,
  }) async {
    try {
      print('🔍 [LOCATION] Creating location: $nama');
      print(
          '🔍 [LOCATION] URL: ${ApiConfig.baseUrl}${ApiConfig.locationCreate}');

      final response = await _api.post(
        ApiConfig.locationCreate,
        data: {
          'kode': kode,
          'nama': nama,
          'catatan': catatan?.isNotEmpty == true ? catatan : '-',
        },
      );

      print('🔍 [LOCATION] Create response: ${response.data}');

      final locationResponse = LocationResponse.fromJsonSingle(response.data);

      if (locationResponse.success) {
        print('✅ [LOCATION] Created successfully');
      } else {
        print('⚠️ [LOCATION] Create warning: ${locationResponse.message}');
      }

      return locationResponse;
    } on DioException catch (e) {
      print('❌ [LOCATION] Create error: ${e.message}');
      print('❌ [LOCATION] Status: ${e.response?.statusCode}');

      return LocationResponse(
        success: false,
        message: e.response?.data['Message'] ??
            'Failed to create location: ${e.message}',
      );
    } catch (e) {
      print('❌ [LOCATION] Unexpected error: $e');
      return LocationResponse(
        success: false,
        message: 'Unexpected error: $e',
      );
    }
  }

  // ✅ UPDATE - Edit existing location
  Future<LocationResponse> updateLocation({
    required String id,
    required String kode,
    required String nama,
    String? catatan,
  }) async {
    try {
      print('🔍 [LOCATION] Updating location: $id');
      print(
          '🔍 [LOCATION] URL: ${ApiConfig.baseUrl}${ApiConfig.locationUpdate}');

      final response = await _api.put(
        ApiConfig.locationUpdate,
        data: {
          'id': id,
          'kode': kode,
          'nama': nama,
          'catatan': catatan?.isNotEmpty == true ? catatan : '-',
        },
      );

      print('🔍 [LOCATION] Update response: ${response.data}');

      final locationResponse = LocationResponse.fromJsonSingle(response.data);

      if (locationResponse.success) {
        print('✅ [LOCATION] Updated successfully');
      } else {
        print('⚠️ [LOCATION] Update warning: ${locationResponse.message}');
      }

      return locationResponse;
    } on DioException catch (e) {
      print('❌ [LOCATION] Update error: ${e.message}');
      print('❌ [LOCATION] Status: ${e.response?.statusCode}');

      return LocationResponse(
        success: false,
        message: e.response?.data['Message'] ??
            'Failed to update location: ${e.message}',
      );
    } catch (e) {
      print('❌ [LOCATION] Unexpected error: $e');
      return LocationResponse(
        success: false,
        message: 'Unexpected error: $e',
      );
    }
  }

  // ✅ DELETE - Remove location
  Future<LocationResponse> deleteLocation(String locationId) async {
    try {
      print('🔍 [LOCATION] Deleting location: $locationId');
      print(
          '🔍 [LOCATION] URL: ${ApiConfig.baseUrl}${ApiConfig.locationFetch}/$locationId');

      final response = await _api.delete(
        '${ApiConfig.locationFetch}/$locationId',
      );

      print('🔍 [LOCATION] Delete response: ${response.data}');

      final locationResponse = LocationResponse.fromJsonNoData(response.data);

      if (locationResponse.success) {
        print('✅ [LOCATION] Deleted successfully');
      } else {
        print('⚠️ [LOCATION] Delete warning: ${locationResponse.message}');
      }

      return locationResponse;
    } on DioException catch (e) {
      print('❌ [LOCATION] Delete error: ${e.message}');
      print('❌ [LOCATION] Status: ${e.response?.statusCode}');

      return LocationResponse(
        success: false,
        message: e.response?.data['Message'] ??
            'Failed to delete location: ${e.message}',
      );
    } catch (e) {
      print('❌ [LOCATION] Unexpected error: $e');
      return LocationResponse(
        success: false,
        message: 'Unexpected error: $e',
      );
    }
  }
}
