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
          throw Exception('Invalid response format: expected List, got ${parsed.runtimeType}');
        }
        jsonList = parsed;
      } else if (response.data is List) {
        jsonList = response.data as List<dynamic>;
      } else {
        throw Exception('Invalid response format: expected List or String, got ${response.data.runtimeType}');
      }

      print('✅ [LOCATION_DS] States loaded: ${jsonList.length}');
      return jsonList
          .map((item) => State.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      print('❌ [LOCATION_DS] Dio error: ${e.message}');
      print('   Response: ${e.response?.data}');
      throw Exception('Failed to fetch states: ${e.response?.data ?? e.message}');
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
      
      final queryParams = stateId != null ? {'state_id': stateId} : <String, dynamic>{};

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
          throw Exception('Invalid response format: expected List, got ${parsed.runtimeType}');
        }
        jsonList = parsed;
      } else if (response.data is List) {
        jsonList = response.data as List<dynamic>;
      } else {
        throw Exception('Invalid response format: expected List or String, got ${response.data.runtimeType}');
      }

      print('✅ [LOCATION_DS] Cities loaded: ${jsonList.length}');
      return jsonList
          .map((item) => City.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      print('❌ [LOCATION_DS] Dio error: ${e.message}');
      print('   Response: ${e.response?.data}');
      throw Exception('Failed to fetch cities: ${e.response?.data ?? e.message}');
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
      
      final queryParams = cityId != null ? {'city_id': cityId} : <String, dynamic>{};

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
          throw Exception('Invalid response format: expected List, got ${parsed.runtimeType}');
        }
        jsonList = parsed;
      } else if (response.data is List) {
        jsonList = response.data as List<dynamic>;
      } else {
        throw Exception('Invalid response format: expected List or String, got ${response.data.runtimeType}');
      }

      print('✅ [LOCATION_DS] Districts loaded: ${jsonList.length}');
      return jsonList
          .map((item) => District.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      print('❌ [LOCATION_DS] Dio error: ${e.message}');
      print('   Response: ${e.response?.data}');
      throw Exception('Failed to fetch districts: ${e.response?.data ?? e.message}');
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
          throw Exception('Invalid response format: expected List, got ${parsed.runtimeType}');
        }
        jsonList = parsed;
      } else if (response.data is List) {
        jsonList = response.data as List<dynamic>;
      } else {
        throw Exception('Invalid response format: expected List or String, got ${response.data.runtimeType}');
      }

      print('✅ [LOCATION_DS] All districts loaded: ${jsonList.length}');
      return jsonList
          .map((item) => District.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      print('❌ [LOCATION_DS] Dio error: ${e.message}');
      print('   Response: ${e.response?.data}');
      throw Exception('Failed to fetch all districts: ${e.response?.data ?? e.message}');
    } catch (e) {
      print('❌ [LOCATION_DS] Unexpected error: $e');
      throw Exception('Unexpected error while fetching all districts: $e');
    }
  }
}
