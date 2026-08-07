import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../features/customer/presentation/providers/customer_provider.dart';
import '../../features/sales_order/presentation/providers/sales_order_provider.dart';
import '../../services/config_service.dart';
import '../../services/local_database/payment_term_local_database.dart';
import '../../services/local_database/product_local_database.dart';
import '../../services/sales_service.dart';
import '../../services/secure_storage_service.dart';
import '../home/home_page.dart';

/// Sync Splash Page - menampilkan proses sync data setelah login
/// 
/// Sync items:
/// 1. Customer data
/// 2. Payment Terms
/// 3. States/Cities/Districts
/// 4. Products
/// 5. Sales Orders
class SyncSplashPage extends StatefulWidget {
  const SyncSplashPage({super.key});

  @override
  State<SyncSplashPage> createState() => _SyncSplashPageState();
}

class _SyncSplashPageState extends State<SyncSplashPage> {
  final List<SyncItem> _syncItems = [
    SyncItem(label: 'Customer Data', status: SyncStatus.pending),
    SyncItem(label: 'Payment Terms', status: SyncStatus.pending),
    SyncItem(label: 'States & Cities', status: SyncStatus.pending),
    SyncItem(label: 'Products', status: SyncStatus.pending),
    SyncItem(label: 'Sales Orders', status: SyncStatus.pending),
  ];

  int _currentSyncIndex = 0;

  @override
  void initState() {
    super.initState();
    _startSync();
  }

  Future<void> _startSync() async {
    try {
      print('🚀 [SYNC_SPLASH] Starting data sync...');

      // 1. Customer Data
      print('📍 [SYNC_SPLASH] Item 1/5: Customer Data');
      await _updateSyncStatus(0, SyncStatus.loading);
      try {
        await context.read<CustomerProvider>().fetchCustomers();
        final customerCount = context.read<CustomerProvider>().customers.length;
        print('✅ [SYNC_SPLASH] Customer data synced: $customerCount customers');
        await _updateSyncStatus(0, SyncStatus.success, count: customerCount, message: '✅ $customerCount customers');
      } catch (e) {
        print('⚠️ [SYNC_SPLASH] Customer data sync error: $e');
        await _updateSyncStatus(0, SyncStatus.error, message: '❌ Error');
      }
      await Future.delayed(const Duration(milliseconds: 300));

      // 2. Payment Terms
      print('📍 [SYNC_SPLASH] Item 2/5: Payment Terms');
      await _updateSyncStatus(1, SyncStatus.loading);
      try {
        // Fetch payment terms from API
        final configService = ConfigService();
        final storageService = SecureStorageService();
        
        final config = await configService.load();
        final db = config['database'] as String?;
        final apiKey = await storageService.getAccessToken();
        
        if (db == null || db.isEmpty || apiKey == null || apiKey.isEmpty) {
          throw Exception('Missing credentials for payment terms sync');
        }
        
        final salesService = SalesService();
        final response = await salesService.getPaymentTermsSync(db: db, apiKey: apiKey);
        
        if (response['Success'] != true) {
          throw Exception(response['Message'] ?? 'Failed to fetch payment terms');
        }
        
        // Upsert to local database
        List<dynamic> paymentTermsList = response['Data'] as List? ?? [];
        List<Map<String, dynamic>> paymentTerms = 
          paymentTermsList.map((e) => e as Map<String, dynamic>).toList();
        
        await PaymentTermLocalDatabase().upsertPaymentTerms(paymentTerms);
        
        final paymentTermCount = await PaymentTermLocalDatabase().getPaymentTermCount();
        print('✅ [SYNC_SPLASH] Payment terms synced: $paymentTermCount terms');
        await _updateSyncStatus(1, SyncStatus.success, count: paymentTermCount, message: '✅ $paymentTermCount terms');
      } catch (e) {
        print('⚠️ [SYNC_SPLASH] Payment terms sync error: $e');
        await _updateSyncStatus(1, SyncStatus.error, message: '❌ Error');
      }
      await Future.delayed(const Duration(milliseconds: 300));

      // 3. States & Cities & Districts
      print('📍 [SYNC_SPLASH] Item 3/5: States, Cities & Districts');
      await _updateSyncStatus(2, SyncStatus.loading);
      try {
        await context.read<CustomerProvider>().syncLocations();
        await context.read<CustomerProvider>().loadLocationStats();
        final locationStats = context.read<CustomerProvider>().locationStats;
        final states = locationStats['states'] as int;
        final cities = locationStats['cities'] as int;
        final districts = locationStats['districts'] as int;
        final totalLocations = states + cities + districts;
        print('✅ [SYNC_SPLASH] Locations synced: $states states, $cities cities, $districts districts');
        await _updateSyncStatus(2, SyncStatus.success, count: totalLocations, message: '✅ $states states, $cities cities, $districts districts');
      } catch (e) {
        print('⚠️ [SYNC_SPLASH] Locations sync error: $e');
        await _updateSyncStatus(2, SyncStatus.error, message: '❌ Error');
      }
      await Future.delayed(const Duration(milliseconds: 300));

      // 4. Products
      print('📍 [SYNC_SPLASH] Item 4/5: Products');
      await _updateSyncStatus(3, SyncStatus.loading);
      try {
        // Fetch products from API
        final configService = ConfigService();
        final storageService = SecureStorageService();
        
        final config = await configService.load();
        final db = config['database'] as String?;
        final apiKey = await storageService.getAccessToken();
        
        if (db == null || db.isEmpty || apiKey == null || apiKey.isEmpty) {
          throw Exception('Missing credentials for products sync');
        }
        
        final salesService = SalesService();
        final response = await salesService.getProductsSync(db: db, apiKey: apiKey);
        
        if (response['Success'] != true) {
          throw Exception(response['Message'] ?? 'Failed to fetch products');
        }
        
        // Upsert to local database
        List<dynamic> productsList = response['Data'] as List? ?? [];
        List<Map<String, dynamic>> products = 
          productsList.map((e) => e as Map<String, dynamic>).toList();
        
        final productDb = ProductLocalDatabase();
        await productDb.upsertProducts(products);
        
        final productCount = await productDb.getProductCount();
        print('✅ [SYNC_SPLASH] Products synced: $productCount products');
        await _updateSyncStatus(3, SyncStatus.success, count: productCount, message: '✅ $productCount products');
      } catch (e) {
        print('⚠️ [SYNC_SPLASH] Products sync error: $e');
        await _updateSyncStatus(3, SyncStatus.error, message: '❌ Error');
      }
      await Future.delayed(const Duration(milliseconds: 300));

      // 5. Sales Orders (fetch untuk info, tidak disimpan ke local DB - sales orders sering berubah)
      print('📍 [SYNC_SPLASH] Item 5/5: Sales Orders');
      await _updateSyncStatus(4, SyncStatus.loading);
      try {
        await context.read<SalesOrderProvider>().fetchSalesOrders();
        final salesOrderCount = context.read<SalesOrderProvider>().ordersCount;
        print('✅ [SYNC_SPLASH] Sales Orders synced: $salesOrderCount orders');
        await _updateSyncStatus(4, SyncStatus.success, count: salesOrderCount, message: '✅ $salesOrderCount orders');
      } catch (e) {
        print('⚠️ [SYNC_SPLASH] Sales Orders sync error: $e');
        await _updateSyncStatus(4, SyncStatus.error, message: '❌ Error');
      }
      await Future.delayed(const Duration(milliseconds: 300));

      // All sync done - navigate to home
      print('✅ [SYNC_SPLASH] All data synced successfully!');
      if (mounted) {
        await Future.delayed(const Duration(milliseconds: 500));
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomePage()),
          (route) => false,
        );
      }
    } catch (e) {
      print('❌ [SYNC_SPLASH] Error during sync: $e');
      if (mounted) {
        await _showErrorDialog(e.toString());
      }
    }
  }

  Future<void> _updateSyncStatus(int index, SyncStatus status, {int count = 0, String? message}) async {
    if (mounted) {
      setState(() {
        _syncItems[index].status = status;
        if (count > 0) _syncItems[index].count = count;
        if (message != null) _syncItems[index].message = message;
        _currentSyncIndex = index;
      });
    }
    // Small delay for UI update
    await Future.delayed(const Duration(milliseconds: 100));
  }

  Future<void> _showErrorDialog(String error) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.error_outline, color: AppTheme.errorColor),
            const SizedBox(width: 8),
            const Expanded(
              child: Text('Sync Error'),
            ),
          ],
        ),
        content: Text(error),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _startSync(); // Retry sync
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.surfaceColor,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo / Icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                ),
                child: const Icon(
                  Icons.cloud_download_rounded,
                  size: 40,
                  color: AppTheme.primaryColor,
                ),
              ),

              const SizedBox(height: 24),

              // Title
              Text(
                'Syncing Data',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? AppTheme.darkTextPrimary
                      : AppTheme.textPrimary,
                ),
              ),

              const SizedBox(height: 8),

              // Subtitle
              Text(
                'Mengunduh data terbaru dari server...',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark
                      ? AppTheme.darkTextSecondary
                      : AppTheme.textSecondary,
                ),
              ),

              const SizedBox(height: 40),

              // Sync Items List
              ..._buildSyncItems(isDark),

              const SizedBox(height: 40),

              // Overall progress indicator
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: (_currentSyncIndex + 1) / _syncItems.length,
                  minHeight: 8,
                  backgroundColor: isDark
                      ? AppTheme.darkSurface
                      : Colors.grey[200],
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppTheme.primaryColor,
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Progress text
              Text(
                '${_currentSyncIndex + 1} / ${_syncItems.length}',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? AppTheme.darkTextSecondary
                      : AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildSyncItems(bool isDark) {
    return List.generate(
      _syncItems.length,
      (index) {
        final item = _syncItems[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildSyncItemRow(item, isDark),
        );
      },
    );
  }

  Widget _buildSyncItemRow(SyncItem item, bool isDark) {
    IconData icon;
    Color color;

    switch (item.status) {
      case SyncStatus.pending:
        icon = Icons.radio_button_unchecked;
        color = isDark ? AppTheme.darkTextSecondary : Colors.grey;
        break;
      case SyncStatus.loading:
        icon = Icons.sync;
        color = AppTheme.primaryColor;
        break;
      case SyncStatus.success:
        icon = Icons.check_circle;
        color = AppTheme.successColor;
        break;
      case SyncStatus.error:
        icon = Icons.error;
        color = AppTheme.errorColor;
        break;
    }

    return Row(
      children: [
        // Icon with animation for loading state
        if (item.status == SyncStatus.loading)
          SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          )
        else
          Icon(icon, color: color, size: 24),

        const SizedBox(width: 12),

        // Label
        Expanded(
          child: Text(
            item.label,
            style: TextStyle(
              fontSize: 14,
              color: isDark
                  ? AppTheme.darkTextPrimary
                  : AppTheme.textPrimary,
              fontWeight: item.status == SyncStatus.loading
                  ? FontWeight.w600
                  : FontWeight.w500,
            ),
          ),
        ),

        // Status text / Count
        if (item.status == SyncStatus.success && item.count > 0)
          Text(
            '✅ ${item.count}',
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.successColor,
              fontWeight: FontWeight.w600,
            ),
          )
        else if (item.status == SyncStatus.success)
          Text(
            'Done',
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.successColor,
              fontWeight: FontWeight.w600,
            ),
          )
        else if (item.message != null && (item.status == SyncStatus.loading || item.status == SyncStatus.error))
          Text(
            item.message!,
            style: TextStyle(
              fontSize: 12,
              color: item.status == SyncStatus.error ? AppTheme.errorColor : AppTheme.primaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    );
  }
}

enum SyncStatus { pending, loading, success, error }

class SyncItem {
  String label;
  SyncStatus status;
  int count; // Item count (jumlah data yang di-sync)
  String? message; // Optional message for display

  SyncItem({
    required this.label,
    required this.status,
    this.count = 0,
    this.message,
  });
}
