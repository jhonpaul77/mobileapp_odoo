import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../config/theme.dart';
import '../../../features/customer/presentation/providers/customer_provider.dart';
import '../../../services/local_database/product_local_database.dart';
import '../../../services/local_database/payment_term_local_database.dart';
import '../../../services/sales_service.dart';
import '../../../services/config_service.dart';
import '../../../services/secure_storage_service.dart';
import '../../../services/sync/sync_progress_manager.dart';
import './sync_progress_dialog.dart';

/// Dashboard Stats Card - Display Customer, Product & Location Stats using a Table format
///
/// Shows:
/// - Database summary table with all counts
/// - Last sync time
/// - Single "Sync All" button that syncs everything at once
class DashboardStatsCard extends StatefulWidget {
  const DashboardStatsCard({super.key});

  @override
  State<DashboardStatsCard> createState() => _DashboardStatsCardState();
}

class _DashboardStatsCardState extends State<DashboardStatsCard> {
  bool _isSyncing = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Consumer<CustomerProvider>(
      builder: (context, provider, _) {
        final totalCustomers = provider.customersCount;
        final locationStats = provider.locationStats;
        final states = locationStats['states'] ?? 0;
        final cities = locationStats['cities'] ?? 0;
        final districts = locationStats['districts'] ?? 0;
        final syncStats = provider.syncStats;
        final lastSync = syncStats['lastSync'] as String?;

        // Format last sync time
        String lastSyncText = 'Never';
        if (lastSync != null) {
          try {
            final lastSyncTime = DateTime.parse(lastSync);
            final now = DateTime.now();
            final diff = now.difference(lastSyncTime);

            if (diff.inMinutes < 1) {
              lastSyncText = 'Just now';
            } else if (diff.inMinutes < 60) {
              lastSyncText = '${diff.inMinutes}m ago';
            } else if (diff.inHours < 24) {
              lastSyncText = '${diff.inHours}h ago';
            } else {
              lastSyncText = '${diff.inDays}d ago';
            }
          } catch (e) {
            lastSyncText = 'Unknown';
          }
        }

        return FutureBuilder<Map<String, int>>(
          future: _getDbStats(),
          builder: (context, snapshot) {
            final stats = snapshot.data ?? {};
            final totalProducts = stats['products'] ?? 0;
            final totalPaymentTerms = stats['paymentTerms'] ?? 0;

            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.cardTheme.color,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.brightness == Brightness.dark
                      ? Colors.grey[700]!
                      : Colors.grey[200]!,
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(
                        alpha: theme.brightness == Brightness.dark ? 0.3 : 0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 2),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.storage,
                          color: AppTheme.primaryColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Database Summary',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: theme.textTheme.bodyLarge?.color,
                              ),
                            ),
                            Text(
                              'Last sync: $lastSyncText',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Summary Table
                  _buildSummaryTable(
                    theme: theme,
                    totalCustomers: totalCustomers,
                    totalProducts: totalProducts,
                    states: states,
                    cities: cities,
                    districts: districts,
                    totalPaymentTerms: totalPaymentTerms,
                  ),
                  const SizedBox(height: 20),

                  // Sync All Button
                  _buildSyncButton(
                    label: _isSyncing ? 'Syncing...' : 'Sync All Data',
                    icon: _isSyncing ? Icons.hourglass_bottom : Icons.cloud_download,
                    color: Colors.deepPurple,
                    isLoading: _isSyncing,
                    onTap: _isSyncing ? null : () => _handleSyncAll(context, provider),
                    theme: theme,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// Build summary table with all database statistics
  static Widget _buildSummaryTable({
    required ThemeData theme,
    required int totalCustomers,
    required int totalProducts,
    required int states,
    required int cities,
    required int districts,
    required int totalPaymentTerms,
  }) {
    final isDark = theme.brightness == Brightness.dark;
    final headerBg = isDark ? Colors.grey[800] : Colors.grey[100];
    final rowBg = isDark ? Colors.grey[900] : Colors.white;
    final borderColor = isDark ? Colors.grey[700] : Colors.grey[300];

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: borderColor!,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Header Row
          Container(
            decoration: BoxDecoration(
              color: headerBg,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(9),
                topRight: Radius.circular(9),
              ),
            ),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    'Data Type',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: theme.textTheme.bodyMedium?.color,
                    ),
                  ),
                ),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'Count',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: theme.textTheme.bodyMedium?.color,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Data Rows
          _buildTableRow(
            label: '👥 Customers',
            count: totalCustomers,
            rowBg: rowBg,
            borderColor: borderColor,
            theme: theme,
            isLast: false,
          ),
          _buildTableRow(
            label: '📦 Products',
            count: totalProducts,
            rowBg: rowBg,
            borderColor: borderColor,
            theme: theme,
            isLast: false,
          ),
          _buildTableRow(
            label: '💳 Payment Terms',
            count: totalPaymentTerms,
            rowBg: rowBg,
            borderColor: borderColor,
            theme: theme,
            isLast: false,
          ),
          _buildTableRow(
            label: '🗺️ States',
            count: states,
            rowBg: rowBg,
            borderColor: borderColor,
            theme: theme,
            isLast: false,
          ),
          _buildTableRow(
            label: '🏙️ Cities',
            count: cities,
            rowBg: rowBg,
            borderColor: borderColor,
            theme: theme,
            isLast: false,
          ),
          _buildTableRow(
            label: '📍 Districts',
            count: districts,
            rowBg: rowBg,
            borderColor: borderColor,
            theme: theme,
            isLast: true,
          ),
        ],
      ),
    );
  }

  /// Build individual table row
  static Widget _buildTableRow({
    required String label,
    required int count,
    required Color? rowBg,
    required Color borderColor,
    required ThemeData theme,
    required bool isLast,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: rowBg,
        border: Border(
          bottom: isLast
              ? BorderSide.none
              : BorderSide(
                  color: borderColor,
                  width: 0.5,
                ),
        ),
        borderRadius: isLast
            ? const BorderRadius.only(
                bottomLeft: Radius.circular(9),
                bottomRight: Radius.circular(9),
              )
            : BorderRadius.zero,
      ),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: theme.textTheme.bodyMedium?.color,
              ),
            ),
          ),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  count.toString(),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build sync button
  static Widget _buildSyncButton({
    required String label,
    required IconData icon,
    required Color color,
    required bool isLoading,
    required VoidCallback? onTap,
    required ThemeData theme,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoading)
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              )
            else
              Icon(icon, color: color, size: 16),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Handle sync all button click
  Future<void> _handleSyncAll(BuildContext context, CustomerProvider provider) async {
    setState(() => _isSyncing = true);
    
    try {
      await _performSyncAll(context, provider);
    } finally {
      if (mounted) {
        setState(() => _isSyncing = false);
      }
    }
  }

  /// Get all database stats in one call
  Future<Map<String, int>> _getDbStats() async {
    try {
      final productDb = ProductLocalDatabase();
      final paymentTermDb = PaymentTermLocalDatabase();
      
      final products = await productDb.getProductCount();
      final paymentTerms = await paymentTermDb.getPaymentTermCount();
      
      return {
        'products': products,
        'paymentTerms': paymentTerms,
      };
    } catch (e) {
      print('⚠️ Error getting DB stats: $e');
      return {};
    }
  }

  /// Perform all syncs sequentially with progress
  Future<void> _performSyncAll(
    BuildContext context,
    CustomerProvider provider,
  ) async {
    try {
      // Initialize progress manager
      final progressManager = SyncProgressManager();
      progressManager.initialize([
        SyncStep(
          id: 'customers',
          label: '👥 Sync Customers',
          icon: '👥',
          status: SyncStepStatus.waiting,
          message: 'Waiting...',
        ),
        SyncStep(
          id: 'locations',
          label: '📍 Sync Locations',
          icon: '📍',
          status: SyncStepStatus.waiting,
          message: 'Waiting...',
        ),
        SyncStep(
          id: 'products',
          label: '📦 Sync Products',
          icon: '📦',
          status: SyncStepStatus.waiting,
          message: 'Waiting...',
        ),
        SyncStep(
          id: 'payment_terms',
          label: '💳 Sync Payment Terms',
          icon: '💳',
          status: SyncStepStatus.waiting,
          message: 'Waiting...',
        ),
      ]);

      // Show progress dialog
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => ChangeNotifierProvider.value(
            value: progressManager,
            child: const SyncProgressDialog(
              title: 'Syncing All Data',
            ),
          ),
        );
      }

      // Step 1: Sync Customers
      print('📦 [SYNC_ALL] Step 1: Syncing customers...');
      progressManager.startStep('customers', message: 'Fetching customers...');

      try {
        final customerResult = await provider.syncCustomers();
        print(
            '✅ [SYNC_ALL] Customers synced: ${customerResult?.newCount ?? 0} new');
        progressManager.completeStep(
          'customers',
          message:
              '✅ ${customerResult?.newCount ?? 0} new, ${customerResult?.updatedCount ?? 0} updated',
          itemCount: customerResult?.totalCount ?? 0,
        );
      } catch (e) {
        print('❌ [SYNC_ALL] Customer sync failed: $e');
        progressManager.failStep('customers', message: 'Failed: $e');
        rethrow;
      }

      // Step 2: Sync Locations
      print('📦 [SYNC_ALL] Step 2: Syncing locations...');
      progressManager.startStep('locations', message: 'Fetching locations...');

      try {
        await provider.syncLocations();
        await provider.loadLocationStats();
        final locationStats = provider.locationStats;
        final states = locationStats['states'] ?? 0;
        final cities = locationStats['cities'] ?? 0;
        final districts = locationStats['districts'] ?? 0;

        print(
            '✅ [SYNC_ALL] Locations synced: $states states, $cities cities, $districts districts');
        progressManager.completeStep(
          'locations',
          message: '✅ $states states, $cities cities, $districts districts',
          itemCount: states + cities + districts,
        );
      } catch (e) {
        print('❌ [SYNC_ALL] Location sync failed: $e');
        progressManager.failStep('locations', message: 'Failed: $e');
        rethrow;
      }

      // Step 3: Sync Products
      print('📦 [SYNC_ALL] Step 3: Syncing products...');
      progressManager.startStep('products', message: 'Fetching products...');

      try {
        // Get credentials
        final configService = ConfigService();
        final secureStorage = SecureStorageService();
        final config = await configService.load();
        final db = config['database'] as String?;
        final apiKey = await secureStorage.getAccessToken();

        if (db == null || db.isEmpty || apiKey == null || apiKey.isEmpty) {
          throw Exception('Missing credentials for product sync');
        }

        // Fetch products
        final salesService = SalesService();
        final response =
            await salesService.getProductsSync(db: db, apiKey: apiKey);

        if (response['Success'] != true) {
          throw Exception(response['Message'] ?? 'Failed to fetch products');
        }

        List<dynamic> products = response['Data'] as List? ?? [];

        if (products.isEmpty) {
          throw Exception('No products found');
        }

        // Update progress
        progressManager.updateProgress('products', 50);

        // Upsert products
        final productList =
            products.map((p) => p as Map<String, dynamic>).toList();
        final productDb = ProductLocalDatabase();
        final upsertCount = await productDb.upsertProducts(productList);
        final finalCount = await productDb.getProductCount();

        print('✅ [SYNC_ALL] Products synced: $upsertCount products');
        progressManager.completeStep(
          'products',
          message: '✅ $upsertCount synced (Total: $finalCount)',
          itemCount: finalCount,
        );
      } catch (e) {
        print('❌ [SYNC_ALL] Product sync failed: $e');
        progressManager.failStep('products', message: 'Failed: $e');
        rethrow;
      }

      // Step 4: Sync Payment Terms
      print('📦 [SYNC_ALL] Step 4: Syncing payment terms...');
      progressManager.startStep('payment_terms', message: 'Fetching payment terms...');

      try {
        // Get credentials
        final configService = ConfigService();
        final secureStorage = SecureStorageService();
        final config = await configService.load();
        final db = config['database'] as String?;
        final apiKey = await secureStorage.getAccessToken();

        if (db == null || db.isEmpty || apiKey == null || apiKey.isEmpty) {
          throw Exception('Missing credentials for payment terms sync');
        }

        // Fetch payment terms
        final salesService = SalesService();
        final response =
            await salesService.getPaymentTermsSync(db: db, apiKey: apiKey);

        if (response['Success'] != true) {
          throw Exception(response['Message'] ?? 'Failed to fetch payment terms');
        }

        List<dynamic> paymentTerms = response['Data'] as List? ?? [];

        final finalCount = await PaymentTermLocalDatabase().getPaymentTermCount();

        print('✅ [SYNC_ALL] Payment terms synced: ${paymentTerms.length} terms');
        progressManager.completeStep(
          'payment_terms',
          message: '✅ ${paymentTerms.length} synced (Total: $finalCount)',
          itemCount: finalCount,
        );
      } catch (e) {
        print('❌ [SYNC_ALL] Payment terms sync failed: $e');
        progressManager.failStep('payment_terms', message: 'Failed: $e');
        rethrow;
      }

      // Mark sync as complete
      progressManager.markComplete();

      // Close dialog after a short delay
      await Future.delayed(const Duration(seconds: 1));
      if (context.mounted) {
        Navigator.pop(context);
      }

      // Refresh provider & UI
      await provider.loadLocationStats();
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      print('❌ [SYNC_ALL] Error: $e');
      // Dialog will show the error in the progress steps
    }
  }
}
