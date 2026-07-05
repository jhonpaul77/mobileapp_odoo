import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pintarx/pages/sales/transaction/transaction_detail_page.dart';
import 'package:pintarx/config/theme.dart';

class TransactionListPage extends StatefulWidget {
  const TransactionListPage({super.key});

  static final List<Map<String, dynamic>> _demoTransactions = [
    {
      'soNumber': 'SO-20260701-001',
      'tanggal': DateTime(2026, 7, 1, 14, 32),
      'customer': 'PT Maju Jaya',
      'phone': '+62 812-3456-7890',
      'nominal': 1525000.0,
      'orderedCount': 4,
      'canceledCount': 0,
      'status': 'Confirm',
      'salesRep': 'Alex Wijaya',
      'paymentTerms': 'TOP 14',
      'deliveryAddress': 'Jl. Merdeka No. 45, Jakarta',
      'items': [
        {'product': 'Paket A', 'analyticAccount': 'Riztastore', 'qty': 2, 'price': 325000.0},
        {'product': 'Paket B', 'analyticAccount': 'Facebook', 'qty': 1, 'price': 875000.0},
      ],
    },
    {
      'soNumber': 'SO-20260701-002',
      'tanggal': DateTime(2026, 7, 1, 12, 10),
      'customer': 'CV Sumber Makmur',
      'phone': '+62 813-9876-5432',
      'nominal': 860000.0,
      'orderedCount': 2,
      'canceledCount': 1,
      'status': 'Open',
      'salesRep': 'Nina Sari',
      'paymentTerms': 'Cash',
      'deliveryAddress': 'Jl. Sudirman No. 78, Bandung',
      'items': [
        {'product': 'Produk C', 'analyticAccount': 'Instagram', 'qty': 3, 'price': 180000.0},
        {'product': 'Produk D', 'analyticAccount': 'Tokopedia', 'qty': 1, 'price': 320000.0},
      ],
    },
    {
      'soNumber': 'SO-20260630-011',
      'tanggal': DateTime(2026, 6, 30, 16, 5),
      'customer': 'UD Berkah Jaya',
      'phone': '+62 811-2233-4455',
      'nominal': 345000.0,
      'orderedCount': 1,
      'canceledCount': 0,
      'status': 'Confirm',
      'salesRep': 'Budi Santoso',
      'paymentTerms': 'TOP 7',
      'deliveryAddress': 'Jl. Veteran No. 12, Bekasi',
      'items': [
        {'product': 'Produk E', 'analyticAccount': 'Shopee', 'qty': 1, 'price': 345000.0},
      ],
    },
    {
      'soNumber': 'SO-20260630-010',
      'tanggal': DateTime(2026, 6, 30, 10, 20),
      'customer': 'PT Agro Mandiri',
      'phone': '+62 816-7788-9900',
      'nominal': 1237500.0,
      'orderedCount': 3,
      'canceledCount': 0,
      'status': 'Confirm',
      'salesRep': 'Rina Putri',
      'paymentTerms': 'Cash',
      'deliveryAddress': 'Jl. Delima No. 22, Surabaya',
      'items': [
        {'product': 'Produk F', 'analyticAccount': 'Lazada', 'qty': 2, 'price': 412500.0},
        {'product': 'Produk G', 'analyticAccount': 'Bukalapak', 'qty': 1, 'price': 412500.0},
      ],
    },
    {
      'soNumber': 'SO-20260629-009',
      'tanggal': DateTime(2026, 6, 29, 9, 15),
      'customer': 'Toko Jaya Sentosa',
      'phone': '+62 817-1122-3344',
      'nominal': 550000.0,
      'orderedCount': 2,
      'canceledCount': 2,
      'status': 'Cancel',
      'salesRep': 'Dini Hartono',
      'paymentTerms': 'TOP 3',
      'deliveryAddress': 'Jl. Ahmad Yani No. 15, Medan',
      'items': [
        {'product': 'Produk B', 'analyticAccount': 'Riztastore', 'qty': 2, 'price': 275000.0},
      ],
    },
    {
      'soNumber': 'SO-20260628-008',
      'tanggal': DateTime(2026, 6, 28, 15, 45),
      'customer': 'PT Dinamis Sejahtera',
      'phone': '+62 818-5566-7788',
      'nominal': 987500.0,
      'orderedCount': 3,
      'canceledCount': 3,
      'status': 'Cancel',
      'salesRep': 'Eka Pratama',
      'paymentTerms': 'Cash',
      'deliveryAddress': 'Jl. Gatot Subroto No. 88, Semarang',
      'items': [
        {'product': 'Paket C', 'analyticAccount': 'Instagram', 'qty': 1, 'price': 450000.0},
        {'product': 'Produk A', 'analyticAccount': 'Facebook', 'qty': 2, 'price': 268750.0},
      ],
    },
    {
      'soNumber': 'SO-20260627-007',
      'tanggal': DateTime(2026, 6, 27, 11, 20),
      'customer': 'CV Sumber Makmur',
      'phone': '+62 813-9876-5432',
      'nominal': 720000.0,
      'orderedCount': 2,
      'canceledCount': 2,
      'status': 'Cancel',
      'salesRep': 'Nina Sari',
      'paymentTerms': 'TOP 14',
      'deliveryAddress': 'Jl. Sudirman No. 78, Bandung',
      'items': [
        {'product': 'Produk D', 'analyticAccount': 'Shopee', 'qty': 2, 'price': 360000.0},
      ],
    },
  ];
  @override
  State<TransactionListPage> createState() => _TransactionListPageState();
}

class _TransactionListPageState extends State<TransactionListPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _statusFilter;

  List<Map<String, dynamic>> get _filteredTransactions {
    final query = _searchQuery.trim().toLowerCase();
    final sorted = List<Map<String, dynamic>>.from(TransactionListPage._demoTransactions)
      ..sort((a, b) => (b['tanggal'] as DateTime).compareTo(a['tanggal'] as DateTime));

    return sorted.where((transaction) {
      final soNumber = (transaction['soNumber'] as String?)?.toLowerCase() ?? '';
      final customer = (transaction['customer'] as String?)?.toLowerCase() ?? '';
      final phone = (transaction['phone'] as String?)?.toLowerCase() ?? '';
      final status = (transaction['status'] as String?)?.toLowerCase() ?? '';

      final matchesStatus = _statusFilter == null ||
          _statusFilter == 'All' ||
          status == _statusFilter?.toLowerCase();

      return matchesStatus && (soNumber.contains(query) ||
          customer.contains(query) ||
          phone.contains(query) ||
          status.contains(query));
    }).toList();
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
        systemOverlayStyle: Theme.of(context).appBarTheme.systemOverlayStyle ?? SystemUiOverlayStyle.dark,
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
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: ListView.separated(
                itemCount: transactions.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final transaction = transactions[index];

                  return InkWell(
                    onTap: () async {
                    final updated = await Navigator.of(context).push<Map<String, dynamic>>(
                      MaterialPageRoute(
                        builder: (_) => TransactionDetailPage(transaction: transaction),
                      ),
                    );

                    if (updated != null) {
                      setState(() {
                        final index = TransactionListPage._demoTransactions.indexWhere(
                          (element) => element['soNumber'] == updated['soNumber'],
                        );
                        if (index != -1) {
                          TransactionListPage._demoTransactions[index] = Map<String, dynamic>.from(updated);
                        }
                      });
                    }
                  },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!, width: 1),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  transaction['soNumber'] as String,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  _formatDate(transaction['tanggal'] as DateTime),
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.person_outline_rounded, size: 16, color: AppTheme.primaryColor),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        transaction['customer'] as String,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.phone_rounded, size: 14, color: Colors.grey),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        (transaction['phone'] as String?) ?? '-',
                                        style: TextStyle(
                                          color: Colors.grey[600],
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
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _formatCurrency(transaction['nominal'] as double),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.successColor,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    transaction['status'] as String,
                                    style: const TextStyle(
                                      color: AppTheme.primaryColor,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                _buildBadge('Order: ${transaction['orderedCount']}', AppTheme.brandBlue),
                                const SizedBox(width: 8),
                                _buildBadge('Canceled: ${transaction['canceledCount']}', AppTheme.errorColor),
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
          ],
        ),
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
