import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../../config/api_config.dart';
import '../../../../services/api_service.dart';
import '../models/location_models.dart';

/// Location Remote DataSource
///
/// Handles semua API calls untuk State, City, District
/// Berkomunikasi dengan Odoo ERP API
class LocationRemoteDataSource {
  final Dio _dio;

  LocationRemoteDataSource({Dio? dio})
      : _dio = dio ?? ApiService().dio;

  /// Fetch semua states dari API
  Future<List<StateLocalModel>> getStates({
    required String db,
    required String apiKey,
  }) async {
    try {
      print('🔄 [LOCATION_DS] Fetching states...');

      final headers = {
        'db': db,
        'api-key': apiKey,
      };

      final response = await _dio.get(
        ApiConfig.getState,
        options: Options(
          headers: headers,
          extra: {'skipAuthInterceptor': true},
        ),
      );

      print('✅ [LOCATION_DS] States response received: ${response.statusCode}');

      // Parse response
      dynamic data = response.data;
      if (data is String) {
        data = jsonDecode(data);
      }

      List<dynamic> itemsList = [];
      if (data is List) {
        itemsList = data;
      } else if (data is Map<String, dynamic>) {
        if (data.containsKey('Success') && data['Success'] == true) {
          if (data['Data'] is List) {
            itemsList = data['Data'] as List;
          }
        }
      }

      final states = itemsList
          .map((json) {
            try {
              return StateLocalModel.fromApi(json as Map<String, dynamic>);
            } catch (e) {
              print('⚠️ [LOCATION_DS] Error parsing state: $e');
              return null;
            }
          })
          .whereType<StateLocalModel>()
          .toList();

      print('✅ [LOCATION_DS] Fetched ${states.length} states');
      return states;
    } catch (e) {
      print('❌ [LOCATION_DS] Error fetching states: $e');
      rethrow;
    }
  }

  /// Fetch semua cities dari API
  Future<List<CityLocalModel>> getCities({
    required String db,
    required String apiKey,
  }) async {
    try {
      print('🔄 [LOCATION_DS] Fetching cities...');

      final headers = {
        'db': db,
        'api-key': apiKey,
      };

      final response = await _dio.get(
        ApiConfig.getCity,
        options: Options(
          headers: headers,
          extra: {'skipAuthInterceptor': true},
        ),
      );

      print('✅ [LOCATION_DS] Cities response received: ${response.statusCode}');

      // Parse response
      dynamic data = response.data;
      if (data is String) {
        data = jsonDecode(data);
      }

      List<dynamic> itemsList = [];
      if (data is List) {
        itemsList = data;
      } else if (data is Map<String, dynamic>) {
        if (data.containsKey('Success') && data['Success'] == true) {
          if (data['Data'] is List) {
            itemsList = data['Data'] as List;
          }
        }
      }

      final cities = itemsList
          .map((json) {
            try {
              return CityLocalModel.fromApi(json as Map<String, dynamic>);
            } catch (e) {
              print('⚠️ [LOCATION_DS] Error parsing city: $e');
              return null;
            }
          })
          .whereType<CityLocalModel>()
          .toList();

      print('✅ [LOCATION_DS] Fetched ${cities.length} cities');
      return cities;
    } catch (e) {
      print('❌ [LOCATION_DS] Error fetching cities: $e');
      rethrow;
    }
  }

  /// Fetch semua districts dari API
  Future<List<DistrictLocalModel>> getDistricts({
    required String db,
    required String apiKey,
  }) async {
    try {
      print('🔄 [LOCATION_DS] Fetching districts...');

      final headers = {
        'db': db,
        'api-key': apiKey,
      };

      final response = await _dio.get(
        ApiConfig.getDistrict,
        options: Options(
          headers: headers,
          extra: {'skipAuthInterceptor': true},
        ),
      );

      print('✅ [LOCATION_DS] Districts response received: ${response.statusCode}');

      // Parse response
      dynamic data = response.data;
      if (data is String) {
        data = jsonDecode(data);
      }

      List<dynamic> itemsList = [];
      if (data is List) {
        itemsList = data;
      } else if (data is Map<String, dynamic>) {
        if (data.containsKey('Success') && data['Success'] == true) {
          if (data['Data'] is List) {
            itemsList = data['Data'] as List;
          }
        }
      }

      final districts = itemsList
          .map((json) {
            try {
              return DistrictLocalModel.fromApi(json as Map<String, dynamic>);
            } catch (e) {
              print('⚠️ [LOCATION_DS] Error parsing district: $e');
              return null;
            }
          })
          .whereType<DistrictLocalModel>()
          .toList();

      print('✅ [LOCATION_DS] Fetched ${districts.length} districts');
      return districts;
    } catch (e) {
      print('❌ [LOCATION_DS] Error fetching districts: $e');
      rethrow;
    }
  }
}
