import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../config/theme.dart';
import '../../../../services/local_database/customer_local_database.dart';
import '../providers/customer_provider.dart';
import '../widgets/customer_card.dart';
import '../widgets/customer_search_bar.dart';
import 'customer_create_page.dart';
import 'customer_detail_page.dart';

/// CustomerListPage - Presentation Layer
///
/// Displays list of customers from Odoo API
class CustomerListPage extends StatefulWidget {
  const CustomerListPage({super.key});

  @override
  State<CustomerListPage> createState() => _CustomerListPageState();
}

class _CustomerListPageState extends State<CustomerListPage> {
  @override
  void initState() {
    super.initState();
    // Fetch customers on page load (from local DB)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<CustomerProvider>();
      provider.fetchCustomers();
      provider.loadSyncStats();
      provider.loadLocationStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Daftar Customer',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<CustomerProvider>(
        builder: (context, provider, child) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(
              children: [
                // Pending updates indicator (if there are pending updates)
                FutureBuilder<Map<String, int>>(
                  future: _loadPendingStats(provider),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      final pendingCount = snapshot.data?['updated'] ?? 0;
                      if (pendingCount > 0) {
                        return _buildPendingIndicator(pendingCount, provider);
                      }
                    }
                    return const SizedBox.shrink();
                  },
                ),

                // Search Bar
                const CustomerSearchBar(),
                const SizedBox(height: 14),

                // Customer List
                Expanded(
                  child: _buildBody(provider),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CustomerCreatePage(),
            ),
          );

          // Reload list if customer was created
          if (result == true && mounted) {
            context.read<CustomerProvider>().fetchCustomers();
          }
        },
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  /// Load pending update statistics
  Future<Map<String, int>> _loadPendingStats(CustomerProvider provider) async {
    try {
      final localDb = CustomerLocalDatabase();
      return await localDb.getSyncStatusCounts();
    } catch (e) {
      print('⚠️ Error loading pending stats: $e');
      return {'updated': 0};
    }
  }

  /// Build pending updates indicator
  Widget _buildPendingIndicator(int pendingCount, CustomerProvider provider) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.orange.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.cloud_off_rounded,
            size: 20,
            color: Colors.orange,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '⏳ $pendingCount Pending Update${pendingCount > 1 ? 's' : ''}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Tap Sync in Dashboard to upload changes',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(CustomerProvider provider) {
    // Loading state
    if (provider.isLoading && provider.customers.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Memuat data customer...',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ],
        ),
      );
    }

    // Error state
    if (provider.hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: AppTheme.errorColor,
            ),
            const SizedBox(height: 16),
            Text(
              'Terjadi Kesalahan',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                provider.errorMessage ?? 'Unknown error',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => provider.fetchCustomers(),
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    // Empty state
    if (provider.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              provider.searchQuery.isEmpty
                  ? Icons.people_outline
                  : Icons.search_off,
              size: 64,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              provider.searchQuery.isEmpty
                  ? 'Belum ada customer'
                  : 'Tidak ada hasil pencarian',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            if (provider.searchQuery.isNotEmpty) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => provider.clearSearch(),
                child: const Text('Clear pencarian'),
              ),
            ],
          ],
        ),
      );
    }

    // Customer list
    return RefreshIndicator(
      onRefresh: () => provider.fetchCustomers(),
      child: Column(
        children: [
          // Customer count
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${provider.customersCount} Customer',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                if (provider.searchQuery.isNotEmpty)
                  TextButton.icon(
                    onPressed: () => provider.clearSearch(),
                    icon: const Icon(Icons.close, size: 16),
                    label: const Text('Clear'),
                  ),
              ],
            ),
          ),
          // Customer list
          Expanded(
            child: ListView.builder(
              itemCount: provider.customers.length,
              itemBuilder: (context, index) {
                final customer = provider.customers[index];

                // Build customer card with sync status
                return FutureBuilder<String>(
                  future: provider.getCustomerSyncStatus(customer.id),
                  builder: (context, snapshot) {
                    final syncStatus = snapshot.data ?? 'SYNCED';

                    return CustomerCard(
                      customer: customer,
                      syncStatus: syncStatus,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                CustomerDetailPage(customer: customer),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
