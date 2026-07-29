import 'package:dio/dio.dart';

import '../config/api_config.dart';
import 'api_service.dart';

/// OdooLocationService - Service untuk endpoint lokasi Odoo
///
/// Menangani operasi untuk wilayah Indonesia:
/// - Get States/Provinces (Provinsi)
/// - Get Cities (Kota/Kabupaten)
/// - Get Districts (Kecamatan)
///
/// **Note**: Ini berbeda dengan legacy LocationService
/// yang menangani location entities (nama, kode, catatan)
class OdooLocationService {
  final _api = ApiService().dio;

  /// Get all states/provinces
  ///
  /// **Endpoint**: `/get_state`
  /// **Method**: `GET`
  ///
  /// **Response**: Array of state objects
  /// ```json
  /// [
  ///   {
  ///     "id": 1,
  ///     "name": "Jawa Timur",
  ///     "code": "JI",
  ///     "country_id": 100
  ///   }
  /// ]
  /// ```
  Future<Map<String, dynamic>> getStates() async {
    try {
      print('🔍 [LOCATION] Fetching states...');
      print('🔍 [LOCATION] URL: ${ApiConfig.baseUrl}${ApiConfig.getState}');

      final response = await _api.get(ApiConfig.getState);

      print('🔍 [LOCATION] Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        // Response is direct array
        final states = response.data as List;
        print('✅ [LOCATION] Fetched ${states.length} states');

        return {
          'Success': true,
          'Message': 'States fetched successfully',
          'Data': states,
        };
      } else {
        print('⚠️ [LOCATION] Unexpected status: ${response.statusCode}');
        return {
          'Success': false,
          'Message': 'Failed to fetch states',
          'Data': [],
        };
      }
    } on DioException catch (e) {
      print('❌ [LOCATION] Fetch states error: ${e.message}');
      print('❌ [LOCATION] Status: ${e.response?.statusCode}');

      return {
        'Success': false,
        'Message': e.response?.data['Message'] ??
            'Failed to fetch states: ${e.message}',
        'Data': [],
      };
    } catch (e) {
      print('❌ [LOCATION] Unexpected error: $e');
      return {
        'Success': false,
        'Message': 'Unexpected error: $e',
        'Data': [],
      };
    }
  }

  /// Get all cities
  ///
  /// **Endpoint**: `/get_city`
  /// **Method**: `GET`
  ///
  /// **Response**: Array of city objects
  /// ```json
  /// [
  ///   {
  ///     "id": 1,
  ///     "name": "Surabaya",
  ///     "state_id": 1
  ///   }
  /// ]
  /// ```
  Future<Map<String, dynamic>> getCities() async {
    try {
      print('🔍 [LOCATION] Fetching cities...');
      print('🔍 [LOCATION] URL: ${ApiConfig.baseUrl}${ApiConfig.getCity}');

      final response = await _api.get(ApiConfig.getCity);

      print('🔍 [LOCATION] Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        // Response is direct array
        final cities = response.data as List;
        print('✅ [LOCATION] Fetched ${cities.length} cities');

        return {
          'Success': true,
          'Message': 'Cities fetched successfully',
          'Data': cities,
        };
      } else {
        print('⚠️ [LOCATION] Unexpected status: ${response.statusCode}');
        return {
          'Success': false,
          'Message': 'Failed to fetch cities',
          'Data': [],
        };
      }
    } on DioException catch (e) {
      print('❌ [LOCATION] Fetch cities error: ${e.message}');
      print('❌ [LOCATION] Status: ${e.response?.statusCode}');

      return {
        'Success': false,
        'Message': e.response?.data['Message'] ??
            'Failed to fetch cities: ${e.message}',
        'Data': [],
      };
    } catch (e) {
      print('❌ [LOCATION] Unexpected error: $e');
      return {
        'Success': false,
        'Message': 'Unexpected error: $e',
        'Data': [],
      };
    }
  }

  /// Get all districts
  ///
  /// **Endpoint**: `/get_district`
  /// **Method**: `GET`
  ///
  /// **Response**: Array of district objects
  /// ```json
  /// [
  ///   {
  ///     "id": 1,
  ///     "name": "Rungkut",
  ///     "city_id": 1
  ///   }
  /// ]
  /// ```
  Future<Map<String, dynamic>> getDistricts() async {
    try {
      print('🔍 [LOCATION] Fetching districts...');
      print('🔍 [LOCATION] URL: ${ApiConfig.baseUrl}${ApiConfig.getDistrict}');

      final response = await _api.get(ApiConfig.getDistrict);

      print('🔍 [LOCATION] Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        // Response is direct array
        final districts = response.data as List;
        print('✅ [LOCATION] Fetched ${districts.length} districts');

        return {
          'Success': true,
          'Message': 'Districts fetched successfully',
          'Data': districts,
        };
      } else {
        print('⚠️ [LOCATION] Unexpected status: ${response.statusCode}');
        return {
          'Success': false,
          'Message': 'Failed to fetch districts',
          'Data': [],
        };
      }
    } on DioException catch (e) {
      print('❌ [LOCATION] Fetch districts error: ${e.message}');
      print('❌ [LOCATION] Status: ${e.response?.statusCode}');

      return {
        'Success': false,
        'Message': e.response?.data['Message'] ??
            'Failed to fetch districts: ${e.message}',
        'Data': [],
      };
    } catch (e) {
      print('❌ [LOCATION] Unexpected error: $e');
      return {
        'Success': false,
        'Message': 'Unexpected error: $e',
        'Data': [],
      };
    }
  }

  /// Get cities by state ID (filter client-side)
  ///
  /// Since API doesn't support filtering, we fetch all and filter locally
  Future<Map<String, dynamic>> getCitiesByState(int stateId) async {
    try {
      final result = await getCities();

      if (result['Success'] == true) {
        final cities = result['Data'] as List;
        final filtered = cities.where((city) {
          return city['state_id'] == stateId;
        }).toList();

        return {
          'Success': true,
          'Message': 'Cities filtered successfully',
          'Data': filtered,
        };
      }

      return result;
    } catch (e) {
      print('❌ [LOCATION] Filter cities error: $e');
      return {
        'Success': false,
        'Message': 'Failed to filter cities: $e',
        'Data': [],
      };
    }
  }

  /// Get districts by city ID (filter client-side)
  ///
  /// Since API doesn't support filtering, we fetch all and filter locally
  Future<Map<String, dynamic>> getDistrictsByCity(int cityId) async {
    try {
      final result = await getDistricts();

      if (result['Success'] == true) {
        final districts = result['Data'] as List;
        final filtered = districts.where((district) {
          return district['city_id'] == cityId;
        }).toList();

        return {
          'Success': true,
          'Message': 'Districts filtered successfully',
          'Data': filtered,
        };
      }

      return result;
    } catch (e) {
      print('❌ [LOCATION] Filter districts error: $e');
      return {
        'Success': false,
        'Message': 'Failed to filter districts: $e',
        'Data': [],
      };
    }
  }
}
