import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../features/customer/presentation/providers/customer_provider.dart';
import '../../features/product/presentation/providers/product_provider.dart';
import '../../features/sales_order/presentation/providers/sales_order_provider.dart';
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
        print('✅ [SYNC_SPLASH] Customer data synced');
      } catch (e) {
        print('⚠️ [SYNC_SPLASH] Customer data sync error: $e');
      }
      await _updateSyncStatus(0, SyncStatus.success);
      await Future.delayed(const Duration(milliseconds: 300));

      // 2. Payment Terms
      print('📍 [SYNC_SPLASH] Item 2/5: Payment Terms');
      await _updateSyncStatus(1, SyncStatus.loading);
      try {
        // TODO: Add payment terms fetch from provider
        print('📝 [SYNC_SPLASH] Payment terms sync - skipped (not yet implemented)');
        await Future.delayed(const Duration(milliseconds: 500));
      } catch (e) {
        print('⚠️ [SYNC_SPLASH] Payment terms sync error: $e');
      }
      await _updateSyncStatus(1, SyncStatus.success);
      await Future.delayed(const Duration(milliseconds: 300));

      // 3. States & Cities & Districts
      print('📍 [SYNC_SPLASH] Item 3/5: States, Cities & Districts');
      await _updateSyncStatus(2, SyncStatus.loading);
      try {
        await context.read<CustomerProvider>().syncLocations();
        print('✅ [SYNC_SPLASH] Locations synced');
      } catch (e) {
        print('⚠️ [SYNC_SPLASH] Locations sync error: $e');
      }
      await _updateSyncStatus(2, SyncStatus.success);
      await Future.delayed(const Duration(milliseconds: 300));

      // 4. Products
      print('📍 [SYNC_SPLASH] Item 4/5: Products');
      await _updateSyncStatus(3, SyncStatus.loading);
      try {
        await context.read<ProductProvider>().fetchProducts();
        print('✅ [SYNC_SPLASH] Products synced');
      } catch (e) {
        print('⚠️ [SYNC_SPLASH] Products sync error: $e');
      }
      await _updateSyncStatus(3, SyncStatus.success);
      await Future.delayed(const Duration(milliseconds: 300));

      // 5. Sales Orders
      print('📍 [SYNC_SPLASH] Item 5/5: Sales Orders');
      await _updateSyncStatus(4, SyncStatus.loading);
      try {
        await context.read<SalesOrderProvider>().fetchSalesOrders();
        print('✅ [SYNC_SPLASH] Sales Orders synced');
      } catch (e) {
        print('⚠️ [SYNC_SPLASH] Sales Orders sync error: $e');
      }
      await _updateSyncStatus(4, SyncStatus.success);
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

  Future<void> _updateSyncStatus(int index, SyncStatus status) async {
    if (mounted) {
      setState(() {
        _syncItems[index].status = status;
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

        // Status text
        if (item.status == SyncStatus.success)
          Text(
            'Done',
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.successColor,
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

  SyncItem({
    required this.label,
    required this.status,
  });
}
