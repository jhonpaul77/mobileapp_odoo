import 'package:sqflite/sqflite.dart';

import '../../features/customer/data/models/location_models.dart';
import 'database_helper.dart';

/// LocationLocalDatabase - CRUD operations untuk State, City, District
///
/// Manages semua database operations untuk data lokasi
class LocationLocalDatabase {
  static final LocationLocalDatabase _instance =
      LocationLocalDatabase._internal();
  final DatabaseHelper _dbHelper = DatabaseHelper();

  factory LocationLocalDatabase() {
    return _instance;
  }

  LocationLocalDatabase._internal();

  // ============ STATES OPERATIONS ============

  /// Insert or replace state
  Future<void> insertOrReplaceState(StateLocalModel state) async {
    try {
      final db = await _dbHelper.database;
      await db.insert(
        'states',
        state.toLocalJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      print('✅ [LOCATION_DB] Inserted/Updated state: ${state.name} (ID: ${state.id})');
    } catch (e) {
      print('❌ [LOCATION_DB] Error inserting state: $e');
      rethrow;
    }
  }

  /// Batch insert states
  Future<void> insertBatchStates(List<StateLocalModel> states) async {
    try {
      final db = await _dbHelper.database;
      final batch = db.batch();

      for (final state in states) {
        batch.insert(
          'states',
          state.toLocalJson(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      await batch.commit();
      print('✅ [LOCATION_DB] Batch inserted ${states.length} states');
    } catch (e) {
      print('❌ [LOCATION_DB] Error batch inserting states: $e');
      rethrow;
    }
  }

  /// Get all states
  Future<List<StateLocalModel>> getAllStates() async {
    try {
      final db = await _dbHelper.database;
      final maps = await db.query('states', orderBy: 'name ASC');

      final states =
          maps.map((json) => StateLocalModel.fromLocalJson(json)).toList();

      print('✅ [LOCATION_DB] Retrieved ${states.length} states');
      return states;
    } catch (e) {
      print('❌ [LOCATION_DB] Error getting all states: $e');
      rethrow;
    }
  }

  /// Get state by ID
  Future<StateLocalModel?> getStateById(int id) async {
    try {
      final db = await _dbHelper.database;
      final maps = await db.query(
        'states',
        where: 'id = ?',
        whereArgs: [id],
      );

      if (maps.isEmpty) return null;
      return StateLocalModel.fromLocalJson(maps.first);
    } catch (e) {
      print('❌ [LOCATION_DB] Error getting state by ID: $e');
      rethrow;
    }
  }

  /// Delete all states
  Future<void> deleteAllStates() async {
    try {
      final db = await _dbHelper.database;
      await db.delete('states');
      print('✅ [LOCATION_DB] Deleted all states');
    } catch (e) {
      print('❌ [LOCATION_DB] Error deleting all states: $e');
      rethrow;
    }
  }

  // ============ CITIES OPERATIONS ============

  /// Insert or replace city
  Future<void> insertOrReplaceCity(CityLocalModel city) async {
    try {
      final db = await _dbHelper.database;
      await db.insert(
        'cities',
        city.toLocalJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      print('✅ [LOCATION_DB] Inserted/Updated city: ${city.name} (ID: ${city.id})');
    } catch (e) {
      print('❌ [LOCATION_DB] Error inserting city: $e');
      rethrow;
    }
  }

  /// Batch insert cities
  Future<void> insertBatchCities(List<CityLocalModel> cities) async {
    try {
      final db = await _dbHelper.database;
      final batch = db.batch();

      for (final city in cities) {
        batch.insert(
          'cities',
          city.toLocalJson(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      await batch.commit();
      print('✅ [LOCATION_DB] Batch inserted ${cities.length} cities');
    } catch (e) {
      print('❌ [LOCATION_DB] Error batch inserting cities: $e');
      rethrow;
    }
  }

  /// Get all cities
  Future<List<CityLocalModel>> getAllCities() async {
    try {
      final db = await _dbHelper.database;
      final maps = await db.query('cities', orderBy: 'name ASC');

      final cities =
          maps.map((json) => CityLocalModel.fromLocalJson(json)).toList();

      print('✅ [LOCATION_DB] Retrieved ${cities.length} cities');
      return cities;
    } catch (e) {
      print('❌ [LOCATION_DB] Error getting all cities: $e');
      rethrow;
    }
  }

  /// Get cities by state ID
  Future<List<CityLocalModel>> getCitiesByState(int stateId) async {
    try {
      final db = await _dbHelper.database;
      final maps = await db.query(
        'cities',
        where: 'state_id = ?',
        whereArgs: [stateId],
        orderBy: 'name ASC',
      );

      final cities =
          maps.map((json) => CityLocalModel.fromLocalJson(json)).toList();

      print('✅ [LOCATION_DB] Retrieved ${cities.length} cities for state $stateId');
      return cities;
    } catch (e) {
      print('❌ [LOCATION_DB] Error getting cities by state: $e');
      rethrow;
    }
  }

  /// Get city by ID
  Future<CityLocalModel?> getCityById(int id) async {
    try {
      final db = await _dbHelper.database;
      final maps = await db.query(
        'cities',
        where: 'id = ?',
        whereArgs: [id],
      );

      if (maps.isEmpty) return null;
      return CityLocalModel.fromLocalJson(maps.first);
    } catch (e) {
      print('❌ [LOCATION_DB] Error getting city by ID: $e');
      rethrow;
    }
  }

  /// Delete all cities
  Future<void> deleteAllCities() async {
    try {
      final db = await _dbHelper.database;
      await db.delete('cities');
      print('✅ [LOCATION_DB] Deleted all cities');
    } catch (e) {
      print('❌ [LOCATION_DB] Error deleting all cities: $e');
      rethrow;
    }
  }

  // ============ DISTRICTS OPERATIONS ============

  /// Insert or replace district
  Future<void> insertOrReplaceDistrict(DistrictLocalModel district) async {
    try {
      final db = await _dbHelper.database;
      await db.insert(
        'districts',
        district.toLocalJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      print('✅ [LOCATION_DB] Inserted/Updated district: ${district.name} (ID: ${district.id})');
    } catch (e) {
      print('❌ [LOCATION_DB] Error inserting district: $e');
      rethrow;
    }
  }

  /// Batch insert districts
  Future<void> insertBatchDistricts(List<DistrictLocalModel> districts) async {
    try {
      final db = await _dbHelper.database;
      final batch = db.batch();

      for (final district in districts) {
        batch.insert(
          'districts',
          district.toLocalJson(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      await batch.commit();
      print('✅ [LOCATION_DB] Batch inserted ${districts.length} districts');
    } catch (e) {
      print('❌ [LOCATION_DB] Error batch inserting districts: $e');
      rethrow;
    }
  }

  /// Get all districts
  Future<List<DistrictLocalModel>> getAllDistricts() async {
    try {
      final db = await _dbHelper.database;
      final maps = await db.query('districts', orderBy: 'name ASC');

      final districts =
          maps.map((json) => DistrictLocalModel.fromLocalJson(json)).toList();

      print('✅ [LOCATION_DB] Retrieved ${districts.length} districts');
      return districts;
    } catch (e) {
      print('❌ [LOCATION_DB] Error getting all districts: $e');
      rethrow;
    }
  }

  /// Get districts by city ID
  Future<List<DistrictLocalModel>> getDistrictsByCity(int cityId) async {
    try {
      final db = await _dbHelper.database;
      final maps = await db.query(
        'districts',
        where: 'city_id = ?',
        whereArgs: [cityId],
        orderBy: 'name ASC',
      );

      final districts =
          maps.map((json) => DistrictLocalModel.fromLocalJson(json)).toList();

      print('✅ [LOCATION_DB] Retrieved ${districts.length} districts for city $cityId');
      return districts;
    } catch (e) {
      print('❌ [LOCATION_DB] Error getting districts by city: $e');
      rethrow;
    }
  }

  /// Get district by ID
  Future<DistrictLocalModel?> getDistrictById(int id) async {
    try {
      final db = await _dbHelper.database;
      final maps = await db.query(
        'districts',
        where: 'id = ?',
        whereArgs: [id],
      );

      if (maps.isEmpty) return null;
      return DistrictLocalModel.fromLocalJson(maps.first);
    } catch (e) {
      print('❌ [LOCATION_DB] Error getting district by ID: $e');
      rethrow;
    }
  }

  /// Delete all districts
  Future<void> deleteAllDistricts() async {
    try {
      final db = await _dbHelper.database;
      await db.delete('districts');
      print('✅ [LOCATION_DB] Deleted all districts');
    } catch (e) {
      print('❌ [LOCATION_DB] Error deleting all districts: $e');
      rethrow;
    }
  }

  // ============ HELPER METHODS ============

  /// Get count of each location type
  Future<Map<String, int>> getLocationCounts() async {
    try {
      final db = await _dbHelper.database;

      final stateCount = Sqflite.firstIntValue(
            await db.rawQuery('SELECT COUNT(*) FROM states'),
          ) ?? 0;
      final cityCount = Sqflite.firstIntValue(
            await db.rawQuery('SELECT COUNT(*) FROM cities'),
          ) ?? 0;
      final districtCount = Sqflite.firstIntValue(
            await db.rawQuery('SELECT COUNT(*) FROM districts'),
          ) ?? 0;

      final counts = {
        'states': stateCount,
        'cities': cityCount,
        'districts': districtCount,
      };

      print('📊 [LOCATION_DB] Location counts: $counts');
      return counts;
    } catch (e) {
      print('❌ [LOCATION_DB] Error getting location counts: $e');
      rethrow;
    }
  }
}
