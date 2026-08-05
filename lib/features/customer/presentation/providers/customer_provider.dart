import 'package:flutter/foundation.dart';

import '../../../../services/config_service.dart';
import '../../../../services/local_database/customer_local_database.dart';
import '../../../../services/secure_storage_service.dart';
import '../../../../services/sync/customer_sync_manager.dart';
import '../../../../services/sync/location_sync_manager.dart';
import '../../data/datasources/location_remote_datasource.dart';
import '../../data/models/customer_local_model.dart';
import '../../data/repositories/customer_repository_impl.dart';
import '../../domain/entities/customer.dart';
import '../../domain/usecases/create_customer_usecase.dart';
import '../../domain/usecases/get_customers_usecase.dart';

/// CustomerProvider - Presentation Layer
///
/// State management for customers using Provider pattern
/// Integrates local database and sync functionality
class CustomerProvider extends ChangeNotifier {
  final GetCustomersUseCase _getCustomersUseCase;
  final CreateCustomerUseCase _createCustomerUseCase;
  final SecureStorageService _storage;
  final ConfigService _configService;
  final CustomerLocalDatabase _localDb = CustomerLocalDatabase();
  final CustomerSyncManager _syncManager = CustomerSyncManager();
  final LocationSyncManager _locationSyncManager = LocationSyncManager();
  final LocationRemoteDataSource _locationRemoteDs = LocationRemoteDataSource();

  CustomerProvider({
    GetCustomersUseCase? getCustomersUseCase,
    CreateCustomerUseCase? createCustomerUseCase,
    SecureStorageService? storage,
    ConfigService? configService,
  })  : _getCustomersUseCase = getCustomersUseCase ?? GetCustomersUseCase(),
        _createCustomerUseCase =
            createCustomerUseCase ?? CreateCustomerUseCase(),
        _storage = storage ?? SecureStorageService(),
        _configService = configService ?? ConfigService();

  // Private state
  List<Customer> _customers = [];
  List<Customer> _filteredCustomers = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = '';
  bool _isSyncing = false;
  SyncResult? _lastSyncResult;
  Map<String, dynamic> _syncStats = {};
  int _syncProgress = 0; // Current count during sync
  int _syncTotal = 0; // Total count target
  Map<String, int> _locationStats = {'states': 0, 'cities': 0, 'districts': 0};

  // Public getters
  List<Customer> get customers =>
      _searchQuery.isEmpty ? _customers : _filteredCustomers;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;
  bool get isEmpty => customers.isEmpty;
  int get customersCount => customers.length;
  String get searchQuery => _searchQuery;
  bool get isSyncing => _isSyncing;
  SyncResult? get lastSyncResult => _lastSyncResult;
  Map<String, dynamic> get syncStats => _syncStats;
  int get syncProgress => _syncProgress;
  int get syncTotal => _syncTotal;
  Map<String, int> get locationStats => _locationStats;

  /// Fetch customers from local database first, then from API
  /// On first load (empty local DB), fetch ALL customers from API
  Future<void> fetchCustomers() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      print('🔄 [CUSTOMER_PROVIDER] Fetching customers...');

      // Try to get from local database first
      try {
        final localCustomers = await _localDb.getAllCustomers();

        if (localCustomers.isNotEmpty) {
          // Use local cache if available
          _customers = localCustomers.map((c) => c.toEntity()).toList();
          _filteredCustomers = _customers;
          _isLoading = false;

          print(
              '✅ [CUSTOMER_PROVIDER] Customers loaded from local DB: ${_customers.length}');
          notifyListeners();
          return;
        }
      } catch (dbError) {
        print('⚠️ [CUSTOMER_PROVIDER] Local DB not ready: $dbError');
        print('   [CUSTOMER_PROVIDER] Fetching from API instead...');
      }

      // If local DB empty or not available, fetch from API with very large limit
      print(
          '🔄 [CUSTOMER_PROVIDER] Fetching ALL customers from API (limit: 9999999)...');

      // Get database from config.json
      final config = await _configService.load();
      final database = config['database'] as String?;

      // Get API key from SecureStorage
      final apiKey = await _storage.getAccessToken();

      print('   [CUSTOMER_PROVIDER] Database: $database');
      print('   [CUSTOMER_PROVIDER] API Key exists: ${apiKey != null}');

      // Validate
      if (database == null || database.isEmpty) {
        throw Exception(
            'Pengaturan database belum diatur. Silakan logout dan atur pengaturan server.');
      }

      if (apiKey == null || apiKey.isEmpty) {
        throw Exception('No API key found. Please login first.');
      }

      // Fetch from API with very large limit to get all customers
      final fetchedCustomers = await _getCustomersUseCase.call(
        db: database,
        apiKey: apiKey,
        limit: 9999999,
      );

      _customers = fetchedCustomers;
      _filteredCustomers = _customers;

      // Try to save to local DB (don't fail if DB not ready)
      try {
        for (final customer in fetchedCustomers) {
          final localModel = CustomerLocalModel.fromEntity(
            customer,
            syncStatus: SyncStatus.SYNCED,
          );
          await _localDb.insertOrReplace(localModel);
        }
        print(
            '✅ [CUSTOMER_PROVIDER] Saved ${fetchedCustomers.length} to local DB');
      } catch (dbError) {
        print('⚠️ [CUSTOMER_PROVIDER] Could not save to local DB: $dbError');
      }

      _isLoading = false;
      print(
          '✅ [CUSTOMER_PROVIDER] Customers loaded from API: ${_customers.length}');
      notifyListeners();
    } catch (e, stackTrace) {
      _errorMessage = e.toString();
      _isLoading = false;

      print('❌ [CUSTOMER_PROVIDER] Error: $_errorMessage');
      print('   Stack trace: $stackTrace');
      notifyListeners();
    }
  }

  /// Sync customers from backend
  ///
  /// Fetches ALL customers from API and syncs with local DB
  /// Also syncs pending local updates (marked as UPDATED) back to API
  Future<SyncResult?> syncCustomers() async {
    if (_isSyncing) {
      print('⚠️ [CUSTOMER_PROVIDER] Sync already in progress');
      return null;
    }

    _isSyncing = true;
    _syncProgress = 0;
    _syncTotal = 0;
    _errorMessage = null;
    notifyListeners();

    try {
      print('🔄 [CUSTOMER_PROVIDER] Starting sync from API...');

      // Get database from config.json
      final config = await _configService.load();
      final database = config['database'] as String?;

      // Get API key from SecureStorage
      final apiKey = await _storage.getAccessToken();

      print('   [CUSTOMER_PROVIDER] Database: $database');
      print('   [CUSTOMER_PROVIDER] API Key exists: ${apiKey != null}');

      // Validate
      if (database == null || database.isEmpty) {
        throw Exception(
            'Pengaturan database belum diatur. Silakan logout dan atur pengaturan server.');
      }

      if (apiKey == null || apiKey.isEmpty) {
        throw Exception('No API key found. Please login first.');
      }

      // STEP 1: First, sync pending local updates to API
      print('   [CUSTOMER_PROVIDER] Checking for pending local updates...');
      try {
        final pendingCustomers =
            await _localDb.getCustomersByStatus(SyncStatus.UPDATED);

        if (pendingCustomers.isNotEmpty) {
          print(
              '   📤 [CUSTOMER_PROVIDER] Found ${pendingCustomers.length} pending updates to sync');

          // Try to push each pending update to API
          int syncedPendingCount = 0;
          for (final customer in pendingCustomers) {
            try {
              final repository = CustomerRepositoryImpl();
              final entity = customer.toEntity();

              await repository.editCustomer(
                id: entity.id,
                db: database,
                apiKey: apiKey,
                data: {
                  'name': entity.name,
                  'email': entity.email,
                  'phone': entity.phone,
                  'street': entity.street,
                  'street2': entity.street2,
                  'district_id': entity.districtId,
                  'city_id': entity.cityId,
                  'state_id': entity.stateId,
                  'zip': entity.zip,
                  'country_id': entity.countryId,
                },
              );

              // Mark as synced
              await _localDb.updateSyncStatus(entity.id, SyncStatus.SYNCED);
              syncedPendingCount++;
              print(
                  '   ✅ [CUSTOMER_PROVIDER] Pushed pending update: ${entity.name}');
            } catch (e) {
              print(
                  '   ⚠️ [CUSTOMER_PROVIDER] Failed to push pending update for ID ${customer.id}: $e');
              // Continue with other pending updates
            }
          }

          print(
              '   ✅ [CUSTOMER_PROVIDER] Synced $syncedPendingCount/${pendingCustomers.length} pending updates');
        }
      } catch (e) {
        print('   ⚠️ [CUSTOMER_PROVIDER] Error syncing pending updates: $e');
        // Continue with main sync
      }

      // STEP 2: Fetch ALL customers from API
      print(
          '   [CUSTOMER_PROVIDER] Fetching ALL customers from API (limit: 2000)...');
      final remoteCustomers = await _getCustomersUseCase.call(
        db: database,
        apiKey: apiKey,
        limit: 2000,
        onProgressUpdate: (pageNum, totalFetched) {
          // Update progress for UI
          _syncProgress = pageNum;
          _syncTotal = totalFetched;
          print(
              '   [CUSTOMER_PROVIDER] Progress: Page $pageNum, Total fetched: $totalFetched');
          notifyListeners();
        },
      );

      print(
          '   [CUSTOMER_PROVIDER] API returned ${remoteCustomers.length} customers');

      // STEP 3: Sync with local database
      print('   [CUSTOMER_PROVIDER] Syncing with local database...');
      final syncResult = await _syncManager.sync(remoteCustomers);

      _lastSyncResult = syncResult;

      // Reload from local database
      await fetchCustomers();

      // Update sync stats
      try {
        _syncStats = await _syncManager.getSyncStats();
      } catch (e) {
        print('⚠️ [CUSTOMER_PROVIDER] Could not get sync stats: $e');
      }

      _isSyncing = false;
      _syncProgress = 0;
      _syncTotal = 0;
      print('✅ [CUSTOMER_PROVIDER] Sync completed: ${syncResult.summary}');
      notifyListeners();

      return syncResult;
    } catch (e, stackTrace) {
      _errorMessage = e.toString();
      _isSyncing = false;
      _syncProgress = 0;
      _syncTotal = 0;

      print('❌ [CUSTOMER_PROVIDER] Sync error: $_errorMessage');
      print('   Stack trace: $stackTrace');
      notifyListeners();
      return null;
    }
  }

  /// Search customers by name, phone, or city
  void searchCustomers(String query) {
    _searchQuery = query.trim().toLowerCase();

    if (_searchQuery.isEmpty) {
      _filteredCustomers = _customers;
    } else {
      // Use in-memory search (fast enough for loaded data)
      _filteredCustomers = _customers.where((customer) {
        final name = customer.name.toLowerCase();
        final phone = customer.phone?.toLowerCase() ?? '';
        final street = customer.street?.toLowerCase() ?? '';

        // Check if any field matches original query
        bool matchesOriginal = name.contains(_searchQuery) ||
            phone.contains(_searchQuery) ||
            street.contains(_searchQuery);

        // Normalize phone search for different formats
        bool matchesNormalized = false;

        // If query starts with 0, convert to +62 and check
        if (_searchQuery.startsWith('0')) {
          final normalizedWith62 = '+62${_searchQuery.substring(1)}';
          matchesNormalized = phone.contains(normalizedWith62);
        }
        // If query starts with 62 (without +), convert to +62 and check
        else if (_searchQuery.startsWith('62')) {
          final normalizedWithPlus = '+$_searchQuery';
          matchesNormalized = phone.contains(normalizedWithPlus);
        }

        return matchesOriginal || matchesNormalized;
      }).toList();
    }

    print(
        '🔍 [CUSTOMER_PROVIDER] Search "$_searchQuery": ${_filteredCustomers.length} results');
    notifyListeners();
  }

  /// Clear search query
  void clearSearch() {
    _searchQuery = '';
    _filteredCustomers = _customers;
    notifyListeners();
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Get customer by ID from local list
  Customer? getCustomerById(int id) {
    try {
      return _customers.firstWhere((customer) => customer.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get sync status for a specific customer
  Future<String> getCustomerSyncStatus(int customerId) async {
    try {
      final customer = await _localDb.getCustomerById(customerId);
      if (customer != null) {
        return customer.syncStatus
            .toString()
            .split('.')
            .last; // 'SYNCED', 'UPDATED', etc
      }
      return 'SYNCED'; // Default
    } catch (e) {
      print('⚠️ [CUSTOMER_PROVIDER] Error getting sync status: $e');
      return 'SYNCED';
    }
  }

  /// Create new customer
  Future<Customer> createCustomer(Map<String, dynamic> data) async {
    try {
      print('🔄 [CUSTOMER_PROVIDER] Creating customer...');

      // Get database from config.json
      final config = await _configService.load();
      final database = config['database'] as String?;

      // Get API key from SecureStorage
      final apiKey = await _storage.getAccessToken();

      // Validate
      if (database == null || database.isEmpty) {
        throw Exception(
            'Pengaturan database belum diatur. Silakan logout dan atur pengaturan server.');
      }

      if (apiKey == null || apiKey.isEmpty) {
        throw Exception('No API key found. Please login first.');
      }

      // Create customer via API
      final newCustomer = await _createCustomerUseCase.call(
        db: database,
        apiKey: apiKey,
        data: data,
      );

      // Add to local list and database
      _customers.insert(0, newCustomer);
      if (_searchQuery.isEmpty) {
        _filteredCustomers = _customers;
      }

      // Save to local database
      final localModel = CustomerLocalModel.fromEntity(
        newCustomer,
        syncStatus: SyncStatus.SYNCED,
      );
      await _localDb.insertOrReplace(localModel);

      print('✅ [CUSTOMER_PROVIDER] Customer created: ${newCustomer.name}');
      notifyListeners();

      return newCustomer;
    } catch (e, stackTrace) {
      print('❌ [CUSTOMER_PROVIDER] Create error: $e');
      print('   Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Update existing customer
  ///
  /// Simple flow:
  /// 1. POST to /edit_customer immediately
  /// 2. If successful: Update local DB with SYNCED status
  /// 3. If fails (offline, error, timeout): Save to local with UPDATED status + re-throw error
  ///
  /// User sees error message and decides whether to proceed with offline save or retry
  Future<Customer> updateCustomer(Map<String, dynamic> data) async {
    try {
      print('🔄 [CUSTOMER_PROVIDER] Updating customer...');

      // Customer ID is required
      final customerId = data['id'] as int?;
      if (customerId == null) {
        throw Exception('Customer ID is required for update');
      }

      // Get database from config.json
      final config = await _configService.load();
      final database = config['database'] as String?;

      // Get API key from SecureStorage
      final apiKey = await _storage.getAccessToken();

      // Validate
      if (database == null || database.isEmpty) {
        throw Exception(
            'Pengaturan database belum diatur. Silakan logout dan atur pengaturan server.');
      }

      if (apiKey == null || apiKey.isEmpty) {
        throw Exception('No API key found. Please login first.');
      }

      // Build the customer object from input data (convert strings to ints if needed)
      final updatedCustomer = Customer(
        id: customerId,
        name: data['name'] ?? '',
        email: data['email'],
        phone: data['phone'],
        userId: data['user_id'] != null
            ? int.tryParse(data['user_id'].toString())
            : null,
        street: data['street'],
        street2: data['street2'],
        districtId: data['district_id'] != null
            ? int.tryParse(data['district_id'].toString())
            : null,
        cityId: data['city_id'] != null
            ? int.tryParse(data['city_id'].toString())
            : null,
        stateId: data['state_id'] != null
            ? int.tryParse(data['state_id'].toString())
            : null,
        zip: data['zip'],
        countryId: data['country_id'] != null
            ? int.tryParse(data['country_id'].toString())
            : null,
      );

      // ⭐ STEP 1: POST langsung ke /edit_customer
      print('   [CUSTOMER_PROVIDER] POST ke /edit_customer...');
      print('   [CUSTOMER_PROVIDER] Data: $data');

      final repository = CustomerRepositoryImpl();
      await repository.editCustomer(
        id: customerId,
        db: database,
        apiKey: apiKey,
        data: data,
      );

      print('✅ [CUSTOMER_PROVIDER] API POST berhasil');

      // ⭐ STEP 2: Jika berhasil, update lokal dengan SYNCED
      final index =
          _customers.indexWhere((customer) => customer.id == customerId);
      if (index != -1) {
        _customers[index] = updatedCustomer;
        if (_searchQuery.isEmpty) {
          _filteredCustomers = _customers;
        } else {
          // Re-apply search filter
          searchCustomers(_searchQuery);
        }
      }

      // Save ke lokal dengan status SYNCED
      final localModel = CustomerLocalModel.fromEntity(
        updatedCustomer,
        syncStatus: SyncStatus.SYNCED,
      );
      await _localDb.insertOrReplace(localModel);
      print('✅ [CUSTOMER_PROVIDER] Tersimpan lokal (SYNCED)');

      notifyListeners();
      return updatedCustomer;
    } on Exception catch (e) {
      // ⭐ STEP 3: Jika gagal, coba simpan ke lokal dengan UPDATED (optional)
      print('❌ [CUSTOMER_PROVIDER] API POST gagal: $e');

      // Extract error message yang lebih readable
      String errorMsg = e.toString();
      if (errorMsg.startsWith('Exception: ')) {
        errorMsg = errorMsg.substring(11);
      }

      rethrow;
    } catch (e, stackTrace) {
      print('❌ [CUSTOMER_PROVIDER] Update error: $e');
      print('   Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Get sync statistics
  Future<void> loadSyncStats() async {
    try {
      _syncStats = await _syncManager.getSyncStats();
      notifyListeners();
    } catch (e) {
      print(
          '⚠️ [CUSTOMER_PROVIDER] Error loading sync stats (local DB may not be ready): $e');
      _syncStats = {
        'total': 0,
        'synced': 0,
        'new': 0,
        'updated': 0,
        'deleted': 0
      };
      notifyListeners();
    }
  }

  /// Sync locations (States, Cities, Districts) from backend
  ///
  /// Fetches ALL locations from API and syncs with local DB
  Future<void> syncLocations() async {
    try {
      print('🔄 [CUSTOMER_PROVIDER] Starting location sync...');

      // Get database from config.json
      final config = await _configService.load();
      final database = config['database'] as String?;

      // Get API key from SecureStorage
      final apiKey = await _storage.getAccessToken();

      // Validate
      if (database == null || database.isEmpty) {
        throw Exception(
            'Pengaturan database belum diatur. Silakan logout dan atur pengaturan server.');
      }

      if (apiKey == null || apiKey.isEmpty) {
        throw Exception('No API key found. Please login first.');
      }

      // Fetch states
      print('   [CUSTOMER_PROVIDER] Fetching states...');
      final states = await _locationRemoteDs.getStates(
        db: database,
        apiKey: apiKey,
      );
      await _locationSyncManager.syncStates(states);

      // Fetch cities
      print('   [CUSTOMER_PROVIDER] Fetching cities...');
      final cities = await _locationRemoteDs.getCities(
        db: database,
        apiKey: apiKey,
      );
      await _locationSyncManager.syncCities(cities);

      // Fetch districts
      print('   [CUSTOMER_PROVIDER] Fetching districts...');
      final districts = await _locationRemoteDs.getDistricts(
        db: database,
        apiKey: apiKey,
      );
      await _locationSyncManager.syncDistricts(districts);

      // Update location stats
      _locationStats = await _locationSyncManager.getLocationStats();
      print('✅ [CUSTOMER_PROVIDER] Location sync completed: $_locationStats');
      notifyListeners();
    } catch (e, stackTrace) {
      print('❌ [CUSTOMER_PROVIDER] Location sync error: $e');
      print('   Stack trace: $stackTrace');
      notifyListeners();
    }
  }

  /// Load location statistics
  Future<void> loadLocationStats() async {
    try {
      _locationStats = await _locationSyncManager.getLocationStats();
      notifyListeners();
    } catch (e) {
      print('⚠️ [CUSTOMER_PROVIDER] Error loading location stats: $e');
      _locationStats = {'states': 0, 'cities': 0, 'districts': 0};
      notifyListeners();
    }
  }
}
