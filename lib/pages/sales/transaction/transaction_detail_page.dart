import 'package:flutter/material.dart';
import 'package:pintarx/config/theme.dart';
import 'package:pintarx/pages/sales/transaction/transaction_edit_page.dart';

class TransactionDetailPage extends StatefulWidget {
  final Map<String, dynamic> transaction;

  const TransactionDetailPage({super.key, required this.transaction});

  @override
  State<TransactionDetailPage> createState() => _TransactionDetailPageState();
}

class _TransactionDetailPageState extends State<TransactionDetailPage> {
  late Map<String, dynamic> transaction;

  @override
  void initState() {
    super.initState();
    transaction = Map<String, dynamic>.from(widget.transaction);
  }

  String _formatDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
  }

  String _formatCurrency(double value) {
    final formatted = value.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => '.',
    );
    return 'Rp $formatted';
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Text(
              label,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            flex: 5,
            child: Text(
              value,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openEditPage() async {
    final updated = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (_) => TransactionEditPage(transaction: transaction),
      ),
    );

    if (updated != null) {
      setState(() {
        transaction = Map<String, dynamic>.from(updated);
      });
    }
  }

  int _estimateShipping() {
    final province = transaction['deliveryProvince'] as String? ?? '';
    final city = transaction['deliveryCity'] as String? ?? '';
    final subdistrict = transaction['deliverySubdistrict'] as String? ?? '';

    if (province.trim().isEmpty || city.trim().isEmpty || subdistrict.trim().isEmpty) {
      return 0;
    }

    const baseFee = 10000;
    const provinceFee = 5000;
    const cityFee = 3000;
    const subdistrictFee = 2000;
    return baseFee + provinceFee + cityFee + subdistrictFee;
  }

  @override
  Widget build(BuildContext context) {
    final date = transaction['tanggal'] as DateTime;
    final status = transaction['status'] as String? ?? '-';
    final phone = transaction['phone'] as String? ?? '-';
    final items = (transaction['items'] as List<Map<String, dynamic>>?) ?? [];
    final address = transaction['deliveryAddress'] as String? ?? '-';
    final province = transaction['deliveryProvince'] as String? ?? '-';
    final city = transaction['deliveryCity'] as String? ?? '-';
    final subdistrict = transaction['deliverySubdistrict'] as String? ?? '-';
    final salesRep = transaction['salesRep'] as String? ?? '-';
    final paymentTerms = transaction['paymentTerms'] as String? ?? '-';
    final isEditable = status.toLowerCase() == 'open';

    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pop(transaction);
        return false;
      },
      child: Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
          title: Text('Detail ${transaction['soNumber'] as String}'),
          backgroundColor: AppTheme.primaryColor,
          actions: [
            if (isEditable)
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Edit Transaksi',
                onPressed: _openEditPage,
              ),
          ],
        ),
        body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        transaction['soNumber'] as String,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          status,
                          style: const TextStyle(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _formatDate(date),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow('Customer', transaction['customer'] as String),
                  _buildInfoRow('Phone', phone),
                  _buildInfoRow('Nominal', _formatCurrency(transaction['nominal'] as double)),
                  _buildInfoRow('Order', '${transaction['orderedCount']} kali'),
                  _buildInfoRow('Canceled', '${transaction['canceledCount']} kali'),
                  _buildInfoRow('Sales Rep', salesRep),
                  _buildInfoRow('Payment Terms', paymentTerms),
                  _buildInfoRow('Delivery', address),
                  _buildInfoRow('Provinsi', province),
                  _buildInfoRow('Kabupaten/Kota', city),
                  _buildInfoRow('Kecamatan', subdistrict),
                ],
              ),
            ),
            const SizedBox(height: 20),
            if (_estimateShipping() > 0)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey[300]!, width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Perkiraan Ongkir',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formatCurrency(_estimateShipping().toDouble()),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            Text(
              'Item SO',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            ...items.map((item) {
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey[200]!, width: 1),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['product'] as String,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Qty: ${item['qty']} x ${_formatCurrency(item['price'] as double)}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      _formatCurrency((item['qty'] as int) * (item['price'] as double)),
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    ),
  );
}
}
