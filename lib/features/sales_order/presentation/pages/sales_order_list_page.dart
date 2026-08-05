import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../config/theme.dart';
import '../providers/sales_order_provider.dart';
import 'sales_order_detail_page.dart';

/// SalesOrderListPage - Presentation Layer
///
/// Displays list of sales orders from Odoo API
class SalesOrderListPage extends StatefulWidget {
  const SalesOrderListPage({super.key});

  @override
  State<SalesOrderListPage> createState() => _SalesOrderListPageState();
}

class _SalesOrderListPageState extends State<SalesOrderListPage> {
  final TextEditingController _searchController = TextEditingController();
  final _currencyFormat =
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    // Fetch sales orders on page load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SalesOrderProvider>().fetchSalesOrders();
      // No need to load customer names separately - API provides them directly
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Daftar Transaksi Penjualan',
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
      body: Consumer<SalesOrderProvider>(
        builder: (context, provider, child) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(
              children: [
                // Status Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildStatusChip(provider, 'All'),
                      const SizedBox(width: 7),
                      _buildStatusChip(provider, 'Open'),
                      const SizedBox(width: 7),
                      _buildStatusChip(provider, 'Confirm'),
                      const SizedBox(width: 7),
                      _buildStatusChip(provider, 'Sale'),
                      const SizedBox(width: 7),
                      _buildStatusChip(provider, 'Cancel'),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Search Bar
                TextField(
                  controller: _searchController,
                  onChanged: (value) => provider.searchOrders(value),
                  style: TextStyle(
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Cari SO atau customer...',
                    prefixIcon: Icon(
                      Icons.search,
                      color: theme.textTheme.bodyMedium?.color,
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(
                              Icons.clear,
                              color: theme.textTheme.bodyMedium?.color,
                            ),
                            onPressed: () {
                              _searchController.clear();
                              provider.clearSearch();
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: theme.brightness == Brightness.dark
                            ? Colors.grey[700]!
                            : Colors.grey,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: theme.brightness == Brightness.dark
                            ? Colors.grey[700]!
                            : Colors.grey.shade300,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.blue),
                    ),
                    filled: true,
                    fillColor: theme.brightness == Brightness.dark
                        ? AppTheme.darkCard
                        : Colors.grey.shade50,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Sales Order List
                Expanded(
                  child: _buildBody(provider),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody(SalesOrderProvider provider) {
    // Loading state
    if (provider.isLoading && provider.orders.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Memuat data transaksi...',
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
              onPressed: () => provider.fetchSalesOrders(),
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
                  ? Icons.receipt_long_outlined
                  : Icons.search_off,
              size: 64,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              provider.searchQuery.isEmpty
                  ? 'Belum ada transaksi'
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
                onPressed: () {
                  _searchController.clear();
                  provider.clearSearch();
                },
                child: const Text('Clear pencarian'),
              ),
            ],
          ],
        ),
      );
    }

    // Sales Order list
    return RefreshIndicator(
      onRefresh: () async {
        // Clear search field when refreshing
        _searchController.clear();
        // Fetch will reset filter to "All" and search to ""
        await provider.fetchSalesOrders();
      },
      child: Column(
        children: [
          // Sales Order count
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${provider.ordersCount} Transaksi',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                if (provider.searchQuery.isNotEmpty)
                  TextButton.icon(
                    onPressed: () {
                      _searchController.clear();
                      provider.clearSearch();
                    },
                    icon: const Icon(Icons.close, size: 16),
                    label: const Text('Clear'),
                  ),
              ],
            ),
          ),
          // Sales Order list
          Expanded(
            child: ListView.separated(
              itemCount: provider.orders.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final order = provider.orders[index];
                final itemTheme = Theme.of(context);

                return Container(
                  decoration: BoxDecoration(
                    color: itemTheme.cardTheme.color,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: itemTheme.brightness == Brightness.dark
                          ? Colors.grey[700]!
                          : Colors.grey[200]!,
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                            alpha: itemTheme.brightness == Brightness.dark
                                ? 0.3
                                : 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: InkWell(
                    onTap: () async {
                      // Navigate to detail page
                      final result = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              SalesOrderDetailPage(order: order),
                        ),
                      );

                      // Refresh list if order was updated
                      if (result == true && mounted) {
                        context.read<SalesOrderProvider>().fetchSalesOrders();
                      }
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header: SO Number + Status Badge + WA Count Badge
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  order.name,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: itemTheme.textTheme.bodyLarge?.color,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Status Badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: Color(order.stateColor)
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: Color(order.stateColor)
                                        .withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Text(
                                  order.stateLabel,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Color(order.stateColor),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Follow-up Message Count Badge (dari fu_count)
                              if (order.state.toLowerCase() == 'draft' ||
                                  order.state.toLowerCase() == 'sent') ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF25D366)
                                        .withValues(alpha: 0.15),
                                    borderRadius:
                                        BorderRadius.circular(12),
                                    border: Border.all(
                                      color: const Color(0xFF25D366)
                                          .withValues(alpha: 0.5),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.message,
                                        size: 12,
                                        color: Color(0xFF25D366),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${order.fuCount}',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF25D366),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                              ],
                              // WA Message Count Badge (untuk Send WA - Sale/Confirm status)
                              if (order.state.toLowerCase() == 'sale' ||
                                  order.state.toLowerCase() == 'confirm') ...[
                                FutureBuilder<int>(
                                  future: _getWAMessageCount(order.id, 'send'),
                                  builder: (context, snapshot) {
                                    final count = snapshot.data ?? 0;
                                    return Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF25D366)
                                            .withValues(alpha: 0.15),
                                        borderRadius:
                                            BorderRadius.circular(12),
                                        border: Border.all(
                                          color: const Color(0xFF25D366)
                                              .withValues(alpha: 0.5),
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.send,
                                            size: 12,
                                            color: const Color(0xFF25D366),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '$count',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: const Color(0xFF25D366),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ],
                          ),

                          const Divider(height: 20, thickness: 1),

                          // Customer Info
                          _buildInfoRow(
                            icon: Icons.person_outline,
                            iconColor: AppTheme.brandBlue,
                            iconBgColor:
                                AppTheme.brandBlue.withValues(alpha: 0.1),
                            label: 'Customer',
                            value: order.customerName,
                          ),

                          // Date Order
                          _buildInfoRow(
                            icon: Icons.calendar_today_outlined,
                            iconColor: Colors.orange,
                            iconBgColor: Colors.orange.withValues(alpha: 0.1),
                            label: 'Tanggal',
                            value: order.dateOrderFormatted,
                          ),

                          // Total Amount
                          _buildInfoRow(
                            icon: Icons.attach_money,
                            iconColor: Colors.green,
                            iconBgColor: Colors.green.withValues(alpha: 0.1),
                            label: 'Total',
                            value: _currencyFormat.format(order.amountTotal),
                            valueStyle: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primaryColor,
                            ),
                          ),

                          // Order Lines Info
                          if (order.orderLines.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: itemTheme.brightness == Brightness.dark
                                    ? AppTheme.darkCard
                                    : Colors.grey[100],
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.shopping_cart_outlined,
                                      size: 14,
                                      color:
                                          itemTheme.textTheme.bodySmall?.color),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${order.orderLines.length} item(s) • ${order.totalQty} qty',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color:
                                          itemTheme.textTheme.bodyMedium?.color,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  if (order.orderCount != null) ...[
                                    const SizedBox(width: 12),
                                    Icon(Icons.receipt_long_outlined,
                                        size: 14,
                                        color: itemTheme
                                            .textTheme.bodySmall?.color),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Order #${order.orderCount}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: itemTheme
                                            .textTheme.bodyMedium?.color,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Get WA message count untuk order
  Future<int> _getWAMessageCount(int orderId, String type) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'wa_count_${orderId}_$type';
      return prefs.getInt(key) ?? 0;
    } catch (e) {
      print('Error getting WA count: $e');
      return 0;
    }
  }

  /// Build status filter chip (same as original transaction_list_page.dart)
  Widget _buildStatusChip(SalesOrderProvider provider, String label) {
    final theme = Theme.of(context);
    final isAll = label == 'All';
    final selected = provider.statusFilter == null
        ? isAll
        : provider.statusFilter?.toLowerCase() == label.toLowerCase();

    // Get color based on status (same as SalesOrder.stateColor)
    Color getStatusColor(String status) {
      switch (status.toLowerCase()) {
        case 'open':
          return const Color(0xFFFFA726); // Orange - for draft
        case 'sale':
          return const Color(0xFF42A5F5); // Blue
        case 'confirm':
          return const Color(0xFF66BB6A); // Green
        case 'cancel':
          return const Color(0xFFEF5350); // Red
        default:
          return AppTheme.primaryColor; // Primary blue for 'All'
      }
    }

    final statusColor = isAll ? AppTheme.primaryColor : getStatusColor(label);

    return GestureDetector(
      onTap: () {
        provider.setStatusFilter(isAll ? null : label);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? statusColor.withValues(alpha: 0.15)
              : theme.brightness == Brightness.dark
                  ? AppTheme.darkCard
                  : Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected
                ? statusColor
                : theme.brightness == Brightness.dark
                    ? Colors.grey[700]!
                    : Colors.grey[300]!,
            width: selected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? statusColor : theme.textTheme.bodyMedium?.color,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  /// Build info row with icon, label, and value
  Widget _buildInfoRow({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String label,
    required String value,
    TextStyle? valueStyle,
  }) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon Container
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 16,
              color: iconColor,
            ),
          ),
          const SizedBox(width: 11),

          // Label & Value
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.textTheme.bodySmall?.color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: valueStyle ??
                      TextStyle(
                        fontSize: 13,
                        color: theme.textTheme.bodyMedium?.color,
                        fontWeight: FontWeight.w500,
                        height: 1.3,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
