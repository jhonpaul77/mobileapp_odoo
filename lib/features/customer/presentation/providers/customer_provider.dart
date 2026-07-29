import 'package:flutter/foundation.dart';

import '../../../../services/config_service.dart';
import '../../../../services/secure_storage_service.dart';
import '../../domain/entities/customer.dart';
import '../../domain/usecases/create_customer_usecase.dart';
import '../../domain/usecases/get_customers_usecase.dart';

/// CustomerProvider - Presentation Layer
///
/// State management for customers using Provider pattern
class CustomerProvider extends ChangeNotifier {
  final GetCustomersUseCase _getCustomersUseCase;
  final CreateCustomerUseCase _createCustomerUseCase;
  final SecureStorageService _storage;
  final ConfigService _configService;

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

  // Public getters
  List<Customer> get customers =>
      _searchQuery.isEmpty ? _customers : _filteredCustomers;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;
  bool get isEmpty => customers.isEmpty;
  int get customersCount => customers.length;
  String get searchQuery => _searchQuery;

  /// Fetch customers from API
  Future<void> fetchCustomers() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      print('🔄 [CUSTOMER_PROVIDER] Fetching customers...');

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

      // Fetch from API
      final fetchedCustomers = await _getCustomersUseCase(
        db: database,
        apiKey: apiKey,
      );

      _customers = fetchedCustomers;
      _filteredCustomers = fetchedCustomers;
      _isLoading = false;

      print('✅ [CUSTOMER_PROVIDER] Customers loaded: ${_customers.length}');
      notifyListeners();
    } catch (e, stackTrace) {
      _errorMessage = e.toString();
      _isLoading = false;

      print('❌ [CUSTOMER_PROVIDER] Error: $_errorMessage');
      print('   Stack trace: $stackTrace');
      notifyListeners();
    }
  }

  /// Search customers by name, phone, or city
  void searchCustomers(String query) {
    _searchQuery = query.trim().toLowerCase();

    if (_searchQuery.isEmpty) {
      _filteredCustomers = _customers;
    } else {
      _filteredCustomers = _customers.where((customer) {
        final name = customer.name.toLowerCase();
        final phone = customer.phone?.toLowerCase() ?? '';
        final street = customer.street?.toLowerCase() ?? '';
        return name.contains(_searchQuery) ||
            phone.contains(_searchQuery) ||
            street.contains(_searchQuery);
      }).toList();
    }

    print(
        '🔍 [CUSTOMER_PROVIDER] Search "$query": ${_filteredCustomers.length} results');
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

  /// Get customer by ID
  Customer? getCustomerById(int id) {
    try {
      return _customers.firstWhere((customer) => customer.id == id);
    } catch (e) {
      return null;
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

      // Add to local list
      _customers.insert(0, newCustomer);
      if (_searchQuery.isEmpty) {
        _filteredCustomers = _customers;
      }

      print('✅ [CUSTOMER_PROVIDER] Customer created: ${newCustomer.name}');
      notifyListeners();

      return newCustomer;
    } catch (e, stackTrace) {
      print('❌ [CUSTOMER_PROVIDER] Create error: $e');
      print('   Stack trace: $stackTrace');
      rethrow;
    }
  }
}
