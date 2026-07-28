import 'package:flutter/foundation.dart';

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

  List<SalesOrder> get orders =>
      _searchQuery.isEmpty ? _orders : _filteredOrders;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;
  bool get isEmpty => orders.isEmpty;
  int get ordersCount => orders.length;

  Future<void> fetchSalesOrders() async {
    _isLoading = true;
    _errorMessage = null;
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

      _orders = fetchedOrders;
      _filteredOrders = fetchedOrders;
      _isLoading = false;

      print('✅ [SALES_ORDER_PROVIDER] Orders loaded: ${_orders.length}');
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      print('❌ [SALES_ORDER_PROVIDER] Error: $_errorMessage');
      notifyListeners();
    }
  }

  void searchOrders(String query) {
    _searchQuery = query.trim().toLowerCase();
    if (_searchQuery.isEmpty) {
      _filteredOrders = _orders;
    } else {
      _filteredOrders = _orders.where((order) {
        return order.name.toLowerCase().contains(_searchQuery) ||
            order.customerName.toLowerCase().contains(_searchQuery);
      }).toList();
    }
    notifyListeners();
  }

  void clearSearch() {
    _searchQuery = '';
    _filteredOrders = _orders;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
