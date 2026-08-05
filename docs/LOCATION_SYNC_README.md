# Location Sync Implementation

## Overview
Implementasi local database untuk menyimpan data lokasi (State, City, District) dan sync dengan API backend.

## Features

### 1. Database Schema
- **states** table: Menyimpan semua states/provinces
- **cities** table: Menyimpan semua cities dengan foreign key ke states
- **districts** table: Menyimpan semua districts dengan foreign key ke cities
- Database migration otomatis dari v1 → v2 untuk menambah `changed_fields` column

### 2. Models
- `StateLocalModel` - Model untuk state
- `CityLocalModel` - Model untuk city
- `DistrictLocalModel` - Model untuk district

### 3. Database Operations
- **LocationLocalDatabase** - CRUD operations untuk ketiga tabel
  - Insert/Update: `insertOrReplaceState()`, `insertOrReplaceCity()`, `insertOrReplaceDistrict()`
  - Batch insert: `insertBatchStates()`, `insertBatchCities()`, `insertBatchDistricts()`
  - Query: `getAllStates()`, `getCitiesByState()`, `getDistrictsByCity()`
  - Delete: `deleteAllStates()`, `deleteAllCities()`, `deleteAllDistricts()`
  - Stats: `getLocationCounts()` - untuk get jumlah tiap lokasi

### 4. API Integration
- **LocationRemoteDataSource** - Handle API calls untuk:
  - `GET /get_state` - Fetch semua states
  - `GET /get_city` - Fetch semua cities
  - `GET /get_district` - Fetch semua districts

### 5. Sync Manager
- **LocationSyncManager** - Handle logic untuk sync
  - `syncStates()` - Full sync states dari remote ke local
  - `syncCities()` - Full sync cities dari remote ke local
  - `syncDistricts()` - Full sync districts dari remote ke local
  - `getLocationStats()` - Get jumlah lokasi yang tersync

### 6. Provider Integration
- **CustomerProvider** tambahan methods:
  - `syncLocations()` - Sync all locations (states, cities, districts) dari API
  - `loadLocationStats()` - Load location statistics
  - `locationStats` getter - Akses jumlah lokasi yang tersync

## API Response Format
Endpoint yang didukung akan mengembalikan response dengan format:
```json
{
  "Success": true,
  "Data": [
    {"id": 1, "name": "Jakarta", ...},
    {"id": 2, "name": "Bandung", ...}
  ]
}
```

## Usage Example

### 1. Sync Locations (dari UI atau inisialisasi app)
```dart
final provider = Provider.of<CustomerProvider>(context, listen: false);
await provider.syncLocations();

// Get location stats
final stats = provider.locationStats;
print('States: ${stats['states']}, Cities: ${stats['cities']}, Districts: ${stats['districts']}');
```

### 2. Get Cities by State
```dart
final locationDb = LocationLocalDatabase();
final cities = await locationDb.getCitiesByState(stateId);
```

### 3. Get Districts by City
```dart
final locationDb = LocationLocalDatabase();
final districts = await locationDb.getDistrictsByCity(cityId);
```

## Database Migration
- Ketika app update dari v1 ke v2, database otomatis:
  1. Deteksi column `changed_fields` belum ada
  2. Add column ke customers table
  3. Create table states, cities, districts
  4. Tidak perlu uninstall app

## Key Features
✅ Local caching untuk performa lebih cepat
✅ Full sync mode (replace all data)
✅ Automatic database migration
✅ Error handling dan logging
✅ Location statistics tracking
✅ Support untuk hierarchical queries (state → city → district)

## Related Files
- `lib/services/local_database/database_helper.dart` - Database initialization & migration
- `lib/services/local_database/location_local_database.dart` - CRUD operations
- `lib/features/customer/data/datasources/location_remote_datasource.dart` - API calls
- `lib/features/customer/data/models/location_models.dart` - Data models
- `lib/services/sync/location_sync_manager.dart` - Sync logic
- `lib/features/customer/presentation/providers/customer_provider.dart` - Integration
