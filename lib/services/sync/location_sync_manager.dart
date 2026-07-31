import '../../features/customer/data/models/location_models.dart';
import '../local_database/location_local_database.dart';

/// LocationSyncManager - Handles syncing States, Cities, Districts
///
/// Manages semua logic untuk sync data lokasi dari API ke local DB
class LocationSyncManager {
  final LocationLocalDatabase _locationDb = LocationLocalDatabase();

  /// Sync states dari remote ke local DB
  Future<void> syncStates(List<StateLocalModel> remoteStates) async {
    try {
      print('🔄 [LOCATION_SYNC] Syncing ${remoteStates.length} states...');

      // Delete all existing states (full sync)
      await _locationDb.deleteAllStates();

      // Insert all remote states
      await _locationDb.insertBatchStates(remoteStates);

      print('✅ [LOCATION_SYNC] States sync completed: ${remoteStates.length} total');
    } catch (e) {
      print('❌ [LOCATION_SYNC] Error syncing states: $e');
      rethrow;
    }
  }

  /// Sync cities dari remote ke local DB
  Future<void> syncCities(List<CityLocalModel> remoteCities) async {
    try {
      print('🔄 [LOCATION_SYNC] Syncing ${remoteCities.length} cities...');

      // Delete all existing cities (full sync)
      await _locationDb.deleteAllCities();

      // Insert all remote cities
      await _locationDb.insertBatchCities(remoteCities);

      print('✅ [LOCATION_SYNC] Cities sync completed: ${remoteCities.length} total');
    } catch (e) {
      print('❌ [LOCATION_SYNC] Error syncing cities: $e');
      rethrow;
    }
  }

  /// Sync districts dari remote ke local DB
  Future<void> syncDistricts(List<DistrictLocalModel> remoteDistricts) async {
    try {
      print('🔄 [LOCATION_SYNC] Syncing ${remoteDistricts.length} districts...');

      // Delete all existing districts (full sync)
      await _locationDb.deleteAllDistricts();

      // Insert all remote districts
      await _locationDb.insertBatchDistricts(remoteDistricts);

      print('✅ [LOCATION_SYNC] Districts sync completed: ${remoteDistricts.length} total');
    } catch (e) {
      print('❌ [LOCATION_SYNC] Error syncing districts: $e');
      rethrow;
    }
  }

  /// Get sync statistics untuk locations
  Future<Map<String, int>> getLocationStats() async {
    try {
      final counts = await _locationDb.getLocationCounts();
      print('📊 [LOCATION_SYNC] Location stats: $counts');
      return counts;
    } catch (e) {
      print('⚠️ [LOCATION_SYNC] Error getting location stats: $e');
      return {'states': 0, 'cities': 0, 'districts': 0};
    }
  }
}
