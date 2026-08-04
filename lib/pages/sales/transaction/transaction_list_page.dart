import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nextpsa/config/theme.dart';
import 'package:nextpsa/features/sales_order/domain/entities/order_line.dart';
import 'package:nextpsa/features/sales_order/domain/entities/sales_order.dart';
import 'package:nextpsa/features/sales_order/presentation/pages/sales_order_detail_page.dart';
import 'package:nextpsa/services/sales_service.dart';

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

          // ✅ Parse fu_count with debugging
          final fuCountRaw = order['fu_count'];
          final fuCountParsed = _parseFuCount(fuCountRaw);
          
          if (order['name'] == 'S00003') {
            print('🔍 [DEBUG_S00003] Raw fu_count: $fuCountRaw (type: ${fuCountRaw.runtimeType})');
            print('🔍 [DEBUG_S00003] Parsed fuCount: $fuCountParsed');
          }

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
            'fuCount': fuCountParsed, // Follow-up count from API
            // Keep original data for detail page
            'rawData': order,
          };
        }).toList();

        // DEBUG: Print fu_count from first few transactions
        if (transformedOrders.isNotEmpty) {
          print('📊 [TRANSACTION_LIST] ✅ Loaded and transformed ${transformedOrders.length} orders');
          print('📊 [TRANSACTION_LIST] Sample fu_count values from first 5:');
          for (int i = 0; i < (transformedOrders.length > 5 ? 5 : transformedOrders.length); i++) {
            final tx = transformedOrders[i];
            final rawFuCount = tx['rawData']?['fu_count'];
            print('   [$i] ${tx['soNumber']}: fu_count=$rawFuCount → fuCount=${tx['fuCount']}');
          }
        }

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

  /// Parse fu_count from various types
  int _parseFuCount(dynamic value) {
    if (value == null) {
      return 0;
    } else if (value is int) {
      return value;
    } else if (value is String) {
      return int.tryParse(value) ?? 0;
    } else if (value is num) {
      return value.toInt();
    }
    return 0;
  }

  /// Convert transaction Map to SalesOrder entity for detail page
  SalesOrder _transactionToSalesOrder(Map<String, dynamic> transaction) {
    // Get raw order data which includes full order_line details
    final rawOrder = transaction['rawData'] as Map<String, dynamic>? ?? {};
    
    // Parse order lines from raw order
    List<OrderLine> orderLines = [];
    if (rawOrder['order_line'] != null && rawOrder['order_line'] is List) {
      orderLines = (rawOrder['order_line'] as List).map((line) {
        return OrderLine(
          productId: line['product_id'] as int? ?? 0,
          productName: line['product_name'] as String? ?? 'Unknown',
          productUomQty: (line['product_uom_qty'] as num?)?.toDouble() ?? 0.0,
          priceUnit: (line['price_unit'] as num?)?.toDouble() ?? 0.0,
          analyticDistribution: line['analytic_distribution'],
        );
      }).toList();
    }

    return SalesOrder(
      id: transaction['id'] as int? ?? 0,
      name: transaction['noTransaksi'] as String? ?? 'SO-???',
      partnerName: transaction['customer'] as String? ?? 'Unknown',
      partnerPhone: transaction['phone'] as String?,
      state: transaction['status'] as String? ?? 'draft',
      warehouseId: 1,
      kurirId: null,
      kurirName: transaction['salesRep'] as String?,
      awb: transaction['awb'] as String?,
      dateOrder: (transaction['tanggal'] as DateTime?)?.toIso8601String() ?? DateTime.now().toIso8601String(),
      amountTotal: transaction['nominal'] as double? ?? 0.0,
      orderLines: orderLines,
      partnerStreet: transaction['deliveryAddress'] as String?,
      partnerCity: transaction['deliveryCity'] as String?,
      partnerState: transaction['deliveryProvince'] as String?,
      partnerDistrict: transaction['deliveryDistrict'] as String?,
      paymentTermName: transaction['paymentTerms'] as String?,
      fuCount: rawOrder['fu_count'] as int? ?? 0, // Parse follow-up count from API data
    );
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
                                  
                                  // DEBUG: Print transaction keys to verify fuCount exists
                                  if (index == 0 || transaction['soNumber'] == 'S00003') {
                                    print('🐛 [TRANSACTION_BUILDER] ${transaction['soNumber']}: fuCount=${transaction['fuCount']} (type: ${transaction['fuCount'].runtimeType})');
                                    print('🐛 [TRANSACTION_BUILDER] rawData fu_count=${transaction['rawData']?['fu_count']}');
                                  }

                                  return InkWell(
                                    onTap: () async {
                                      final transaction = transactions[index];
                                      final salesOrder = _transactionToSalesOrder(transaction);
                                      
                                      final updated =
                                          await Navigator.of(context)
                                              .push<Map<String, dynamic>>(
                                        MaterialPageRoute(
                                          builder: (_) => SalesOrderDetailPage(
                                              order: salesOrder),
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
                                                Expanded(
                                                  child: Text(
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
                                                ),
                                                const SizedBox(width: 12),
                                                Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    // ✅ Follow-up count badge
                                                    _buildSmallBadge(
                                                      '${transaction['fuCount'] ?? 0}',
                                                      AppTheme.brandGreen,
                                                      icon: Icons.message_rounded,
                                                    ),
                                                    const SizedBox(width: 8),
                                                    // ✅ Status badge
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
                                              ],
                                            ),
                                            const SizedBox(height: 10),
                                            Wrap(
                                              spacing: 8,
                                              runSpacing: 4,
                                              children: [
                                                _buildBadge(
                                                    'Follow-up: ${transaction['fuCount'] ?? 0}',
                                                    AppTheme.brandGreen),
                                                _buildBadge(
                                                    'Order: ${transaction['orderedCount']}',
                                                    AppTheme.brandBlue),
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

  /// Build small badge with optional icon and count
  Widget _buildSmallBadge(String label, Color color, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
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

