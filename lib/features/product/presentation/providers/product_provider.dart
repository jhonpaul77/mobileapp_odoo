import 'package:flutter/foundation.dart';

import '../../../../services/config_service.dart';
import '../../../../services/secure_storage_service.dart';
import '../../domain/entities/product.dart';
import '../../domain/usecases/get_products_usecase.dart';

/// Product Provider - State Management for Products
///
/// Manages product list state using Provider pattern.
/// Follows existing project conventions (ChangeNotifier).
class ProductProvider extends ChangeNotifier {
  final GetProductsUseCase _getProductsUseCase;
  final SecureStorageService _storage;
  final ConfigService _configService;

  ProductProvider({
    GetProductsUseCase? getProductsUseCase,
    SecureStorageService? storage,
    ConfigService? configService,
  })  : _getProductsUseCase = getProductsUseCase ?? GetProductsUseCase(),
        _storage = storage ?? SecureStorageService(),
        _configService = configService ?? ConfigService();

  // Private state
  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = '';

  // Public getters
  List<Product> get products =>
      _searchQuery.isEmpty ? _products : _filteredProducts;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;
  bool get isEmpty => products.isEmpty;
  int get productsCount => products.length;
  String get searchQuery => _searchQuery;

  /// Fetches products from API
  ///
  /// Uses stored db and api-key from secure storage settings.
  Future<void> fetchProducts() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      print('🔄 [PRODUCT_PROVIDER] Fetching products...');

      // ✅ Get database & URL from config.json (file-based)
      final config = await _configService.load();
      final database = config['database'] as String?;
      final serverUrl = config['url'] as String?;

      // ✅ Get API key from SecureStorage (sensitive data)
      final apiKey = await _storage.getAccessToken();

      print('   [PRODUCT_PROVIDER] Database: $database');
      print('   [PRODUCT_PROVIDER] Server URL: $serverUrl');
      print('   [PRODUCT_PROVIDER] API Key exists: ${apiKey != null}');

      if (apiKey != null && apiKey.isNotEmpty) {
        print('   [PRODUCT_PROVIDER] API Key length: ${apiKey.length}');
        print(
            '   [PRODUCT_PROVIDER] API Key preview: ${apiKey.substring(0, apiKey.length > 8 ? 8 : apiKey.length)}...');
      }

      // Validate settings
      if (database == null || database.isEmpty) {
        throw Exception(
            'Pengaturan database belum diatur. Silakan logout dan atur pengaturan server terlebih dahulu.');
      }

      if (serverUrl == null || serverUrl.isEmpty) {
        throw Exception(
            'Pengaturan URL server belum diatur. Silakan logout dan atur pengaturan server terlebih dahulu.');
      }

      if (apiKey == null || apiKey.isEmpty) {
        throw Exception('No API key found. Please login first.');
      }

      print('   [PRODUCT_PROVIDER] Calling usecase with db=$database');

      final fetchedProducts = await _getProductsUseCase(
        db: database,
        apiKey: apiKey,
      );

      _products = fetchedProducts;
      _filteredProducts = fetchedProducts;
      _isLoading = false;

      print('✅ [PRODUCT_PROVIDER] Products loaded: ${_products.length}');
      notifyListeners();
    } catch (e, stackTrace) {
      _errorMessage = e.toString();
      _isLoading = false;

      print('❌ [PRODUCT_PROVIDER] Error: $_errorMessage');
      print('   Stack trace: $stackTrace');
      notifyListeners();
    }
  }

  /// Searches products by name or SKU
  ///
  /// Filters products locally (no API call).
  void searchProducts(String query) {
    _searchQuery = query.trim().toLowerCase();

    if (_searchQuery.isEmpty) {
      _filteredProducts = _products;
    } else {
      _filteredProducts = _products.where((product) {
        final name = product.name.toLowerCase();
        final sku = product.defaultCode?.toLowerCase() ?? '';
        return name.contains(_searchQuery) || sku.contains(_searchQuery);
      }).toList();
    }

    print(
        '🔍 [PRODUCT_PROVIDER] Search "$query": ${_filteredProducts.length} results');
    notifyListeners();
  }

  /// Clears search query and resets filtered products
  void clearSearch() {
    _searchQuery = '';
    _filteredProducts = _products;
    notifyListeners();
  }

  /// Clears error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Gets product by ID
  ///
  /// Returns product from local list (no API call).
  Product? getProductById(int id) {
    try {
      return _products.firstWhere((product) => product.id == id);
    } catch (e) {
      return null;
    }
  }
}
