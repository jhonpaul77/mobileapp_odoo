import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../config/theme.dart';
import '../../domain/entities/sales_order.dart';

/// SalesOrderDetailPage - Detail Transaksi Penjualan
///
/// Displays complete sales order information with order lines
class SalesOrderDetailPage extends StatefulWidget {
  final SalesOrder order;

  const SalesOrderDetailPage({
    super.key,
    required this.order,
  });

  @override
  State<SalesOrderDetailPage> createState() => _SalesOrderDetailPageState();
}

class _SalesOrderDetailPageState extends State<SalesOrderDetailPage> {
  final _currencyFormat =
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateStr;
    }
  }

  /// Format field value - convert false/null to "-"
  String _formatFieldValue(dynamic value) {
    if (value == null || value == false) {
      return '-';
    }
    return value.toString();
  }

  /// Send WhatsApp payment reminder
  Future<void> _sendWhatsAppReminder() async {
    final order = widget.order;

    // TODO: Check phone from API response when field is added
    // For now, phone field doesn't exist in sales order API
    final String? customerPhone =
        null; // Will be: order.customerPhone when API is updated

    // Check if phone number exists
    if (customerPhone == null || customerPhone.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'No WhatsApp Customer Not Found',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    // Format message yang user-friendly dengan emoji
    final message = '''
🔔 *Pengingat Pembayaran*

Halo *${order.customerName}*,

Kami ingin mengingatkan pembayaran untuk pesanan Anda:

📋 *Detail Pesanan:*
• Nomor SO: *${order.name}*
• Tanggal Order: ${order.dateOrderFormatted}
• Total Pembayaran: *${_currencyFormat.format(order.amountTotal)}*

💳 Mohon segera melakukan pembayaran agar pesanan dapat segera kami proses.

✅ Jika pembayaran sudah dilakukan, silakan kirimkan bukti transfer untuk konfirmasi.

Terima kasih atas kepercayaan Anda! 🙏
''';

    try {
      // Format phone number (remove leading 0, add country code)
      String formattedPhone = customerPhone.trim();
      if (formattedPhone.startsWith('0')) {
        formattedPhone = formattedPhone.substring(1);
      }
      if (!formattedPhone.startsWith('62')) {
        formattedPhone = '62$formattedPhone';
      }

      // Encode message for URL
      final encodedMessage = Uri.encodeComponent(message);

      // WhatsApp URL
      final whatsappUrl = 'https://wa.me/$formattedPhone?text=$encodedMessage';

      // Launch WhatsApp
      if (await canLaunch(whatsappUrl)) {
        await launch(whatsappUrl);

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 12),
                  Text('Membuka WhatsApp...'),
                ],
              ),
              backgroundColor: Color(0xFF25D366),
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tidak dapat membuka WhatsApp'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _printTransaction() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Preview Cetak'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'RECEIPT TRANSAKSI',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const Divider(),
                Text('No. SO: ${widget.order.name}',
                    style: const TextStyle(fontSize: 12)),
                Text('Tanggal: ${_formatDate(widget.order.dateOrder)}',
                    style: const TextStyle(fontSize: 12)),
                const SizedBox(height: 8),
                Text('Customer: ${widget.order.customerName}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 8),
                const Text('DETAIL ITEM',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                const Divider(),
                ...widget.order.orderLines.map((line) {
                  final subtotal = line.productUomQty * line.priceUnit;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(line.productName,
                          style: const TextStyle(fontSize: 11)),
                      Text(
                          'Qty: ${line.productUomQty} | Harga: ${_currencyFormat.format(line.priceUnit)}',
                          style:
                              TextStyle(fontSize: 10, color: Colors.grey[600])),
                      Text('Subtotal: ${_currencyFormat.format(subtotal)}',
                          style: const TextStyle(
                              fontSize: 11, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                    ],
                  );
                }),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('TOTAL:',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 12)),
                    Text(_currencyFormat.format(widget.order.amountTotal),
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: AppTheme.primaryColor)),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Catatan: Fitur print Bluetooth akan tersedia di versi berikutnya. Untuk sekarang, gunakan fungsi screenshot untuk menyimpan.',
                  style: TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Tutup'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final order = widget.order;
    final isEditable = order.state.toLowerCase() == 'draft' ||
        order.state.toLowerCase() == 'sent';
    final isCancel = order.state.toLowerCase() == 'cancel';
    final isConfirm = order.state.toLowerCase() == 'sale' ||
        order.state.toLowerCase() == 'done';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Transaction Detail',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 18)),
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: const Icon(Icons.print_rounded, color: Colors.white),
              onPressed: _printTransaction,
              tooltip: 'Print',
            ),
          ),
          if (isCancel)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Fitur ubah status akan segera hadir'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                child: const Text(
                  'Buka',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          if (isConfirm)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Fitur cancel transaksi akan segera hadir'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                child: const Text(
                  'Cancel',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          if (isEditable)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Fitur edit transaksi akan segera hadir'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                child: const Text(
                  'Edit',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Color(order.stateColor).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: Color(order.stateColor).withValues(alpha: 0.3),
                    width: 1),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Color(order.stateColor),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child:
                        const Icon(Icons.check, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _formatDate(order.dateOrder),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: theme.textTheme.bodyMedium?.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // WhatsApp Button (only for Open status)
                  if (isEditable) ...[
                    GestureDetector(
                      onTap: _sendWhatsAppReminder,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(
                              0xFF25D366), // WhatsApp green original
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF25D366)
                                  .withValues(alpha: 0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const FaIcon(
                          FontAwesomeIcons.whatsapp,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Color(order.stateColor),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      order.stateLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Main Info Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
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
                        alpha:
                            theme.brightness == Brightness.dark ? 0.3 : 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with SO Number
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sales Order No',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: theme.textTheme.bodySmall?.color,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            order.name,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: theme.textTheme.bodyLarge?.color,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Order Date',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: theme.textTheme.bodySmall?.color,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            order.dateOrderFormatted,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: theme.textTheme.bodyLarge?.color,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Divider(
                    color: theme.brightness == Brightness.dark
                        ? Colors.grey[700]
                        : Colors.grey[200],
                    height: 1,
                  ),
                  const SizedBox(height: 16),

                  // Grid Info
                  _buildInfoGrid([
                    {
                      'label': 'Customer',
                      'value': order.customerName,
                    },
                    {
                      'label': 'Customer ID',
                      'value': order.partnerId.toString(),
                    },
                  ]),
                  const SizedBox(height: 12),
                  _buildInfoGrid([
                    {
                      'label': 'Warehouse ID',
                      'value': _formatFieldValue(order.warehouseId),
                    },
                    {
                      'label': 'Kurir ID',
                      'value': _formatFieldValue(order.kurirId),
                    },
                  ]),
                  const SizedBox(height: 12),
                  _buildInfoGrid([
                    {
                      'label': 'AWB',
                      'value': _formatFieldValue(order.awb),
                    },
                  ]),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Items Card
            if (order.orderLines.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
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
                          alpha:
                              theme.brightness == Brightness.dark ? 0.3 : 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Order Lines',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: theme.textTheme.bodyMedium?.color,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${order.orderLines.length} item(s)',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...order.orderLines.asMap().entries.map((entry) {
                      final index = entry.key;
                      final line = entry.value;
                      final isLast = index == order.orderLines.length - 1;
                      final subtotal = line.productUomQty * line.priceUnit;

                      // Parse analytic distribution
                      String analyticInfo = '';
                      if (line.analyticDistribution != null &&
                          line.analyticDistribution!.isNotEmpty) {
                        final entries =
                            line.analyticDistribution!.entries.toList();
                        analyticInfo = entries
                            .map((e) => '${e.key}: ${e.value}%')
                            .join(', ');
                      }

                      return Column(
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color:
                                      AppTheme.brandBlue.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.inventory_2_outlined,
                                  size: 16,
                                  color: AppTheme.brandBlue,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      line.productName,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: theme.textTheme.bodyLarge?.color,
                                      ),
                                    ),
                                    if (analyticInfo.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        'Analytic: $analyticInfo',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color:
                                              theme.textTheme.bodySmall?.color,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 4),
                                    Text(
                                      'Qty: ${line.productUomQty} | Price: ${_currencyFormat.format(line.priceUnit)}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: theme.textTheme.bodySmall?.color,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    _currencyFormat.format(subtotal),
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                      color: theme.textTheme.bodyLarge?.color,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          if (!isLast)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Divider(
                                color: theme.brightness == Brightness.dark
                                    ? Colors.grey[700]
                                    : Colors.grey[200],
                                height: 1,
                              ),
                            ),
                        ],
                      );
                    }),
                  ],
                ),
              ),
            const SizedBox(height: 16),

            // Total Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
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
                        alpha:
                            theme.brightness == Brightness.dark ? 0.3 : 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Quantity',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: theme.textTheme.bodyMedium?.color,
                        ),
                      ),
                      Text(
                        '${order.totalQty} qty',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: theme.textTheme.bodyMedium?.color,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Divider(
                    color: theme.brightness == Brightness.dark
                        ? Colors.grey[700]
                        : Colors.grey[200],
                    height: 1,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Grand Total',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: theme.textTheme.bodyLarge?.color,
                        ),
                      ),
                      Text(
                        _currencyFormat.format(order.amountTotal),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoGrid(List<Map<String, String>> items) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items.map((item) {
        return Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item['label'] ?? '',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: theme.textTheme.bodySmall?.color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                item['value'] ?? '-',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: theme.textTheme.bodyLarge?.color,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
