# Local Database + Sync System Implementation

## Overview
Implemented complete local SQLite database with sync functionality for customers. Users can now sync customer data from backend, with intelligent change detection (NEW, UPDATED, DELETED).

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    Customer List Page                   │
│  - [SYNC] Button in AppBar                             │
│  - Sync status indicator showing:                       │
│    * Total customers                                    │
│    * Last sync time                                     │
│    * Changes from last sync (NEW/UPDATED/DELETED)      │
└─────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────┐
│              Customer Provider (State)                   │
│  - fetchCustomers() - Load from local DB                │
│  - syncCustomers() - Sync from API                      │
│  - loadSyncStats() - Get sync statistics                │
│  - CRUD operations integrated with local DB             │
└─────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────┐
│            Sync Manager                                  │
│  - Detects NEW records (in remote, not in local)       │
│  - Detects UPDATED records (field changes)              │
│  - Detects DELETED records (in local, not in remote)   │
│  - Logs all sync events with timestamps                 │
└─────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────┐
│         Local Database Service                          │
│  - CRUD operations                                      │
│  - Sync status tracking                                 │
│  - Query by sync status                                 │
│  - Sync logs for history                                │
└─────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────┐
│            SQLite Database                              │
│  Tables:                                                │
│  - customers (with sync fields)                        │
│  - sync_logs (sync event history)                       │
└─────────────────────────────────────────────────────────┘
```

## Files Created

### 1. Step 1: Database Setup
**`lib/services/local_database/database_helper.dart`**
- SQLite initialization (singleton pattern)
- Creates `customers` and `sync_logs` tables
- Database lifecycle management

### 2. Step 2: Extended Customer Model
**`lib/features/customer/data/models/customer_local_model.dart`**
- Extends Customer entity with sync fields:
  - `syncStatus`: SYNCED, NEW, UPDATED, DELETED
  - `remoteUpdatedAt`: Backend timestamp
  - `localCreatedAt/localUpdatedAt`: Local timestamps
  - `syncedAt`: Last sync timestamp
- Conversion methods between Entity ↔ LocalModel
- Sync status display text

### 3. Step 3: Local Database CRUD
**`lib/services/local_database/customer_local_database.dart`**
- CRUD operations for customers
- Query by sync status
- Batch operations
- Sync statistics:
  - Count by status
  - Last sync time
  - Customers needing sync
- Sync log recording

### 4. Step 4: Sync Manager
**`lib/services/sync/customer_sync_manager.dart`**
- Main sync logic
- Compares backend vs local database
- Detects changes:
  - NEW: In remote, not in local
  - UPDATED: Field changes detected
  - DELETED: In local, not in remote
- Returns `SyncResult` with detailed info

### 5. Step 5: Updated Provider
**`lib/features/customer/presentation/providers/customer_provider.dart`**
- `fetchCustomers()` - Load from local DB first
- `syncCustomers()` - Sync from API
- CRUD operations save to both API and local DB
- Sync stats tracking
- Error handling

### 6. Step 6: Updated UI
**`lib/features/customer/presentation/pages/customer_list_page.dart`**
- Sync button in AppBar
- Sync status indicator showing:
  - Total count
  - Last sync time (formatted: "5m ago", "2h ago", etc)
  - Changes from last sync
- Sync feedback via SnackBar

## Database Schema

### customers table
```sql
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
  sync_status TEXT DEFAULT 'SYNCED',           -- SYNCED, NEW, UPDATED, DELETED
  remote_updated_at TEXT,                      -- Last BE update
  local_created_at TEXT,                       -- When created locally
  local_updated_at TEXT,                       -- Last local change
  synced_at TEXT                               -- Last sync time
)
```

### sync_logs table
```sql
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
```

## Sync Flow

### 1. Initial Load
```
[Customer List Page]
      ↓
fetchCustomers() - Loads all from local DB
      ↓
Display customers from local cache (instant!)
```

### 2. Manual Sync
```
[User clicks SYNC button]
      ↓
syncCustomers()
      ↓
Fetch all from API
      ↓
Compare with local DB:
  - Detect NEW, UPDATED, DELETED
      ↓
Update local DB with sync flags
      ↓
Log sync event
      ↓
Show results:
  "✏️ 5 updated | 🆕 2 new | 🗑️ 1 deleted"
```

### 3. Update After Edit
```
[User edits customer]
      ↓
API update + local DB update
      ↓
Provider updates list
      ↓
No need to re-sync (already synced)
```

## Usage

### From Customer List Page
1. **First load**: Shows customers from local DB (instant, cached)
2. **Sync button**: Click cloud icon in AppBar
3. **View status**: See last sync time and sync counts
4. **See changes**: Red badge shows NEW/UPDATED/DELETED counts

### Sync Status Display
```
Total: 123 customers | Last sync: 5m ago
✏️ 3 updated | 🆕 1 new | 🗑️ 0 deleted
```

### Automatic Sync Fields
Every customer in local DB tracks:
- When created locally
- When last updated locally
- Last backend update time
- Current sync status
- Last sync time

## Benefits

✅ **Fast Load**: Customers display instantly from local cache
✅ **Offline Support**: Read data even if offline
✅ **Smart Sync**: Only flags changed records
✅ **Full History**: Track all changes via sync logs
✅ **Batch Operations**: Insert multiple records efficiently
✅ **Status Tracking**: Know exactly which records are synced
✅ **Type Safe**: Enums for sync status

## Future Enhancements

1. **Pagination**: Implement offset-based pagination for large datasets
2. **Conflict Resolution**: Handle backend changes while user editing locally
3. **Auto-sync**: Background sync at intervals
4. **Compression**: Minimize network traffic for large syncs
5. **Delta Sync**: Only fetch changed records (if BE supports)
6. **Search Optimization**: Index frequently searched fields
7. **Export/Import**: Backup/restore local database

## Dependencies Added

```yaml
sqflite: ^2.3.3  # SQLite for local database
path: ^1.9.0     # File path utilities
```

Run `flutter pub get` to install dependencies.
