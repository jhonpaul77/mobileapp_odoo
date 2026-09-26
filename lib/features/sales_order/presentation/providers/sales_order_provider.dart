import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../services/config_service.dart';
import '../../../../services/secure_storage_service.dart';
import '../../domain/entities/sales_order.dart';
import '../../domain/usecases/get_sales_orders_usecase.dart';

/// SalesOrderProvider - Presentation Layer
class SalesOrderProvider extends ChangeNotifier {
  final GetSalesOrdersUseCase _getSalesOrdersUseCase;
  final SecureStorageService _storage;
  final ConfigService _configService;

  SalesOrderProvider({
    GetSalesOrdersUseCase? getSalesOrdersUseCase,
    SecureStorageService? storage,
    ConfigService? configService,
  })  : _getSalesOrdersUseCase =
            getSalesOrdersUseCase ?? GetSalesOrdersUseCase(),
        _storage = storage ?? SecureStorageService(),
        _configService = configService ?? ConfigService();

  List<SalesOrder> _orders = [];
  List<SalesOrder> _filteredOrders = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = '';
  String? _statusFilter; // null, 'Open', 'Confirm', 'Sale', 'Cancel'
  String? _dateFilter; // null, 'today', 'yesterday', 'thisWeek', 'thisMonth'
  
  // Advanced Search Filters
  String? _advancedCustomerName;
  String? _advancedSONumber;
  double? _advancedMinPrice;
  double? _advancedMaxPrice;
  Set<String> _advancedWAStatus = {}; // 'sent', 'not_sent'
  
  // Cache for WA counts (orderId -> count)
  Map<int, int> _waCountCache = {};

  List<SalesOrder> get orders =>
      _searchQuery.isEmpty && _statusFilter == null && _dateFilter == null && 
      _advancedCustomerName == null && _advancedSONumber == null && 
      _advancedMinPrice == null && _advancedMaxPrice == null && 
      _advancedWAStatus.isEmpty ? _orders : _filteredOrders;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;
  bool get isEmpty => orders.isEmpty;
  int get ordersCount => orders.length;
  String get searchQuery => _searchQuery;
  String? get statusFilter => _statusFilter;
  String? get dateFilter => _dateFilter;
  
  // Advanced Search Getters
  String? get advancedCustomerName => _advancedCustomerName;
  String? get advancedSONumber => _advancedSONumber;
  double? get advancedMinPrice => _advancedMinPrice;
  double? get advancedMaxPrice => _advancedMaxPrice;
  Set<String> get advancedWAStatus => _advancedWAStatus;
  bool get hasActiveAdvancedFilters => _advancedCustomerName != null || _advancedSONumber != null || 
      _advancedMinPrice != null || _advancedMaxPrice != null || _advancedWAStatus.isNotEmpty;

  Future<void> fetchSalesOrders() async {
    _isLoading = true;
    _errorMessage = null;
    // Reset filter to "All" when refreshing
    _statusFilter = null;
    _dateFilter = null;
    _searchQuery = '';
    notifyListeners();

    try {
      print('🔄 [SALES_ORDER_PROVIDER] Fetching sales orders...');

      final config = await _configService.load();
      final database = config['database'] as String?;
      final apiKey = await _storage.getAccessToken();

      if (database == null || database.isEmpty) {
        throw Exception('Database belum diatur.');
      }

      if (apiKey == null || apiKey.isEmpty) {
        throw Exception('API key not found. Please login.');
      }

      final fetchedOrders = await _getSalesOrdersUseCase(
        db: database,
        apiKey: apiKey,
      );

      // Sort by date descending (terbaru paling atas)
      fetchedOrders.sort((a, b) {
        final dateA = a.dateOrderParsed;
        final dateB = b.dateOrderParsed;
        
        if (dateA == null || dateB == null) return 0;
        return dateB.compareTo(dateA); // Descending: terbaru paling atas
      });

      _orders = fetchedOrders;
      _filteredOrders = fetchedOrders;
      _isLoading = false;

      // Load WA counts from SharedPreferences untuk cache
      await _loadWACountsCache();

      print('✅ [SALES_ORDER_PROVIDER] Orders loaded: ${_orders.length}');
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      print('❌ [SALES_ORDER_PROVIDER] Error: $_errorMessage');
      notifyListeners();
    }
  }

  /// Load WA counts cache dari SharedPreferences
  Future<void> _loadWACountsCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _waCountCache.clear();
      
      for (final order in _orders) {
        // For Sale/Confirm status: check wa_count_${orderId}_send
        // For Open/Draft status: use fuCount from order object
        if (order.state.toLowerCase() == 'sale' || 
            order.state.toLowerCase() == 'confirm') {
          final sendCount = prefs.getInt('wa_count_${order.id}_send') ?? 0;
          _waCountCache[order.id] = sendCount;
          print('📊 [WA_COUNT_CACHE] Order ${order.name} (Sale): sendCount=$sendCount');
        } else {
          // For Open/Draft, use fuCount from order
          _waCountCache[order.id] = order.fuCount;
          print('📊 [WA_COUNT_CACHE] Order ${order.name} (Open): fuCount=${order.fuCount}');
        }
      }
      print('✅ [SALES_ORDER_PROVIDER] WA counts cache loaded: ${_waCountCache.length} orders');
    } catch (e) {
      print('⚠️ [SALES_ORDER_PROVIDER] Error loading WA counts: $e');
    }
  }

  /// Get WA count untuk order based on status
  int _getTotalWACount(SalesOrder order) {
    // For Sale/Confirm: use cache (wa_count_send)
    if (order.state.toLowerCase() == 'sale' || 
        order.state.toLowerCase() == 'confirm') {
      return _waCountCache[order.id] ?? 0;
    }
    // For Open/Draft: use fuCount from order
    return order.fuCount;
  }

  void searchOrders(String query) {
    _searchQuery = query.trim().toLowerCase();
    _applyFilters();
  }

  void setStatusFilter(String? status) {
    _statusFilter = status;
    _applyFilters();
  }

  void setDateFilter(String? dateFilter) {
    _dateFilter = dateFilter;
    _applyFilters();
  }

  void setAdvancedFilters({
    String? customerName,
    String? soNumber,
    double? minPrice,
    double? maxPrice,
    Set<String>? waStatus,
  }) {
    _advancedCustomerName = customerName?.trim().isEmpty ?? true ? null : customerName?.trim().toLowerCase();
    _advancedSONumber = soNumber?.trim().isEmpty ?? true ? null : soNumber?.trim().toLowerCase();
    _advancedMinPrice = minPrice;
    _advancedMaxPrice = maxPrice;
    _advancedWAStatus = waStatus ?? {};
    _applyFilters();
  }

  void clearAdvancedFilters() {
    _advancedCustomerName = null;
    _advancedSONumber = null;
    _advancedMinPrice = null;
    _advancedMaxPrice = null;
    _advancedWAStatus.clear();
    _applyFilters();
  }

  void _applyFilters() {
    List<SalesOrder> filtered = _orders;

    // Apply status filter
    if (_statusFilter != null && _statusFilter!.isNotEmpty) {
      filtered = filtered.where((order) {
        // Map API states to display labels
        final displayLabel = _getDisplayLabel(order.state);
        return displayLabel.toLowerCase() == _statusFilter!.toLowerCase();
      }).toList();
    }

    // Apply date filter
    if (_dateFilter != null && _dateFilter!.isNotEmpty) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      
      filtered = filtered.where((order) {
        final orderDate = order.dateOrderParsed;
        if (orderDate == null) return false;
        
        final orderDay = DateTime(orderDate.year, orderDate.month, orderDate.day);
        
        switch (_dateFilter) {
          case 'today':
            return orderDay.isAtSameMomentAs(today);
          case 'yesterday':
            final yesterday = today.subtract(const Duration(days: 1));
            return orderDay.isAtSameMomentAs(yesterday);
          case 'thisWeek':
            // Get Monday of this week
            final dayOfWeek = today.weekday; // 1 = Monday, 7 = Sunday
            final monday = today.subtract(Duration(days: dayOfWeek - 1));
            return orderDay.isAfter(monday.subtract(const Duration(days: 1))) &&
                orderDay.isBefore(today.add(const Duration(days: 1)));
          case 'thisMonth':
            return orderDate.month == now.month && orderDate.year == now.year;
          default:
            return true;
        }
      }).toList();
    }

    // Advanced WA Status Filter
    // 'sent' = totalWACount > 0, 'not_sent' = totalWACount == 0
    if (_advancedWAStatus.isNotEmpty) {
      filtered = filtered.where((order) {
        final totalWACount = _getTotalWACount(order);
        final hasSentWA = totalWACount > 0;
        
        // If both options are selected, include all
        if (_advancedWAStatus.contains('sent') && _advancedWAStatus.contains('not_sent')) {
          return true;
        }
        
        // If only 'sent' is selected
        if (_advancedWAStatus.contains('sent') && !_advancedWAStatus.contains('not_sent')) {
          return hasSentWA;
        }
        
        // If only 'not_sent' is selected
        if (_advancedWAStatus.contains('not_sent') && !_advancedWAStatus.contains('sent')) {
          return !hasSentWA;
        }
        
        return true;
      }).toList();
    }

    // Apply search filter (quick search)
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((order) {
        return order.name.toLowerCase().contains(_searchQuery) ||
            order.customerName.toLowerCase().contains(_searchQuery);
      }).toList();
    }

    _filteredOrders = filtered;
    notifyListeners();
  }

  String _getDisplayLabel(String apiState) {
    // Map API states to display labels
    // API states: draft, sale, confirm, cancel
    // Display labels: Open, Sale, Confirm, Cancel
    switch (apiState.toLowerCase()) {
      case 'draft':
        return 'Open';
      case 'sale':
        return 'Sale';
      case 'confirm':
        return 'Confirm';
      case 'cancel':
        return 'Cancel';
      default:
        return 'Open';
    }
  }

  void clearSearch() {
    _searchQuery = '';
    _applyFilters();
  }

  void clearFilters() {
    _searchQuery = '';
    _statusFilter = null;
    _dateFilter = null;
    _advancedCustomerName = null;
    _advancedSONumber = null;
    _advancedMinPrice = null;
    _advancedMaxPrice = null;
    _advancedWAStatus.clear();
    _filteredOrders = _orders;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
