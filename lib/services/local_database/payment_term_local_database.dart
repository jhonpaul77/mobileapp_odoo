import 'database_helper.dart';

/// PaymentTermLocalDatabase - Manages payment terms in local SQLite database
class PaymentTermLocalDatabase {
  final _dbHelper = DatabaseHelper();

  /// Get all payment terms count
  Future<int> getPaymentTermCount() async {
    try {
      // Ensure table exists first
      await _dbHelper.ensurePaymentTermsTable();
      
      final db = await _dbHelper.database;
      final result = await db.rawQuery('SELECT COUNT(*) FROM payment_terms');
      
      final count = (result.first['COUNT(*)'] as int?) ?? 0;
      print('✅ [PAYMENT_TERM_DB] Payment term count: $count');
      
      return count;
    } catch (e) {
      print('❌ [PAYMENT_TERM_DB] Error getting payment term count: $e');
      return 0;
    }
  }

  /// Upsert payment terms - insert or update if exists
  /// Returns count of affected records
  Future<int> upsertPaymentTerms(List<Map<String, dynamic>> paymentTerms) async {
    try {
      // Ensure table exists first
      await _dbHelper.ensurePaymentTermsTable();
      
      final db = await _dbHelper.database;
      final now = DateTime.now().toIso8601String();
      int affectedCount = 0;

      print('📝 [PAYMENT_TERM_DB] Upserting ${paymentTerms.length} payment terms...');

      for (final term in paymentTerms) {
        final id = term['id'] as int?;
        final name = term['name'] as String?;
        final description = term['description'] ?? '';

        if (id == null || name == null) {
          print('   ⚠️ Skipping term with missing id or name: $term');
          continue;
        }

        // Check if exists
        final existing = await db.query(
          'payment_terms',
          where: 'id = ?',
          whereArgs: [id],
          limit: 1,
        );

        if (existing.isEmpty) {
          // Insert new
          await db.insert(
            'payment_terms',
            {
              'id': id,
              'name': name,
              'description': description,
              'sync_status': 'SYNCED',
              'synced_at': now,
            },
          );
          affectedCount++;
          print('   ✅ Inserted: $name (ID: $id)');
        } else {
          // Update existing
          await db.update(
            'payment_terms',
            {
              'name': name,
              'description': description,
              'sync_status': 'SYNCED',
              'synced_at': now,
            },
            where: 'id = ?',
            whereArgs: [id],
          );
          affectedCount++;
          print('   ✅ Updated: $name (ID: $id)');
        }
      }

      print('✅ [PAYMENT_TERM_DB] Upserted $affectedCount payment terms');
      return affectedCount;
    } catch (e) {
      print('❌ [PAYMENT_TERM_DB] Error upserting payment terms: $e');
      return 0;
    }
  }

  /// Get all payment terms
  Future<List<Map<String, dynamic>>> getAllPaymentTerms() async {
    try {
      // Ensure table exists first
      await _dbHelper.ensurePaymentTermsTable();
      
      final db = await _dbHelper.database;
      final result = await db.query('payment_terms');
      
      print('✅ [PAYMENT_TERM_DB] Retrieved ${result.length} payment terms');
      return result;
    } catch (e) {
      print('❌ [PAYMENT_TERM_DB] Error getting payment terms: $e');
      return [];
    }
  }

  /// Delete all payment terms
  Future<int> deleteAllPaymentTerms() async {
    try {
      // Ensure table exists first
      await _dbHelper.ensurePaymentTermsTable();
      
      final db = await _dbHelper.database;
      final count = await db.delete('payment_terms');
      
      print('✅ [PAYMENT_TERM_DB] Deleted $count payment terms');
      return count;
    } catch (e) {
      print('❌ [PAYMENT_TERM_DB] Error deleting payment terms: $e');
      return 0;
    }
  }

  /// Get payment term by ID
  Future<Map<String, dynamic>?> getPaymentTermById(int id) async {
    try {
      // Ensure table exists first
      await _dbHelper.ensurePaymentTermsTable();
      
      final db = await _dbHelper.database;
      final result = await db.query(
        'payment_terms',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (result.isEmpty) {
        print('⚠️ [PAYMENT_TERM_DB] Payment term with ID $id not found');
        return null;
      }

      return result.first;
    } catch (e) {
      print('❌ [PAYMENT_TERM_DB] Error getting payment term by ID: $e');
      return null;
    }
  }
}
