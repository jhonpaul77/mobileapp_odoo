import 'dart:convert';
import 'package:dio/dio.dart';
import '../../../../services/api_service.dart';
import '../../domain/entities/state.dart';
import '../../domain/entities/city.dart';
import '../../domain/entities/district.dart';

/// LocationRemoteDataSource - Handle location API calls
///
/// Mengikuti pola yang sama dengan ProductRemoteDataSource
class LocationRemoteDataSource {
  final Dio _dio;

  // Cache untuk mengurangi API calls
  final Map<int, String> _districtNameCache = {};
  final Map<int, String> _cityNameCache = {};
  final Map<int, String> _stateNameCache = {};
  final Map<int, String> _countryNameCache = {};

  LocationRemoteDataSource({Dio? dio}) : _dio = dio ?? ApiService().dio;

  Future<List<State>> getStates({
    required String db,
    required String apiKey,
  }) async {
    try {
      print('🔄 [LOCATION_DS] Fetching states...');

      final response = await _dio.get(
        '/get_state',
        options: Options(
          headers: {
            'db': db,
            'api-key': apiKey,
          },
        ),
      );

      print('✅ [LOCATION_DS] Response status: ${response.statusCode}');

      List<dynamic> jsonList;
      if (response.data is String) {
        final parsed = json.decode(response.data);
        if (parsed is! List) {
          throw Exception(
              'Invalid response format: expected List, got ${parsed.runtimeType}');
        }
        jsonList = parsed;
      } else if (response.data is List) {
        jsonList = response.data as List<dynamic>;
      } else {
        throw Exception(
            'Invalid response format: expected List or String, got ${response.data.runtimeType}');
      }

      print('✅ [LOCATION_DS] States loaded: ${jsonList.length}');
      return jsonList
          .map((item) => State.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      print('❌ [LOCATION_DS] Dio error: ${e.message}');
      print('   Response: ${e.response?.data}');
      throw Exception(
          'Failed to fetch states: ${e.response?.data ?? e.message}');
    } catch (e) {
      print('❌ [LOCATION_DS] Unexpected error: $e');
      throw Exception('Unexpected error while fetching states: $e');
    }
  }

  Future<List<City>> getCities({
    required String db,
    required String apiKey,
    int? stateId,
  }) async {
    try {
      print('🔄 [LOCATION_DS] Fetching cities...');

      final queryParams =
          stateId != null ? {'state_id': stateId} : <String, dynamic>{};

      final response = await _dio.get(
        '/get_city',
        queryParameters: queryParams,
        options: Options(
          headers: {
            'db': db,
            'api-key': apiKey,
          },
        ),
      );

      print('✅ [LOCATION_DS] Response status: ${response.statusCode}');

      List<dynamic> jsonList;
      if (response.data is String) {
        final parsed = json.decode(response.data);
        if (parsed is! List) {
          throw Exception(
              'Invalid response format: expected List, got ${parsed.runtimeType}');
        }
        jsonList = parsed;
      } else if (response.data is List) {
        jsonList = response.data as List<dynamic>;
      } else {
        throw Exception(
            'Invalid response format: expected List or String, got ${response.data.runtimeType}');
      }

      print('✅ [LOCATION_DS] Cities loaded: ${jsonList.length}');
      return jsonList
          .map((item) => City.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      print('❌ [LOCATION_DS] Dio error: ${e.message}');
      print('   Response: ${e.response?.data}');
      throw Exception(
          'Failed to fetch cities: ${e.response?.data ?? e.message}');
    } catch (e) {
      print('❌ [LOCATION_DS] Unexpected error: $e');
      throw Exception('Unexpected error while fetching cities: $e');
    }
  }

  Future<List<District>> getDistricts({
    required String db,
    required String apiKey,
    int? cityId,
  }) async {
    try {
      print('🔄 [LOCATION_DS] Fetching districts...');

      final queryParams =
          cityId != null ? {'city_id': cityId} : <String, dynamic>{};

      final response = await _dio.get(
        '/get_district',
        queryParameters: queryParams,
        options: Options(
          headers: {
            'db': db,
            'api-key': apiKey,
          },
        ),
      );

      print('✅ [LOCATION_DS] Response status: ${response.statusCode}');

      List<dynamic> jsonList;
      if (response.data is String) {
        final parsed = json.decode(response.data);
        if (parsed is! List) {
          throw Exception(
              'Invalid response format: expected List, got ${parsed.runtimeType}');
        }
        jsonList = parsed;
      } else if (response.data is List) {
        jsonList = response.data as List<dynamic>;
      } else {
        throw Exception(
            'Invalid response format: expected List or String, got ${response.data.runtimeType}');
      }

      print('✅ [LOCATION_DS] Districts loaded: ${jsonList.length}');
      return jsonList
          .map((item) => District.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      print('❌ [LOCATION_DS] Dio error: ${e.message}');
      print('   Response: ${e.response?.data}');
      throw Exception(
          'Failed to fetch districts: ${e.response?.data ?? e.message}');
    } catch (e) {
      print('❌ [LOCATION_DS] Unexpected error: $e');
      throw Exception('Unexpected error while fetching districts: $e');
    }
  }

  /// Get all districts (for search functionality)
  Future<List<District>> getAllDistricts({
    required String db,
    required String apiKey,
  }) async {
    try {
      print('🔄 [LOCATION_DS] Fetching all districts...');

      final response = await _dio.get(
        '/get_district',
        options: Options(
          headers: {
            'db': db,
            'api-key': apiKey,
          },
        ),
      );

      print('✅ [LOCATION_DS] Response status: ${response.statusCode}');

      List<dynamic> jsonList;
      if (response.data is String) {
        final parsed = json.decode(response.data);
        if (parsed is! List) {
          throw Exception(
              'Invalid response format: expected List, got ${parsed.runtimeType}');
        }
        jsonList = parsed;
      } else if (response.data is List) {
        jsonList = response.data as List<dynamic>;
      } else {
        throw Exception(
            'Invalid response format: expected List or String, got ${response.data.runtimeType}');
      }

      print('✅ [LOCATION_DS] All districts loaded: ${jsonList.length}');

      // Cache district names
      for (final item in jsonList) {
        final district = District.fromJson(item as Map<String, dynamic>);
        _districtNameCache[district.id] = district.name;
      }

      return jsonList
          .map((item) => District.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      print('❌ [LOCATION_DS] Dio error: ${e.message}');
      print('   Response: ${e.response?.data}');
      throw Exception(
          'Failed to fetch all districts: ${e.response?.data ?? e.message}');
    } catch (e) {
      print('❌ [LOCATION_DS] Unexpected error: $e');
      throw Exception('Unexpected error while fetching all districts: $e');
    }
  }

  /// Get district name by ID
  Future<String> getDistrictName({
    required int districtId,
    required String db,
    required String apiKey,
  }) async {
    // Check cache first
    if (_districtNameCache.containsKey(districtId)) {
      return _districtNameCache[districtId]!;
    }

    try {
      final districts = await getAllDistricts(db: db, apiKey: apiKey);
      final district = districts.firstWhere(
        (d) => d.id == districtId,
        orElse: () =>
            District(id: districtId, name: 'Unknown', code: '', cityId: 0),
      );
      _districtNameCache[districtId] = district.name;
      return district.name;
    } catch (e) {
      print('❌ [LOCATION_DS] Error getting district name: $e');
      return 'District #$districtId';
    }
  }

  /// Get city name by ID
  Future<String> getCityName({
    required int cityId,
    required String db,
    required String apiKey,
  }) async {
    // Check cache first
    if (_cityNameCache.containsKey(cityId)) {
      return _cityNameCache[cityId]!;
    }

    try {
      final cities = await getCities(db: db, apiKey: apiKey);
      final city = cities.firstWhere(
        (c) => c.id == cityId,
        orElse: () => City(id: cityId, name: 'Unknown', code: '', stateId: 0),
      );
      _cityNameCache[cityId] = city.name;
      return city.name;
    } catch (e) {
      print('❌ [LOCATION_DS] Error getting city name: $e');
      return 'City #$cityId';
    }
  }

  /// Get state name by ID
  Future<String> getStateName({
    required int stateId,
    required String db,
    required String apiKey,
  }) async {
    // Check cache first
    if (_stateNameCache.containsKey(stateId)) {
      return _stateNameCache[stateId]!;
    }

    try {
      final states = await getStates(db: db, apiKey: apiKey);
      final state = states.firstWhere(
        (s) => s.id == stateId,
        orElse: () =>
            State(id: stateId, name: 'Unknown', code: '', countryId: 0),
      );
      _stateNameCache[stateId] = state.name;
      return state.name;
    } catch (e) {
      print('❌ [LOCATION_DS] Error getting state name: $e');
      return 'State #$stateId';
    }
  }

  /// Get country name by ID
  Future<String> getCountryName({
    required int countryId,
    required String db,
    required String apiKey,
  }) async {
    // Check cache first
    if (_countryNameCache.containsKey(countryId)) {
      return _countryNameCache[countryId]!;
    }

    try {
      print('🔄 [LOCATION_DS] Fetching country name for ID: $countryId...');

      // Try to get from countries list if available
      // For now, return placeholder - can be enhanced if endpoint exists
      final countryName = 'Country #$countryId';
      _countryNameCache[countryId] = countryName;
      return countryName;
    } catch (e) {
      print('❌ [LOCATION_DS] Error getting country name: $e');
      return 'Country #$countryId';
    }
  }
}
