# Local Sync System - Quick Start Guide

## Installation

1. **Install dependencies**:
   ```bash
   flutter pub get
   ```

2. **Database will initialize automatically** when app starts:
   - SQLite database created at: `pintarx.db`
   - Tables created: `customers`, `sync_logs`

## How to Use

### Step 1: First Load
- When you open Customer List page, customers load from local database (instant!)
- If local DB is empty, no customers show

### Step 2: Initial Sync from Backend
1. Click the **☁️ Download icon** in the AppBar
2. App fetches all customers from backend API
3. Compares with local DB
4. Detects changes:
   - 🆕 NEW: Customers not in local DB
   - ✏️ UPDATED: Customers with changes
   - 🗑️ DELETED: Customers removed from backend
5. Updates local DB and shows results

### Step 3: View Sync Status
After sync, you see information like:
```
123 customers | Last sync: 5m ago
✏️ 3 updated | 🆕 2 new | 🗑️ 1 deleted
```

### Step 4: Work Offline
- Customers are cached locally
- You can search and view customers even without internet
- Edits are saved to both API and local DB
- Next sync will sync any changes

## Sync Status Icons

In customer list:
- ✅ **SYNCED**: Customer is up-to-date with backend
- 🆕 **NEW**: Customer just added from backend
- ✏️ **UPDATED**: Customer recently changed from backend
- 🗑️ **DELETED**: Customer removed from backend

## Provider Methods

### In your code:

```dart
// Load from local cache
await provider.fetchCustomers();

// Sync from API
final result = await provider.syncCustomers();
if (result != null) {
  print('New: ${result.newCount}');
  print('Updated: ${result.updatedCount}');
  print('Deleted: ${result.deletedCount}');
}

// Get sync stats
await provider.loadSyncStats();
final stats = provider.syncStats;
print('Total: ${stats['total']}');
print('Last sync: ${stats['lastSync']}');
```

## Database Access

### Direct database operations:

```dart
final localDb = CustomerLocalDatabase();

// Get all customers
final customers = await localDb.getAllCustomers();

// Get by sync status
final newCustomers = await localDb.getCustomersByStatus(SyncStatus.NEW);
final updatedCustomers = await localDb.getCustomersByStatus(SyncStatus.UPDATED);

// Get customers needing sync
final toSync = await localDb.getCustomersNeedingSync();

// Get sync statistics
final counts = await localDb.getSyncStatusCounts();
// Returns: {total: 123, synced: 120, new: 2, updated: 1, deleted: 0}

// Get last sync time
final lastSync = await localDb.getLastSyncTime();
```

## Typical Flow

```
┌─────────────────────────────────────────┐
│  App Start / Customer List Page Open    │
└────────────┬────────────────────────────┘
             │
             ↓
    ┌────────────────────┐
    │ fetchCustomers()   │
    │ Load from local DB │
    └────┬───────────────┘
         │
         ↓
    ┌──────────────────────────────┐
    │ Display cached customers     │
    │ (instant, even if offline)   │
    └──────────────────────────────┘
         │
         │ User clicks SYNC button
         ↓
    ┌──────────────────────────┐
    │ syncCustomers()          │
    │ Fetch from API           │
    │ Compare & detect changes │
    │ Update local DB          │
    └──────────────────────────┘
         │
         ↓
    ┌──────────────────────────┐
    │ Show sync results:       │
    │ "✏️ 3 | 🆕 2 | 🗑️ 1"   │
    └──────────────────────────┘
         │
         │ User edits customer
         ↓
    ┌──────────────────────────────┐
    │ API update + local DB update │
    │ Mark as SYNCED               │
    └──────────────────────────────┘
```

## Performance Tips

1. **First sync may be slow**: If you have thousands of customers
   - Consider paginating in future
   - For now, all customers are synced

2. **Search is instant**: Searches local database (no API calls)

3. **Offline work**: All customer data is available locally

4. **Incremental sync**: Only fetch what changed (future feature)

## Debugging

### Check database size:
```dart
final dbHelper = DatabaseHelper();
final db = await dbHelper.database;
// Database is at: /data/data/com.example.pintarx/pintarx.db
```

### View sync logs:
```dart
final localDb = CustomerLocalDatabase();
final counts = await localDb.getSyncStatusCounts();
print('Synced: ${counts['synced']}');
print('New: ${counts['new']}');
print('Updated: ${counts['updated']}');
print('Deleted: ${counts['deleted']}');
```

### Clear database (development only):
```dart
final dbHelper = DatabaseHelper();
await dbHelper.clearAll();
```

## Next Steps

To extend the sync system to other entities (Sales Orders, Products):

1. Create `sales_order_local_model.dart` similar to `customer_local_model.dart`
2. Create `sales_order_local_database.dart` for CRUD
3. Create `SalesOrderSyncManager` with comparison logic
4. Add sync method to Sales Order Provider
5. Add sync button to Sales Order List page

Same pattern for each entity!
