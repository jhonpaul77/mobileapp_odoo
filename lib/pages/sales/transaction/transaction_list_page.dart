import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pintarx/config/theme.dart';
import 'package:pintarx/pages/sales/transaction/transaction_detail_page.dart';
import 'package:pintarx/services/sales_service.dart';

class TransactionListPage extends StatefulWidget {
  const TransactionListPage({super.key});

  @override
  State<TransactionListPage> createState() => _TransactionListPageState();
}

class _TransactionListPageState extends State<TransactionListPage> {
  final TextEditingController _searchController = TextEditingController();
  final _salesService = SalesService();

  String _searchQuery = '';
  String? _statusFilter;
  List<Map<String, dynamic>> _allTransactions = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      print('📦 [TRANSACTION LIST] Loading sale orders...');
      final result = await _salesService.getSaleOrders();

      if (result['Success'] == true) {
        final orders = result['Data']['items'] as List;
        print('✅ [TRANSACTION LIST] Loaded ${orders.length} orders');

        // Transform Odoo format to UI format
        final transformedOrders = orders.map((order) {
          // Calculate line item counts
          final orderLines = (order['order_line'] as List?) ?? [];
          final orderedCount = orderLines.length;
          // Count canceled items based on line state or quantity delivered
          final canceledCount = orderLines.where((line) {
            final state = line['state'] ?? '';
            return state.toString().toLowerCase() == 'cancel';
          }).length;

          return {
            'id': order['id'],
            'soNumber': order['name'] ?? 'SO-???',
            'noTransaksi': order['name'] ?? 'SO-???',
            'customer': order['partner_name'] ?? 'Unknown Customer',
            'phone': order['partner_phone'] ?? '-',
            'tanggal':
                DateTime.tryParse(order['date_order'] ?? '') ?? DateTime.now(),
            'status': _mapOdooState(order['state'] ?? 'draft'),
            'nominal': (order['amount_total'] ?? 0.0).toDouble(),
            'orderedCount': orderedCount,
            'canceledCount': canceledCount,
            // Keep original data for detail page
            'rawData': order,
          };
        }).toList();

        if (mounted) {
          setState(() {
            _allTransactions = transformedOrders;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = result['Message'] ?? 'Failed to load orders';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('❌ [TRANSACTION LIST] Error: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Error loading orders: $e';
          _isLoading = false;
        });
      }
    }
  }

  /// Map Odoo state to UI status
  String _mapOdooState(String odooState) {
    switch (odooState.toLowerCase()) {
      case 'draft':
        return 'Open';
      case 'sent':
        return 'Open';
      case 'sale':
        return 'Confirm';
      case 'done':
        return 'Confirm';
      case 'cancel':
        return 'Cancel';
      default:
        return 'Open';
    }
  }

  List<Map<String, dynamic>> get _filteredTransactions {
    var filtered = _allTransactions;

    // Filter by status
    if (_statusFilter != null) {
      filtered = filtered
          .where((t) =>
              t['status']?.toString().toLowerCase() ==
              _statusFilter!.toLowerCase())
          .toList();
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered
          .where((t) =>
              t['soNumber']?.toString().toLowerCase().contains(query) == true ||
              t['customer']?.toString().toLowerCase().contains(query) == true ||
              t['noTransaksi']?.toString().toLowerCase().contains(query) ==
                  true)
          .toList();
    }

    return filtered;
  }

  Widget _buildStatusChip(String label) {
    final selected = _statusFilter == null
        ? label == 'All'
        : _statusFilter?.toLowerCase() == label.toLowerCase();

    return ChoiceChip(
      label: Text(label),
      selected: selected,
      selectedColor: AppTheme.primaryColor.withValues(alpha: 0.15),
      backgroundColor: Colors.grey[100],
      labelStyle: TextStyle(
        color: selected ? AppTheme.primaryColor : AppTheme.textSecondary,
        fontWeight: FontWeight.w600,
      ),
      onSelected: (_) {
        setState(() {
          _statusFilter = label == 'All' ? null : label;
        });
      },
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _formatCurrency(double value) {
    final formatted = value.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (match) => '.',
        );
    return 'Rp $formatted';
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final transactions = _filteredTransactions;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: const Text(
          'Daftar Transaksi',
          style: TextStyle(color: Colors.black87),
        ),
        centerTitle: false,
        systemOverlayStyle: Theme.of(context).appBarTheme.systemOverlayStyle ??
            SystemUiOverlayStyle.dark,
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: Column(
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildStatusChip('All'),
                  const SizedBox(width: 8),
                  _buildStatusChip('Open'),
                  const SizedBox(width: 8),
                  _buildStatusChip('Confirm'),
                  const SizedBox(width: 8),
                  _buildStatusChip('Cancel'),
                ],
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Cari SO, customer...',
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: _isLoading
                  ? _buildLoadingState()
                  : _errorMessage != null
                      ? _buildErrorState()
                      : transactions.isEmpty
                          ? _buildEmptyState()
                          : RefreshIndicator(
                              onRefresh: _loadTransactions,
                              child: ListView.separated(
                                itemCount: transactions.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 10),
                                itemBuilder: (context, index) {
                                  final transaction = transactions[index];

                                  return InkWell(
                                    onTap: () async {
                                      final updated =
                                          await Navigator.of(context)
                                              .push<Map<String, dynamic>>(
                                        MaterialPageRoute(
                                          builder: (_) => TransactionDetailPage(
                                              transaction: transaction),
                                        ),
                                      );

                                      if (updated != null) {
                                        // Reload data from API
                                        _loadTransactions();
                                      }
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                            color: Colors.grey[200]!, width: 1),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black
                                                .withValues(alpha: 0.03),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(14),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  transaction['soNumber']
                                                      as String,
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                                Text(
                                                  _formatDate(
                                                      transaction['tanggal']
                                                          as DateTime),
                                                  style: TextStyle(
                                                    color: Colors.grey[600],
                                                    fontSize: 11,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 10),
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    const Icon(
                                                        Icons
                                                            .person_outline_rounded,
                                                        size: 16,
                                                        color: AppTheme
                                                            .primaryColor),
                                                    const SizedBox(width: 8),
                                                    Expanded(
                                                      child: Text(
                                                        transaction['customer']
                                                            as String,
                                                        style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          fontSize: 13,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 4),
                                                Row(
                                                  children: [
                                                    const Icon(
                                                        Icons.phone_rounded,
                                                        size: 14,
                                                        color: Colors.grey),
                                                    const SizedBox(width: 8),
                                                    Expanded(
                                                      child: Text(
                                                        (transaction['phone']
                                                                as String?) ??
                                                            '-',
                                                        style: TextStyle(
                                                          color:
                                                              Colors.grey[600],
                                                          fontSize: 11,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 10),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  _formatCurrency(
                                                      transaction['nominal']
                                                          as double),
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w700,
                                                    color:
                                                        AppTheme.successColor,
                                                  ),
                                                ),
                                                Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 10,
                                                      vertical: 5),
                                                  decoration: BoxDecoration(
                                                    color: AppTheme.primaryColor
                                                        .withValues(alpha: 0.1),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                  ),
                                                  child: Text(
                                                    transaction['status']
                                                        as String,
                                                    style: const TextStyle(
                                                      color:
                                                          AppTheme.primaryColor,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      fontSize: 11,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 10),
                                            Row(
                                              children: [
                                                _buildBadge(
                                                    'Order: ${transaction['orderedCount']}',
                                                    AppTheme.brandBlue),
                                                const SizedBox(width: 8),
                                                _buildBadge(
                                                    'Canceled: ${transaction['canceledCount']}',
                                                    AppTheme.errorColor),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading transactions...',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            const Text(
              'Failed to Load',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'An error occurred',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadTransactions,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
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
            Icons.inbox_rounded,
            size: 64,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'No Transactions',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No transactions match your filters',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
