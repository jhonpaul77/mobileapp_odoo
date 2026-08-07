import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// DatabaseHelper - Handles SQLite database initialization and management
///
/// Singleton pattern - ensures only one database connection
/// Tables: customers, sync_logs, states, cities, districts, products
class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() {
    return _instance;
  }

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Initialize database - create tables if they don't exist
  Future<Database> _initDatabase() async {
    try {
      print('🔄 [DB_HELPER] Initializing SQLite database...');

      final databasesPath = await getDatabasesPath();
      final path = join(databasesPath, 'pintarx.db');

      print('   [DB_HELPER] Database path: $path');

      // Open database (create if doesn't exist)
      final db = await openDatabase(
        path,
        version: 4,
        onCreate: _createTables,
        onUpgrade: _upgradeTables,
      );

      print('✅ [DB_HELPER] Database initialized successfully');
      return db;
    } catch (e) {
      print('❌ [DB_HELPER] Error initializing database: $e');
      rethrow;
    }
  }

  /// Create tables in database
  Future<void> _createTables(Database db, int version) async {
    try {
      print('🔄 [DB_HELPER] Creating tables...');

      // Customers table with sync fields
      await db.execute('''
        CREATE TABLE customers (
          id INTEGER PRIMARY KEY,
          name TEXT NOT NULL,
          email TEXT,
          phone TEXT,
          street TEXT,
          street2 TEXT,
          district_id INTEGER,
          city_id INTEGER,
          state_id INTEGER,
          zip TEXT,
          country_id INTEGER,
          sync_status TEXT DEFAULT 'SYNCED',
          remote_updated_at TEXT,
          local_created_at TEXT,
          local_updated_at TEXT,
          synced_at TEXT,
          changed_fields TEXT
        )
      ''');

      print('   ✅ Created customers table');

      // Sync logs table - for tracking sync history
      await db.execute('''
        CREATE TABLE sync_logs (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          entity_type TEXT,
          total_count INTEGER,
          new_count INTEGER,
          updated_count INTEGER,
          deleted_count INTEGER,
          synced_at TEXT,
          duration_ms INTEGER
        )
      ''');

      print('   ✅ Created sync_logs table');

      // States table
      await db.execute('''
        CREATE TABLE states (
          id INTEGER PRIMARY KEY,
          name TEXT NOT NULL,
          code TEXT,
          sync_status TEXT DEFAULT 'SYNCED',
          synced_at TEXT
        )
      ''');

      print('   ✅ Created states table');

      // Cities table
      await db.execute('''
        CREATE TABLE cities (
          id INTEGER PRIMARY KEY,
          name TEXT NOT NULL,
          state_id INTEGER,
          sync_status TEXT DEFAULT 'SYNCED',
          synced_at TEXT,
          FOREIGN KEY (state_id) REFERENCES states(id)
        )
      ''');

      print('   ✅ Created cities table');

      // Districts table
      await db.execute('''
        CREATE TABLE districts (
          id INTEGER PRIMARY KEY,
          name TEXT NOT NULL,
          city_id INTEGER,
          sync_status TEXT DEFAULT 'SYNCED',
          synced_at TEXT,
          FOREIGN KEY (city_id) REFERENCES cities(id)
        )
      ''');

      print('   ✅ Created districts table');

      // Products table
      await db.execute('''
        CREATE TABLE products (
          id INTEGER PRIMARY KEY,
          name TEXT NOT NULL,
          type TEXT DEFAULT 'product',
          is_storable INTEGER DEFAULT 1,
          default_code TEXT,
          list_price REAL,
          qty_available REAL,
          category_id INTEGER,
          categ_name TEXT,
          sync_status TEXT DEFAULT 'SYNCED',
          synced_at TEXT
        )
      ''');

      print('   ✅ Created products table');

      // Payment Terms table
      await db.execute('''
        CREATE TABLE payment_terms (
          id INTEGER PRIMARY KEY,
          name TEXT NOT NULL,
          description TEXT,
          sync_status TEXT DEFAULT 'SYNCED',
          synced_at TEXT
        )
      ''');

      print('   ✅ Created payment_terms table');

      print('✅ [DB_HELPER] All tables created');
    } catch (e) {
      print('❌ [DB_HELPER] Error creating tables: $e');
      rethrow;
    }
  }

  /// Handle database migrations when schema changes
  Future<void> _upgradeTables(Database db, int oldVersion, int newVersion) async {
    try {
      print('🔄 [DB_HELPER] Upgrading database from version $oldVersion to $newVersion...');

      // Migration from v1 → v2: Add changed_fields column + location tables
      if (oldVersion < 2) {
        print('   [DB_HELPER] Migrating v1 → v2: Adding changed_fields + location tables...');

        try {
          // Check if column already exists (safety check)
          final columns = await db.rawQuery("PRAGMA table_info(customers)");
          final hasChangedFields =
              columns.any((col) => col['name'] == 'changed_fields');

          if (!hasChangedFields) {
            await db.execute('''
              ALTER TABLE customers ADD COLUMN changed_fields TEXT
            ''');
            print('   ✅ Added changed_fields column to customers table');
          } else {
            print('   ℹ️ changed_fields column already exists, skipping');
          }

          // Create location tables if they don't exist
          final tables =
              await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table'");
          final tableNames = tables.map((t) => t['name'] as String).toList();

          if (!tableNames.contains('states')) {
            await db.execute('''
              CREATE TABLE states (
                id INTEGER PRIMARY KEY,
                name TEXT NOT NULL,
                code TEXT,
                sync_status TEXT DEFAULT 'SYNCED',
                synced_at TEXT
              )
            ''');
            print('   ✅ Created states table');
          }

          if (!tableNames.contains('cities')) {
            await db.execute('''
              CREATE TABLE cities (
                id INTEGER PRIMARY KEY,
                name TEXT NOT NULL,
                state_id INTEGER,
                sync_status TEXT DEFAULT 'SYNCED',
                synced_at TEXT,
                FOREIGN KEY (state_id) REFERENCES states(id)
              )
            ''');
            print('   ✅ Created cities table');
          }

          if (!tableNames.contains('districts')) {
            await db.execute('''
              CREATE TABLE districts (
                id INTEGER PRIMARY KEY,
                name TEXT NOT NULL,
                city_id INTEGER,
                sync_status TEXT DEFAULT 'SYNCED',
                synced_at TEXT,
                FOREIGN KEY (city_id) REFERENCES cities(id)
              )
            ''');
            print('   ✅ Created districts table');
          }
        } catch (e) {
          print('   ⚠️ Error in v1→v2 migration: $e');
        }
      }

      // Migration from v2 → v3: Ensure products table exists
      if (oldVersion < 3) {
        print('   [DB_HELPER] Migrating v2 → v3: Ensuring products table...');

        try {
          final tables =
              await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table'");
          final tableNames = tables.map((t) => t['name'] as String).toList();

          if (!tableNames.contains('products')) {
            await db.execute('''
              CREATE TABLE products (
                id INTEGER PRIMARY KEY,
                name TEXT NOT NULL,
                default_code TEXT,
                list_price REAL,
                qty_available REAL,
                category_id INTEGER,
                categ_name TEXT,
                sync_status TEXT DEFAULT 'SYNCED',
                synced_at TEXT
              )
            ''');
            print('   ✅ Created products table');
          } else {
            print('   ℹ️ products table already exists, skipping');
          }
        } catch (e) {
          print('   ⚠️ Error in v2→v3 migration: $e');
        }
      }

      // Migration from v3 → v4: Create payment_terms table
      if (oldVersion < 4) {
        print('   [DB_HELPER] Migrating v3 → v4: Creating payment_terms table...');

        try {
          final tables =
              await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table'");
          final tableNames = tables.map((t) => t['name'] as String).toList();

          if (!tableNames.contains('payment_terms')) {
            await db.execute('''
              CREATE TABLE payment_terms (
                id INTEGER PRIMARY KEY,
                name TEXT NOT NULL,
                description TEXT,
                sync_status TEXT DEFAULT 'SYNCED',
                synced_at TEXT
              )
            ''');
            print('   ✅ Created payment_terms table');
          } else {
            print('   ℹ️ payment_terms table already exists, skipping');
          }
        } catch (e) {
          print('   ⚠️ Error in v3→v4 migration: $e');
        }
      }

      print('✅ [DB_HELPER] Database migration completed');
    } catch (e) {
      print('❌ [DB_HELPER] Error upgrading database: $e');
      rethrow;
    }
  }

  /// Close database connection
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
      print('✅ [DB_HELPER] Database closed');
    }
  }

  /// Clear all data (for testing/reset)
  Future<void> clearAll() async {
    final db = await database;
    try {
      print('⚠️ [DB_HELPER] Clearing all database tables...');
      await db.execute('DELETE FROM customers');
      await db.execute('DELETE FROM sync_logs');
      try {
        await db.execute('DELETE FROM products');
      } catch (e) {
        print('   ℹ️ products table delete failed (may not exist): $e');
      }
      print('✅ [DB_HELPER] Database cleared');
    } catch (e) {
      print('❌ [DB_HELPER] Error clearing database: $e');
      rethrow;
    }
  }

  /// Force create products table if it doesn't exist
  Future<void> ensureProductsTable() async {
    final db = await database;
    try {
      print('🔄 [DB_HELPER] Ensuring products table exists...');
      
      // Check if table exists
      final tables =
          await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table' AND name='products'");
      
      if (tables.isEmpty) {
        print('   [DB_HELPER] products table not found, creating...');
        await db.execute('''
          CREATE TABLE IF NOT EXISTS products (
            id INTEGER PRIMARY KEY,
            name TEXT NOT NULL,
            type TEXT DEFAULT 'product',
            is_storable INTEGER DEFAULT 1,
            default_code TEXT,
            list_price REAL,
            qty_available REAL,
            category_id INTEGER,
            categ_name TEXT,
            sync_status TEXT DEFAULT 'SYNCED',
            synced_at TEXT
          )
        ''');
        print('   ✅ Created products table');
      } else {
        print('   ✅ products table already exists');
        
        // Check if type and is_storable columns exist, add if missing
        final columns = await db.rawQuery('PRAGMA table_info(products)');
        final columnNames = columns.map((col) => col['name'] as String).toList();
        
        if (!columnNames.contains('type')) {
          print('   [DB_HELPER] Adding missing type column...');
          await db.execute('ALTER TABLE products ADD COLUMN type TEXT DEFAULT \'product\'');
          print('   ✅ Added type column');
        }
        
        if (!columnNames.contains('is_storable')) {
          print('   [DB_HELPER] Adding missing is_storable column...');
          await db.execute('ALTER TABLE products ADD COLUMN is_storable INTEGER DEFAULT 1');
          print('   ✅ Added is_storable column');
        }
      }
    } catch (e) {
      print('❌ [DB_HELPER] Error ensuring products table: $e');
      // Don't rethrow - try to continue anyway
    }
  }

  /// Force create payment_terms table if it doesn't exist
  Future<void> ensurePaymentTermsTable() async {
    final db = await database;
    try {
      print('🔄 [DB_HELPER] Ensuring payment_terms table exists...');
      
      // Check if table exists
      final tables =
          await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table' AND name='payment_terms'");
      
      if (tables.isEmpty) {
        print('   [DB_HELPER] payment_terms table not found, creating...');
        await db.execute('''
          CREATE TABLE IF NOT EXISTS payment_terms (
            id INTEGER PRIMARY KEY,
            name TEXT NOT NULL,
            description TEXT,
            sync_status TEXT DEFAULT 'SYNCED',
            synced_at TEXT
          )
        ''');
        print('   ✅ Created payment_terms table');
      } else {
        print('   ✅ payment_terms table already exists');
      }
    } catch (e) {
      print('❌ [DB_HELPER] Error ensuring payment_terms table: $e');
      // Don't rethrow - try to continue anyway
    }
  }

  /// Get database size for debugging
  Future<void> printDatabaseSize() async {
    final db = await database;
    try {
      final customerCount =
          Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM customers')) ??
              0;
      final logCount =
          Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM sync_logs')) ??
              0;
      final productCount =
          Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM products')) ??
              0;

      print('📊 [DB_HELPER] Database size:');
      print('   Customers: $customerCount');
      print('   Sync logs: $logCount');
      print('   Products: $productCount');
    } catch (e) {
      print('❌ [DB_HELPER] Error getting database size: $e');
    }
  }
}
