import 'package:dio/dio.dart';
import 'package:pintarx/models/location/location.dart';
import 'package:pintarx/models/location/location_response.dart';
import 'api_service.dart';
import '../config/api_config.dart';

class LocationService {
  final _api = ApiService().dio;

  // ✅ FETCH - Get all locations with pagination
  Future<LocationResponse> fetchLocations({
    int length = 10,
    int start = 0,
  }) async {
    try {
      print('📍 [LOCATION] Fetching locations...');
      print('📍 [LOCATION] URL: ${ApiConfig.baseUrl}${ApiConfig.locationFetch}');
      print('📍 [LOCATION] Params: length=$length, start=$start');
      
      final response = await _api.get(
        ApiConfig.locationFetch,
        queryParameters: {
          'length': length,
          'start': start,
        },
      );

      print('📍 [LOCATION] Response status: ${response.statusCode}');
      print('📍 [LOCATION] Response data: ${response.data}');

      final locationResponse = LocationResponse.fromJsonList(response.data);
      
      if (locationResponse.success) {
        print('✅ [LOCATION] Fetched ${locationResponse.data?.length ?? 0} locations');
      } else {
        print('⚠️ [LOCATION] Fetch warning: ${locationResponse.message}');
      }

      return locationResponse;
    } on DioException catch (e) {
      print('❌ [LOCATION] Fetch error: ${e.message}');
      print('❌ [LOCATION] Status: ${e.response?.statusCode}');
      print('❌ [LOCATION] Response: ${e.response?.data}');
      return LocationResponse(
        success: false,
        message: e.response?.data['Message'] ?? 'Failed to fetch locations: ${e.message}',
      );
    } catch (e) {
      print('❌ [LOCATION] Unexpected error: $e');
      return LocationResponse(
        success: false,
        message: 'Unexpected error: $e',
      );
    }
  }

  // ✅ GET - Get single location by ID (path parameter)
  Future<LocationResponse> getLocationDetail(String locationId) async {
    try {
      print('📍 [LOCATION] Getting detail for: $locationId');
      
      final response = await _api.get(
        '${ApiConfig.locationGet}/$locationId',
      );

      final locationResponse = LocationResponse.fromJsonSingle(response.data);
      
      if (locationResponse.success) {
        print('✅ [LOCATION] Detail loaded: ${locationResponse.singleData?.nama}');
      }

      return locationResponse;
    } on DioException catch (e) {
      print('❌ [LOCATION] Detail error: ${e.message}');
      return LocationResponse(
        success: false,
        message: e.response?.data['Message'] ?? 'Failed to get location detail',
      );
    }
  }

  // ✅ LOOKUP - Search/lookup locations
  Future<LocationResponse> lookupLocations({String? keyword}) async {
    try {
      print('📍 [LOCATION] Looking up locations... (keyword: $keyword)');
      
      final response = await _api.get(
        ApiConfig.locationLookup,
        queryParameters: keyword != null ? {'keyword': keyword} : null,
      );

      final locationResponse = LocationResponse.fromJsonList(response.data);
      
      if (locationResponse.success) {
        print('✅ [LOCATION] Found ${locationResponse.data?.length ?? 0} locations');
      }

      return locationResponse;
    } on DioException catch (e) {
      print('❌ [LOCATION] Lookup error: ${e.message}');
      return LocationResponse(
        success: false,
        message: e.response?.data['Message'] ?? 'Failed to lookup locations',
      );
    }
  }

  // ✅ CREATE - Add new location
  Future<LocationResponse> createLocation({
    required String kode,
    required String nama,
    required String catatan,
  }) async {
    try {
      print('📍 [LOCATION] Creating location: $nama');
      print('📍 [LOCATION] URL: ${ApiConfig.baseUrl}${ApiConfig.locationCreate}');
      print('📍 [LOCATION] Data: kode=$kode, nama=$nama');
      
      final response = await _api.post(
        ApiConfig.locationCreate,
        data: {
          'kode': kode,
          'nama': nama,
          'catatan': catatan,
        },
      );

      print('📍 [LOCATION] Create response: ${response.data}');

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
      print('❌ [LOCATION] Response: ${e.response?.data}');
      
      // Handle 500 error
      if (e.response?.statusCode == 500) {
        final data = e.response?.data;
        if (data != null && data is Map) {
          return LocationResponse(
            success: false,
            message: data['Message'] ?? 'Gagal menambah lokasi',
          );
        }
      }
      
      return LocationResponse(
        success: false,
        message: e.response?.data['Message'] ?? 'Failed to create location: ${e.message}',
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
  required String catatan,
}) async {
  try {
    print('📍 [LOCATION] Updating location: $id');
    print('📍 [LOCATION] URL: ${ApiConfig.baseUrl}${ApiConfig.locationUpdate}');
    print('📍 [LOCATION] Data: id=$id, kode=$kode, nama=$nama');

    // ✅ Sesuai Swagger: PUT /location (id dikirim di body)
    final response = await _api.put(
      ApiConfig.locationUpdate, // <── tanpa /$id
      data: {
        'id': id, // <── wajib disertakan di body
        'kode': kode,
        'nama': nama,
        'catatan': catatan,
      },
    );

    print('📍 [LOCATION] Update response: ${response.data}');

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
    print('❌ [LOCATION] Response: ${e.response?.data}');

    if (e.response?.statusCode == 500) {
      final data = e.response?.data;
      if (data != null && data is Map) {
        final message = data['Message'] ?? 'Gagal update lokasi';
        if (message.contains('no rows')) {
          return LocationResponse(
            success: false,
            message: 'Lokasi tidak ditemukan atau sudah dihapus',
          );
        }
        return LocationResponse(
          success: false,
          message: message,
        );
      }
    }

    return LocationResponse(
      success: false,
      message:
          e.response?.data['Message'] ?? 'Failed to update location: ${e.message}',
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
      print('📍 [LOCATION] Deleting location: $locationId');
      print('📍 [LOCATION] URL: ${ApiConfig.baseUrl}${ApiConfig.locationUpdate}/$locationId');
      
      final response = await _api.delete(
        '${ApiConfig.locationUpdate}/$locationId',
      );

      print('📍 [LOCATION] Delete response: ${response.data}');

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
      print('❌ [LOCATION] Response: ${e.response?.data}');
      
      // Handle 500 error
      if (e.response?.statusCode == 500) {
        final data = e.response?.data;
        if (data != null && data is Map) {
          final message = data['Message'] ?? 'Gagal hapus lokasi';
          
          if (message.contains('no rows')) {
            return LocationResponse(
              success: false,
              message: 'Lokasi tidak ditemukan atau sudah dihapus',
            );
          }
          
          return LocationResponse(
            success: false,
            message: message,
          );
        }
      }
      
      return LocationResponse(
        success: false,
        message: e.response?.data['Message'] ?? 'Failed to delete location: ${e.message}',
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