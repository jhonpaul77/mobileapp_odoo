import '../../features/customer/data/models/customer_local_model.dart';
import '../../features/customer/domain/entities/customer.dart';
import '../local_database/customer_local_database.dart';

/// SyncResult - Result from a sync operation
class SyncResult {
  final int totalCount;
  final int newCount;
  final int updatedCount;
  final int deletedCount;
  final int durationMs;
  final List<String> messages;

  SyncResult({
    required this.totalCount,
    required this.newCount,
    required this.updatedCount,
    required this.deletedCount,
    required this.durationMs,
    this.messages = const [],
  });

  /// Get summary text
  String get summary =>
      'Synced: $totalCount total, $newCount new, $updatedCount updated, $deletedCount deleted (${durationMs}ms)';

  /// Check if there were any changes
  bool get hasChanges => newCount > 0 || updatedCount > 0 || deletedCount > 0;
}

/// CustomerSyncManager - Handles sync between local DB and backend
///
/// Strategy:
/// 1. Fetch all customers from backend
/// 2. Compare with local DB
/// 3. Identify changes (new, updated, deleted)
/// 4. Update local DB with sync flags
/// 5. Log sync event
class CustomerSyncManager {
  static final CustomerSyncManager _instance = CustomerSyncManager._internal();
  final CustomerLocalDatabase _localDb = CustomerLocalDatabase();

  factory CustomerSyncManager() {
    return _instance;
  }

  CustomerSyncManager._internal();

  /// Main sync operation
  ///
  /// Parameters:
  /// - remoteCustomers: List of customers from backend
  ///
  /// Returns: SyncResult with detailed sync information
  Future<SyncResult> sync(List<Customer> remoteCustomers) async {
    try {
      final startTime = DateTime.now();
      print('🔄 [SYNC_MANAGER] Starting customer sync...');
      print('   [SYNC_MANAGER] Remote customers: ${remoteCustomers.length}');

      // Get all local customers
      final localCustomers = await _localDb.getAllCustomers();
      print('   [SYNC_MANAGER] Local customers: ${localCustomers.length}');

      // Create maps for quick lookup
      final localMap = {for (final c in localCustomers) c.id: c};
      final remoteMap = {for (final c in remoteCustomers) c.id: c};

      int newCount = 0;
      int updatedCount = 0;
      int deletedCount = 0;
      final messages = <String>[];

      // STEP 1: Identify NEW customers (in remote but not in local)
      for (final remoteCustomer in remoteCustomers) {
        if (!localMap.containsKey(remoteCustomer.id)) {
          print('   🆕 NEW: ${remoteCustomer.name} (ID: ${remoteCustomer.id})');

          final newLocalCustomer = CustomerLocalModel.fromEntity(
            remoteCustomer,
            syncStatus: SyncStatus.SYNCED,
            remoteUpdatedAt: DateTime.now(),
          );

          await _localDb.insertOrReplace(newLocalCustomer);
          newCount++;
          messages.add('➕ New: ${remoteCustomer.name}');
        }
      }

      // STEP 2: Identify UPDATED customers (in both, but different)
      for (final remoteCustomer in remoteCustomers) {
        final local = localMap[remoteCustomer.id];
        if (local != null && _hasChanged(local, remoteCustomer)) {
          print(
              '   ✏️ UPDATED: ${remoteCustomer.name} (ID: ${remoteCustomer.id})');

          final updatedLocalCustomer = CustomerLocalModel(
            id: remoteCustomer.id,
            name: remoteCustomer.name,
            email: remoteCustomer.email,
            phone: remoteCustomer.phone,
            userId: remoteCustomer.userId,
            street: remoteCustomer.street,
            street2: remoteCustomer.street2,
            districtId: remoteCustomer.districtId,
            cityId: remoteCustomer.cityId,
            stateId: remoteCustomer.stateId,
            zip: remoteCustomer.zip,
            countryId: remoteCustomer.countryId,
            syncStatus: SyncStatus.SYNCED,
            remoteUpdatedAt: DateTime.now(),
            localCreatedAt: local.localCreatedAt,
            localUpdatedAt: DateTime.now(),
            syncedAt: DateTime.now(),
          );

          await _localDb.insertOrReplace(updatedLocalCustomer);
          updatedCount++;
          messages.add('✏️ Updated: ${remoteCustomer.name}');
        }
      }

      // STEP 3: Identify DELETED customers (in local but not in remote)
      for (final localCustomer in localCustomers) {
        if (!remoteMap.containsKey(localCustomer.id)) {
          print(
              '   🗑️ DELETED: ${localCustomer.name} (ID: ${localCustomer.id})');

          // Mark as deleted instead of removing (soft delete for history)
          await _localDb.updateSyncStatus(localCustomer.id, SyncStatus.DELETED);
          deletedCount++;
          messages.add('🗑️ Deleted: ${localCustomer.name}');
        }
      }

      // Log sync event
      final durationMs = DateTime.now().difference(startTime).inMilliseconds;
      await _localDb.insertSyncLog(
        entityType: 'customer',
        totalCount: remoteCustomers.length,
        newCount: newCount,
        updatedCount: updatedCount,
        deletedCount: deletedCount,
        durationMs: durationMs,
      );

      final result = SyncResult(
        totalCount: remoteCustomers.length,
        newCount: newCount,
        updatedCount: updatedCount,
        deletedCount: deletedCount,
        durationMs: durationMs,
        messages: messages,
      );

      print('✅ [SYNC_MANAGER] Sync completed: ${result.summary}');
      for (final msg in messages) {
        print('   $msg');
      }

      return result;
    } catch (e, stackTrace) {
      print('❌ [SYNC_MANAGER] Sync error: $e');
      print('   Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Check if customer data has changed
  ///
  /// Compares relevant fields between local and remote
  bool _hasChanged(CustomerLocalModel local, Customer remote) {
    // Compare all relevant fields
    return local.name != remote.name ||
        local.email != remote.email ||
        local.phone != remote.phone ||
        local.street != remote.street ||
        local.street2 != remote.street2 ||
        local.districtId != remote.districtId ||
        local.cityId != remote.cityId ||
        local.stateId != remote.stateId ||
        local.zip != remote.zip ||
        local.countryId != remote.countryId;
  }

  /// Get sync statistics
  Future<Map<String, dynamic>> getSyncStats() async {
    try {
      final counts = await _localDb.getSyncStatusCounts();
      final lastSync = await _localDb.getLastSyncTime();

      return {
        'total': counts['total'],
        'synced': counts['synced'],
        'new': counts['new'],
        'updated': counts['updated'],
        'deleted': counts['deleted'],
        'lastSync': lastSync?.toIso8601String(),
        'needsSync': (counts['new'] ?? 0) +
            (counts['updated'] ?? 0) +
            (counts['deleted'] ?? 0),
      };
    } catch (e) {
      print('❌ [SYNC_MANAGER] Error getting sync stats: $e');
      rethrow;
    }
  }
}
