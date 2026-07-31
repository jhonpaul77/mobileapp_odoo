import 'package:sqflite/sqflite.dart';

import '../../features/customer/data/models/customer_local_model.dart';
import 'database_helper.dart';

/// CustomerLocalDatabase - CRUD operations for customers in local SQLite
///
/// Manages all database operations for customer data storage and retrieval
class CustomerLocalDatabase {
  static final CustomerLocalDatabase _instance =
      CustomerLocalDatabase._internal();
  final DatabaseHelper _dbHelper = DatabaseHelper();

  factory CustomerLocalDatabase() {
    return _instance;
  }

  CustomerLocalDatabase._internal();

  /// Insert or replace a customer in local database
  Future<void> insertOrReplace(CustomerLocalModel customer) async {
    try {
      final db = await _dbHelper.database;
      await db.insert(
        'customers',
        customer.toLocalJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      print(
          '✅ [CUSTOMER_LOCAL_DB] Inserted/Updated customer: ${customer.name} (ID: ${customer.id})');
    } catch (e) {
      print('❌ [CUSTOMER_LOCAL_DB] Error inserting customer: $e');
      rethrow;
    }
  }

  /// Insert multiple customers in batch
  Future<void> insertBatch(List<CustomerLocalModel> customers) async {
    try {
      final db = await _dbHelper.database;
      final batch = db.batch();

      for (final customer in customers) {
        batch.insert(
          'customers',
          customer.toLocalJson(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      await batch.commit();
      print(
          '✅ [CUSTOMER_LOCAL_DB] Batch inserted ${customers.length} customers');
    } catch (e) {
      print('❌ [CUSTOMER_LOCAL_DB] Error batch inserting customers: $e');
      rethrow;
    }
  }

  /// Get all customers from local database (excluding deleted)
  Future<List<CustomerLocalModel>> getAllCustomers() async {
    try {
      final db = await _dbHelper.database;
      final maps = await db.query(
        'customers',
        where: 'sync_status != ?',
        whereArgs: ['DELETED'],
        orderBy: 'name ASC',
      );

      final customers =
          maps.map((json) => CustomerLocalModel.fromLocalJson(json)).toList();

      print('✅ [CUSTOMER_LOCAL_DB] Retrieved ${customers.length} customers (excluding deleted)');
      return customers;
    } catch (e) {
      print('❌ [CUSTOMER_LOCAL_DB] Error getting all customers: $e');
      rethrow;
    }
  }

  /// Get customer by ID
  Future<CustomerLocalModel?> getCustomerById(int id) async {
    try {
      final db = await _dbHelper.database;
      final maps = await db.query(
        'customers',
        where: 'id = ?',
        whereArgs: [id],
      );

      if (maps.isEmpty) {
        print('ℹ️ [CUSTOMER_LOCAL_DB] Customer not found: ID $id');
        return null;
      }

      final customer = CustomerLocalModel.fromLocalJson(maps.first);
      print('✅ [CUSTOMER_LOCAL_DB] Retrieved customer: ${customer.name}');
      return customer;
    } catch (e) {
      print('❌ [CUSTOMER_LOCAL_DB] Error getting customer by ID: $e');
      rethrow;
    }
  }

  /// Get customers with specific sync status
  Future<List<CustomerLocalModel>> getCustomersByStatus(
      SyncStatus status) async {
    try {
      final db = await _dbHelper.database;
      final statusStr = status.toString().split('.').last;

      final maps = await db.query(
        'customers',
        where: 'sync_status = ?',
        whereArgs: [statusStr],
        orderBy: 'name ASC',
      );

      final customers =
          maps.map((json) => CustomerLocalModel.fromLocalJson(json)).toList();

      print(
          '✅ [CUSTOMER_LOCAL_DB] Retrieved ${customers.length} customers with status $statusStr');
      return customers;
    } catch (e) {
      print('❌ [CUSTOMER_LOCAL_DB] Error getting customers by status: $e');
      rethrow;
    }
  }

  /// Get customers that need syncing (NEW, UPDATED, DELETED)
  Future<List<CustomerLocalModel>> getCustomersNeedingSync() async {
    try {
      final db = await _dbHelper.database;
      final maps = await db.query(
        'customers',
        where:
            'sync_status IN (?, ?, ?)',
        whereArgs: ['NEW', 'UPDATED', 'DELETED'],
        orderBy: 'local_updated_at ASC',
      );

      final customers =
          maps.map((json) => CustomerLocalModel.fromLocalJson(json)).toList();

      print(
          '✅ [CUSTOMER_LOCAL_DB] Retrieved ${customers.length} customers needing sync');
      return customers;
    } catch (e) {
      print('❌ [CUSTOMER_LOCAL_DB] Error getting customers needing sync: $e');
      rethrow;
    }
  }

  /// Update customer sync status
  Future<void> updateSyncStatus(int customerId, SyncStatus status) async {
    try {
      final db = await _dbHelper.database;
      final statusStr = status.toString().split('.').last;

      await db.update(
        'customers',
        {
          'sync_status': statusStr,
          'synced_at': status == SyncStatus.SYNCED
              ? DateTime.now().toIso8601String()
              : null,
        },
        where: 'id = ?',
        whereArgs: [customerId],
      );

      print(
          '✅ [CUSTOMER_LOCAL_DB] Updated customer sync status: ID $customerId → $statusStr');
    } catch (e) {
      print('❌ [CUSTOMER_LOCAL_DB] Error updating sync status: $e');
      rethrow;
    }
  }

  /// Update customer data
  Future<void> updateCustomer(CustomerLocalModel customer) async {
    try {
      final db = await _dbHelper.database;
      await db.update(
        'customers',
        customer.toLocalJson(),
        where: 'id = ?',
        whereArgs: [customer.id],
      );

      print(
          '✅ [CUSTOMER_LOCAL_DB] Updated customer: ${customer.name} (ID: ${customer.id})');
    } catch (e) {
      print('❌ [CUSTOMER_LOCAL_DB] Error updating customer: $e');
      rethrow;
    }
  }

  /// Delete customer by ID
  Future<void> deleteCustomer(int id) async {
    try {
      final db = await _dbHelper.database;
      await db.delete(
        'customers',
        where: 'id = ?',
        whereArgs: [id],
      );

      print('✅ [CUSTOMER_LOCAL_DB] Deleted customer: ID $id');
    } catch (e) {
      print('❌ [CUSTOMER_LOCAL_DB] Error deleting customer: $e');
      rethrow;
    }
  }

  /// Delete all customers
  Future<void> deleteAllCustomers() async {
    try {
      final db = await _dbHelper.database;
      await db.delete('customers');
      print('✅ [CUSTOMER_LOCAL_DB] Deleted all customers');
    } catch (e) {
      print('❌ [CUSTOMER_LOCAL_DB] Error deleting all customers: $e');
      rethrow;
    }
  }

  /// Get customer count by sync status
  Future<Map<String, int>> getSyncStatusCounts() async {
    try {
      final db = await _dbHelper.database;

      final synced = Sqflite.firstIntValue(await db.rawQuery(
            'SELECT COUNT(*) FROM customers WHERE sync_status = ?',
            ['SYNCED'],
          )) ??
          0;
      final new_ = Sqflite.firstIntValue(await db.rawQuery(
            'SELECT COUNT(*) FROM customers WHERE sync_status = ?',
            ['NEW'],
          )) ??
          0;
      final updated = Sqflite.firstIntValue(await db.rawQuery(
            'SELECT COUNT(*) FROM customers WHERE sync_status = ?',
            ['UPDATED'],
          )) ??
          0;
      final deleted = Sqflite.firstIntValue(await db.rawQuery(
            'SELECT COUNT(*) FROM customers WHERE sync_status = ?',
            ['DELETED'],
          )) ??
          0;
      final total = Sqflite.firstIntValue(
            await db.rawQuery('SELECT COUNT(*) FROM customers'),
          ) ??
          0;

      final counts = {
        'total': total,
        'synced': synced,
        'new': new_,
        'updated': updated,
        'deleted': deleted,
      };

      print('📊 [CUSTOMER_LOCAL_DB] Sync status counts: $counts');
      return counts;
    } catch (e) {
      print('❌ [CUSTOMER_LOCAL_DB] Error getting sync status counts: $e');
      rethrow;
    }
  }

  /// Get last sync timestamp
  Future<DateTime?> getLastSyncTime() async {
    try {
      final db = await _dbHelper.database;
      final result = await db.rawQuery(
        'SELECT MAX(synced_at) as last_sync FROM customers WHERE sync_status = ?',
        ['SYNCED'],
      );

      if (result.isEmpty || result[0]['last_sync'] == null) {
        print('ℹ️ [CUSTOMER_LOCAL_DB] No sync timestamp found');
        return null;
      }

      final lastSync =
          DateTime.parse(result[0]['last_sync'] as String);
      print('✅ [CUSTOMER_LOCAL_DB] Last sync: $lastSync');
      return lastSync;
    } catch (e) {
      print('❌ [CUSTOMER_LOCAL_DB] Error getting last sync time: $e');
      rethrow;
    }
  }

  /// Insert sync log
  Future<void> insertSyncLog({
    required String entityType,
    required int totalCount,
    required int newCount,
    required int updatedCount,
    required int deletedCount,
    required int durationMs,
  }) async {
    try {
      final db = await _dbHelper.database;
      await db.insert('sync_logs', {
        'entity_type': entityType,
        'total_count': totalCount,
        'new_count': newCount,
        'updated_count': updatedCount,
        'deleted_count': deletedCount,
        'synced_at': DateTime.now().toIso8601String(),
        'duration_ms': durationMs,
      });

      print(
          '✅ [CUSTOMER_LOCAL_DB] Logged sync: $entityType (Total: $totalCount, New: $newCount, Updated: $updatedCount, Deleted: $deletedCount, Duration: ${durationMs}ms)');
    } catch (e) {
      print('❌ [CUSTOMER_LOCAL_DB] Error inserting sync log: $e');
      rethrow;
    }
  }

  /// Search customers by name or phone in local database
  /// Supports search with different phone formats: 0821, 62821, +62821
  Future<List<CustomerLocalModel>> searchCustomers(String query) async {
    try {
      if (query.isEmpty) {
        return await getAllCustomers();
      }

      final db = await _dbHelper.database;
      final searchTerm = '%$query%';

      // Normalize phone search formats
      List<String> phoneVariants = [query]; // Original query

      if (query.startsWith('0')) {
        // If starts with 0, also search with +62
        phoneVariants.add('+62${query.substring(1)}');
      } else if (query.startsWith('62')) {
        // If starts with 62, also search with +62
        phoneVariants.add('+$query');
      }

      // Build WHERE clause with LIKE for name and multiple phone formats
      final whereConditions = <String>[];
      final whereArgs = <String>[];

      // Name search
      whereConditions.add('name LIKE ?');
      whereArgs.add(searchTerm);

      // Phone search - any of the variants
      final phoneConditions =
          phoneVariants.map((_) => 'phone LIKE ?').toList();
      whereConditions.add('(${phoneConditions.join(' OR ')})');
      whereArgs.addAll(phoneVariants.map((p) => '%$p%'));

      final fullWhere = '(${whereConditions.join(') OR (')})';

      final maps = await db.query(
        'customers',
        where: fullWhere,
        whereArgs: whereArgs,
        orderBy: 'name ASC',
      );

      final customers =
          maps.map((json) => CustomerLocalModel.fromLocalJson(json)).toList();

      print(
          '🔍 [CUSTOMER_LOCAL_DB] Search "$query": ${customers.length} results');
      return customers;
    } catch (e) {
      print('❌ [CUSTOMER_LOCAL_DB] Error searching customers: $e');
      rethrow;
    }
  }
}
