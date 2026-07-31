import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../config/theme.dart';
import '../../../sales_order/domain/entities/sales_order.dart';
import '../../../sales_order/presentation/pages/sales_order_detail_page.dart';

/// Customer Transaction History Page
///
/// Displays full transaction history for a specific customer
/// with filtering, searching, and sorting capabilities
class CustomerTransactionHistoryPage extends StatefulWidget {
  final int customerId;
  final String customerName;
  final List<SalesOrder> transactions;

  const CustomerTransactionHistoryPage({
    super.key,
    required this.customerId,
    required this.customerName,
    required this.transactions,
  });

  @override
  State<CustomerTransactionHistoryPage> createState() =>
      _CustomerTransactionHistoryPageState();
}

class _CustomerTransactionHistoryPageState
    extends State<CustomerTransactionHistoryPage> {
  final _searchController = TextEditingController();
  final _currencyFormat =
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  String _searchQuery = '';
  String? _statusFilter; // null = All, 'draft', 'sale', 'confirm', 'cancel'
  String _sortBy = 'date_desc'; // date_desc, date_asc, amount_desc, amount_asc

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<SalesOrder> get _filteredTransactions {
    var filtered = widget.transactions;

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((tx) {
        final query = _searchQuery.toLowerCase();
        return tx.name.toLowerCase().contains(query) ||
            tx.customerName.toLowerCase().contains(query);
      }).toList();
    }

    // Filter by status
    if (_statusFilter != null) {
      filtered = filtered
          .where((tx) => tx.state.toLowerCase() == _statusFilter!.toLowerCase())
          .toList();
    }

    // Sort
    switch (_sortBy) {
      case 'date_desc':
        filtered.sort((a, b) => b.dateOrder.compareTo(a.dateOrder));
        break;
      case 'date_asc':
        filtered.sort((a, b) => a.dateOrder.compareTo(b.dateOrder));
        break;
      case 'amount_desc':
        filtered.sort((a, b) => b.amountTotal.compareTo(a.amountTotal));
        break;
      case 'amount_asc':
        filtered.sort((a, b) => a.amountTotal.compareTo(b.amountTotal));
        break;
    }

    return filtered;
  }

  double get _totalRevenue {
    return widget.transactions.fold(
      0.0,
      (sum, tx) =>
          sum + (tx.state.toLowerCase() != 'cancel' ? tx.amountTotal : 0.0),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filtered = _filteredTransactions;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Riwayat Transaksi',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 18,
              ),
            ),
            Text(
              widget.customerName,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort, color: Colors.white),
            onSelected: (value) {
              setState(() => _sortBy = value);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'date_desc',
                child: Text('Tanggal (Terbaru)'),
              ),
              const PopupMenuItem(
                value: 'date_asc',
                child: Text('Tanggal (Terlama)'),
              ),
              const PopupMenuItem(
                value: 'amount_desc',
                child: Text('Nilai (Tertinggi)'),
              ),
              const PopupMenuItem(
                value: 'amount_asc',
                child: Text('Nilai (Terendah)'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Summary Stats Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  icon: Icons.receipt_long,
                  label: 'Total Transaksi',
                  value: '${widget.transactions.length}x',
                  color: Colors.white,
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.white24,
                ),
                _buildStatItem(
                  icon: Icons.attach_money,
                  label: 'Total Belanja',
                  value: _currencyFormat.format(_totalRevenue),
                  color: Colors.white,
                ),
              ],
            ),
          ),

          // Search & Filter
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Search Bar
                TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _searchQuery = value),
                  style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                  decoration: InputDecoration(
                    hintText: 'Cari nomor SO...',
                    prefixIcon: Icon(
                      Icons.search,
                      color: theme.textTheme.bodyMedium?.color,
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(
                              Icons.clear,
                              color: theme.textTheme.bodyMedium?.color,
                            ),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: theme.brightness == Brightness.dark
                            ? Colors.grey[700]!
                            : Colors.grey.shade300,
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
                const SizedBox(height: 12),

                // Status Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('All', null),
                      const SizedBox(width: 8),
                      _buildFilterChip('Open', 'draft'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Confirm', 'confirm'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Sale', 'sale'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Cancel', 'cancel'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Results Count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  '${filtered.length} Transaksi',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                if (_searchQuery.isNotEmpty || _statusFilter != null) ...[
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _searchQuery = '';
                        _statusFilter = null;
                        _searchController.clear();
                      });
                    },
                    icon: const Icon(Icons.clear_all, size: 16),
                    label: const Text('Reset Filter'),
                  ),
                ],
              ],
            ),
          ),

          // Transaction List
          Expanded(
            child: filtered.isEmpty
                ? _buildEmptyState()
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final tx = filtered[index];
                      return _buildCompactTransactionCard(tx);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, size: 24, color: color),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: color.withValues(alpha: 0.8),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, String? value) {
    final isSelected = _statusFilter == value;
    final theme = Theme.of(context);

    Color getStatusColor(String? status) {
      if (status == null) return AppTheme.primaryColor;
      switch (status.toLowerCase()) {
        case 'draft':
          return const Color(0xFFFFA726);
        case 'sale':
          return const Color(0xFF42A5F5);
        case 'confirm':
          return const Color(0xFF66BB6A);
        case 'cancel':
          return const Color(0xFFEF5350);
        default:
          return AppTheme.primaryColor;
      }
    }

    final statusColor = getStatusColor(value);

    return GestureDetector(
      onTap: () => setState(() => _statusFilter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? statusColor.withValues(alpha: 0.15)
              : theme.brightness == Brightness.dark
                  ? AppTheme.darkCard
                  : Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? statusColor
                : theme.brightness == Brightness.dark
                    ? Colors.grey[700]!
                    : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? statusColor : theme.textTheme.bodyMedium?.color,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildCompactTransactionCard(SalesOrder tx) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(12),
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
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SalesOrderDetailPage(order: tx),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Leading Circle Avatar
              CircleAvatar(
                radius: 20,
                backgroundColor: Color(tx.stateColor).withValues(alpha: 0.2),
                child: Text(
                  tx.name.substring(tx.name.length - 2),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(tx.stateColor),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // SO Number + Status Badge
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            tx.name,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: theme.textTheme.bodyLarge?.color,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Color(tx.stateColor).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color:
                                  Color(tx.stateColor).withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            tx.stateLabel,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Color(tx.stateColor),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Date + Items
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 12,
                          color: theme.textTheme.bodySmall?.color,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          tx.dateOrderFormatted,
                          style: TextStyle(
                            fontSize: 11,
                            color: theme.textTheme.bodySmall?.color,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.shopping_cart_outlined,
                          size: 12,
                          color: theme.textTheme.bodySmall?.color,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${tx.orderLines.length} item(s)',
                          style: TextStyle(
                            fontSize: 11,
                            color: theme.textTheme.bodySmall?.color,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Amount
                    Text(
                      _currencyFormat.format(tx.amountTotal),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),

              // Trailing Arrow
              Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: theme.textTheme.bodySmall?.color,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _searchQuery.isNotEmpty || _statusFilter != null
                ? Icons.search_off
                : Icons.receipt_long_outlined,
            size: 64,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty || _statusFilter != null
                ? 'Tidak ada transaksi ditemukan'
                : 'Belum ada transaksi',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          if (_searchQuery.isNotEmpty || _statusFilter != null) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                setState(() {
                  _searchQuery = '';
                  _statusFilter = null;
                  _searchController.clear();
                });
              },
              child: const Text('Reset Filter'),
            ),
          ],
        ],
      ),
    );
  }
}
