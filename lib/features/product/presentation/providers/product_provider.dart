import 'package:flutter/foundation.dart';

import '../../../../services/local_database/product_local_database.dart';
import '../../domain/entities/product.dart';

/// Product Provider - State Management for Products
///
/// Manages product list state using Provider pattern.
/// Loads products from LOCAL DATABASE (already synced at login).
/// Follows existing project conventions (ChangeNotifier).
class ProductProvider extends ChangeNotifier {
  final ProductLocalDatabase _productDb;

  ProductProvider({
    ProductLocalDatabase? productDb,
  })  : _productDb = productDb ?? ProductLocalDatabase();

  // Private state
  List<Product> _allProducts = [];
  List<Product> _filteredProducts = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = '';
  
  // Filter state
  String? _selectedType; // null = all, 'product', 'jasa'
  bool? _filterStok; // null = all, true = only stok, false = no stok

  // Public getters
  List<Product> get products => _filteredProducts;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;
  bool get isEmpty => _filteredProducts.isEmpty;
  int get productsCount => _filteredProducts.length;
  String get searchQuery => _searchQuery;
  String? get selectedType => _selectedType;
  bool? get filterStok => _filterStok;
  
  // Get available types from products (normalized to jasa/stok only)
  List<String> get availableTypes {
    return ['jasa', 'stok'];
  }

  /// Get human-readable label for type
  /// service → Jasa
  /// consu → Stok
  /// others → Stok (default)
  String getTypeLabel(String type) {
    switch (type.toLowerCase()) {
      case 'service':
        return 'Jasa';
      case 'consu':
      case 'product':
      default:
        return 'Stok';
    }
  }

  /// Normalize type for consistent filtering
  /// service → jasa
  /// consu/product/others → stok
  String normalizeType(String type) {
    switch (type.toLowerCase()) {
      case 'service':
        return 'jasa';
      default:
        return 'stok';
    }
  }

  /// Fetches products from LOCAL DATABASE
  ///
  /// Products are synced at login and stored in local SQLite database.
  /// This method loads from database - no API call.
  Future<void> fetchProducts() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      print('🔄 [PRODUCT_PROVIDER] Loading products from local database...');

      // Load from local database
      final productMaps = await _productDb.getAllProducts();

      if (productMaps.isEmpty) {
        print('⚠️ [PRODUCT_PROVIDER] No products found in local database');
        _allProducts = [];
        _filteredProducts = [];
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Convert to Product entities
      _allProducts = productMaps
          .map((map) => Product.fromJson(map))
          .toList();
      _isLoading = false;

      print('✅ [PRODUCT_PROVIDER] Loaded ${_allProducts.length} products from local database');
      
      // Debug: print all products and their types
      for (final product in _allProducts) {
        print('   📦 ${product.id}: ${product.name} | type=${product.type} | isStorable=${product.isStorable}');
      }
      
      // Count by type
      final jasaCount = _allProducts.where((p) => p.type.toLowerCase() == 'service').length;
      final stokCount = _allProducts.where((p) => p.type.toLowerCase() != 'service').length;
      print('   📊 Jasa: $jasaCount, Stok: $stokCount');
      
      // Apply filters
      _applyFilters();
      notifyListeners();
    } catch (e, stackTrace) {
      _errorMessage = e.toString();
      _isLoading = false;

      print('❌ [PRODUCT_PROVIDER] Error loading products: $_errorMessage');
      print('   Stack trace: $stackTrace');
      notifyListeners();
    }
  }

  /// Apply search and filter criteria
  void _applyFilters() {
    _filteredProducts = _allProducts.where((product) {
      // Apply type filter (normalize to jasa/stok)
      if (_selectedType != null) {
        final normalizedProductType = normalizeType(product.type);
        print('   [FILTER_DEBUG] Product: ${product.name}, type: ${product.type}, normalized: $normalizedProductType, filter: $_selectedType, match: ${normalizedProductType == _selectedType}');
        if (normalizedProductType != _selectedType) {
          return false;
        }
      }

      // Apply stok filter
      if (_filterStok != null) {
        if (_filterStok == true && !product.isStorable) {
          // Filter stok ON: show only storable products
          return false;
        }
        if (_filterStok == false && product.isStorable) {
          // Filter no-stok ON: show only non-storable products (jasa)
          return false;
        }
      }

      // Apply search query
      if (_searchQuery.isNotEmpty) {
        final name = product.name.toLowerCase();
        final sku = product.defaultCode?.toLowerCase() ?? '';
        if (!name.contains(_searchQuery) && !sku.contains(_searchQuery)) {
          return false;
        }
      }

      return true;
    }).toList();
    
    print('🔍 [PRODUCT_PROVIDER] Filter results: ${_filteredProducts.length} products (from ${_allProducts.length} total)');
  }

  /// Filter by product type
  void setTypeFilter(String? type) {
    _selectedType = type;
    print('🔍 [PRODUCT_PROVIDER] Setting type filter: ${type ?? "all"}');
    _applyFilters();
    print('🔍 [PRODUCT_PROVIDER] After filter: ${_filteredProducts.length} products shown');
    notifyListeners();
  }

  /// Filter by stok status
  /// null = show all
  /// true = show only storable (ada stok)
  /// false = show only non-storable (jasa)
  void setStokFilter(bool? filterStok) {
    _filterStok = filterStok;
    final filterLabel = filterStok == null ? 'all' : (filterStok ? 'stok' : 'no-stok');
    print('🔍 [PRODUCT_PROVIDER] Stok filter: $filterLabel');
    _applyFilters();
    notifyListeners();
  }

  /// Searches products by name or SKU
  ///
  /// Filters products locally (no API call).
  void searchProducts(String query) {
    _searchQuery = query.trim().toLowerCase();
    print('🔍 [PRODUCT_PROVIDER] Search "$query"');
    _applyFilters();
    notifyListeners();
  }

  /// Clears search query and all filters
  void clearSearch() {
    _searchQuery = '';
    print('🔍 [PRODUCT_PROVIDER] Search cleared');
    _applyFilters();
    notifyListeners();
  }

  /// Clears all filters
  void clearAllFilters() {
    _selectedType = null;
    _filterStok = null;
    _searchQuery = '';
    print('🔍 [PRODUCT_PROVIDER] All filters cleared');
    _applyFilters();
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
      return _allProducts.firstWhere((product) => product.id == id);
    } catch (e) {
      return null;
    }
  }
}
