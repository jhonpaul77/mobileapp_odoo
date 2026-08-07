import 'database_helper.dart';

/// Product Local Database - Manages product data in SQLite
///
/// Handles:
/// - Storing products from API
/// - Querying products locally
/// - Syncing product data
class ProductLocalDatabase {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  /// Insert or update products (upsert)
  Future<int> upsertProducts(List<Map<String, dynamic>> products) async {
    final db = await _dbHelper.database;
    int upsertCount = 0;

    try {
      print('📦 [PRODUCT_DB] Upserting ${products.length} products...');

      // Ensure products table exists first - CRITICAL!
      await _dbHelper.ensureProductsTable();
      
      // Wait a moment to ensure table is created
      await Future.delayed(const Duration(milliseconds: 100));

      for (var product in products) {
        try {
          final id = product['id'] as int;
          final name = product['name'] as String?;
          final type = product['type'] as String? ?? 'product';
          final isStorable = product['is_storable'] as bool? ?? false;
          final defaultCode = product['default_code'];
          final listPrice = (product['list_price'] as num?)?.toDouble() ?? 0.0;
          final qtyAvailable = (product['qty_available'] as num?)?.toDouble() ?? 0.0;
          final categoryId = product['category_id'];
          final categName = product['categ_name'] ?? '';

          // Check if product exists
          final existing = await db.query(
            'products',
            where: 'id = ?',
            whereArgs: [id],
            limit: 1,
          );

          if (existing.isEmpty) {
            // Insert new
            await db.insert('products', {
              'id': id,
              'name': name,
              'type': type,
              'is_storable': isStorable ? 1 : 0,
              'default_code': defaultCode,
              'list_price': listPrice,
              'qty_available': qtyAvailable,
              'category_id': categoryId,
              'categ_name': categName,
              'sync_status': 'SYNCED',
              'synced_at': DateTime.now().toIso8601String(),
            });
            upsertCount++;
          } else {
            // Update existing
            await db.update(
              'products',
              {
                'name': name,
                'type': type,
                'is_storable': isStorable ? 1 : 0,
                'default_code': defaultCode,
                'list_price': listPrice,
                'qty_available': qtyAvailable,
                'category_id': categoryId,
                'categ_name': categName,
                'sync_status': 'SYNCED',
                'synced_at': DateTime.now().toIso8601String(),
              },
              where: 'id = ?',
              whereArgs: [id],
            );
            upsertCount++;
          }
        } catch (productError) {
          print('⚠️ [PRODUCT_DB] Error upserting product ${product['id']}: $productError');
          // Continue with next product instead of failing entire upsert
        }
      }

      print('✅ [PRODUCT_DB] Upserted $upsertCount products');
      return upsertCount;
    } catch (e) {
      print('❌ [PRODUCT_DB] Error upserting products: $e');
      rethrow;
    }
  }

  /// Get all products
  Future<List<Map<String, dynamic>>> getAllProducts() async {
    final db = await _dbHelper.database;

    try {
      print('📦 [PRODUCT_DB] Fetching all products...');
      
      // Ensure table exists
      await _dbHelper.ensureProductsTable();

      final products = await db.query(
        'products',
        orderBy: 'name ASC',
      );

      print('✅ [PRODUCT_DB] Fetched ${products.length} products');
      return products;
    } catch (e) {
      print('❌ [PRODUCT_DB] Error fetching products: $e');
      return [];
    }
  }

  /// Get product by ID
  Future<Map<String, dynamic>?> getProductById(int id) async {
    final db = await _dbHelper.database;

    try {
      final products = await db.query(
        'products',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      return products.isNotEmpty ? products.first : null;
    } catch (e) {
      print('❌ [PRODUCT_DB] Error fetching product by ID: $e');
      rethrow;
    }
  }

  /// Search products by name or code
  Future<List<Map<String, dynamic>>> searchProducts(String query) async {
    final db = await _dbHelper.database;

    try {
      final searchQuery = '%$query%';
      final products = await db.query(
        'products',
        where: 'name LIKE ? OR default_code LIKE ?',
        whereArgs: [searchQuery, searchQuery],
        orderBy: 'name ASC',
      );

      return products;
    } catch (e) {
      print('❌ [PRODUCT_DB] Error searching products: $e');
      rethrow;
    }
  }

  /// Get products by category
  Future<List<Map<String, dynamic>>> getProductsByCategory(String category) async {
    final db = await _dbHelper.database;

    try {
      final products = await db.query(
        'products',
        where: 'categ_name = ?',
        whereArgs: [category],
        orderBy: 'name ASC',
      );

      return products;
    } catch (e) {
      print('❌ [PRODUCT_DB] Error fetching products by category: $e');
      rethrow;
    }
  }

  /// Get product count
  Future<int> getProductCount() async {
    final db = await _dbHelper.database;

    try {
      // Ensure table exists first
      await _dbHelper.ensureProductsTable();
      
      final result = await db.rawQuery('SELECT COUNT(*) as count FROM products');
      return (result.first['count'] as int?) ?? 0;
    } catch (e) {
      print('❌ [PRODUCT_DB] Error getting product count: $e');
      return 0;
    }
  }

  /// Clear all products
  Future<void> clearAllProducts() async {
    final db = await _dbHelper.database;

    try {
      print('⚠️ [PRODUCT_DB] Clearing all products...');
      await db.delete('products');
      print('✅ [PRODUCT_DB] All products cleared');
    } catch (e) {
      print('❌ [PRODUCT_DB] Error clearing products: $e');
      rethrow;
    }
  }

  /// Get sync stats
  Future<Map<String, dynamic>> getSyncStats() async {
    final db = await _dbHelper.database;

    try {
      // Ensure table exists first
      await _dbHelper.ensureProductsTable();
      
      final totalResult =
          await db.rawQuery('SELECT COUNT(*) as count FROM products');
      final total = (totalResult.first['count'] as int?) ?? 0;

      final syncedResult = await db.rawQuery(
        'SELECT COUNT(*) as count FROM products WHERE sync_status = ?',
        ['SYNCED'],
      );
      final synced = (syncedResult.first['count'] as int?) ?? 0;

      return {
        'total': total,
        'synced': synced,
        'pending': total - synced,
      };
    } catch (e) {
      print('❌ [PRODUCT_DB] Error getting sync stats: $e');
      return {'total': 0, 'synced': 0, 'pending': 0};
    }
  }
}
