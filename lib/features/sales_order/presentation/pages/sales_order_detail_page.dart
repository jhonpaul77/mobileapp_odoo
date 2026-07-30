import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../config/theme.dart';
import '../../domain/entities/order_line.dart';
import '../../domain/entities/sales_order.dart';
import 'sales_order_edit_page.dart';

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

  @override
  void initState() {
    super.initState();
    // No need to load names anymore - API provides them directly
  }

  /// Format field value - convert false/null to "-"
  String _formatFieldValue(dynamic value) {
    if (value == null || value == false) {
      return '-';
    }
    return value.toString();
  }

  /// Get customer name - use API value from order
  String _getCustomerName(int? customerId) {
    return widget.order.customerName;
  }

  /// Get product name - use API value from order line
  String _getProductName(dynamic productId, OrderLine line) {
    return line.productNameDisplay;
  }

  /// Send WhatsApp order confirmation message
  Future<void> _sendWhatsAppReminder() async {
    final order = widget.order;

    // Get customer phone from order
    String? customerPhone;
    if (order.customerName.contains('(') && order.customerName.contains(')')) {
      // Extract phone from format "Name (phone)"
      final match = RegExp(r'\((\d+)\)').firstMatch(order.customerName);
      if (match != null) {
        customerPhone = match.group(1);
      }
    }

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
                    'Nomor WhatsApp pelanggan tidak ditemukan',
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

    try {
      // Get current user name
      String senderName = 'Tim Penjualan';
      try {
        // Try to get from AuthService or just use a default
        senderName = 'Tim Penjualan';
      } catch (e) {
        print('Could not get user name: $e');
      }

      // Get customer name without phone
      String customerNameOnly = order.customerName;
      if (customerNameOnly.contains('(')) {
        customerNameOnly = customerNameOnly.split('(')[0].trim();
      }

      // Build items list
      String itemsList = '';
      for (final line in order.orderLines) {
        final qty = line.productUomQty.toInt();
        final product = _getProductName(line.productId, line);
        itemsList += '$qty (pcs) $product\n';
      }

      // Build address section for customer to fill in
      final addressSection = '''Tolong isi alamat kakak dengan lengkap :
RT/RW/Nama Jalan: 
Desa/Kelurahan: 
Kecamatan: 
Kota/Kab: 
Provinsi: ''';

      // Build the full message
      final message = '''Halo kak $customerNameOnly

Dengan saya ($senderName) :

Kami sudah terima pesanannya  dengan rincian sebagai berikut:
$itemsList
_BISA TRANSFER_ maupun _BAYAR DI TEMPAT_

$addressSection

Mohon segera dikonfirmasi ya kak untuk pesanannya. 

TERIMA KASIH''';

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

      bool launched = false;

      // Use api.whatsapp.com - the only reliable method that works
      final whatsappUrl =
          'https://api.whatsapp.com/send?phone=$formattedPhone&text=$encodedMessage';
      print('🔵 Opening WhatsApp: $whatsappUrl');

      try {
        if (await canLaunchUrl(Uri.parse(whatsappUrl))) {
          await launchUrl(
            Uri.parse(whatsappUrl),
            mode: LaunchMode.externalApplication,
          );
          launched = true;
          print('✅ WhatsApp opened successfully');
        } else {
          print('⚠️ Cannot launch URL');
          // If canLaunchUrl fails, try anyway - sometimes it fails but still works
          try {
            await launchUrl(
              Uri.parse(whatsappUrl),
              mode: LaunchMode.externalApplication,
            );
            launched = true;
            print('✅ WhatsApp opened (after retry)');
          } catch (e) {
            print('❌ Error launching: $e');
          }
        }
      } catch (e) {
        print('❌ Exception: $e');
      }

      if (launched) {
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
            SnackBar(
              content: const Text('Membuka WhatsApp Web di browser...'),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 3),
              action: SnackBarAction(
                label: 'Salin Pesan',
                textColor: Colors.white,
                onPressed: () {
                  // Copy message to clipboard
                  Clipboard.setData(ClipboardData(text: message));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Pesan disalin ke clipboard'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
              ),
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Error in WhatsApp: $e');
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

  /// Send WhatsApp shipment tracking message (for Sale/Confirm status)
  Future<void> _sendWhatsAppShipment() async {
    final order = widget.order;

    // Get customer phone from order
    String? customerPhone;
    if (order.customerName.contains('(') && order.customerName.contains(')')) {
      // Extract phone from format "Name (phone)"
      final match = RegExp(r'\((\d+)\)').firstMatch(order.customerName);
      if (match != null) {
        customerPhone = match.group(1);
      }
    }

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
                    'Nomor WhatsApp pelanggan tidak ditemukan',
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

    // Check if kurir and awb exist
    if ((order.kurirName == null || order.kurirName!.isEmpty) &&
        (order.awb == null || order.awb!.isEmpty)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.warning_outlined, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Data kurir dan nomor resi belum tersedia',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    try {
      // Get customer name without phone
      String customerNameOnly = order.customerName;
      if (customerNameOnly.contains('(')) {
        customerNameOnly = customerNameOnly.split('(')[0].trim();
      }

      // Get kurir name and AWB
      final kurirName = order.kurirName ?? '-';
      final awbNumber = order.awb?.toString() ?? '-';

      // Build the shipment tracking message
      final message = '''Halo kak $customerNameOnly

Dengan saya CS Armand dari UNIK TRENDI

Memberitahukan bahwa pesanannya sudah terkirim melalui kurir $kurirName, dengan nomor resi: $awbNumber

Mohon ditunggu. Jika kedapatan kurir yang tidak mau antar paket ke lokasi, jangan lupa langsung hubungi kami ya kak.

Mohon sertakan bukti chat nya akan kami ganti rugi 100%

Paket yang terkirim tidak dapat dicancel. Jika menolak paket, maka harus mengganti biaya kirim ya kak *(penggantian ongkir jangan diberikan ke kurir)*.

Dimohon untuk membayar paket sesuai kesepakatan di awal . :-)

TERIMA KASIH''';

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

      bool launched = false;

      // Use api.whatsapp.com - the only reliable method that works
      final whatsappUrl =
          'https://api.whatsapp.com/send?phone=$formattedPhone&text=$encodedMessage';
      print('🔵 Opening WhatsApp: $whatsappUrl');

      try {
        if (await canLaunchUrl(Uri.parse(whatsappUrl))) {
          await launchUrl(
            Uri.parse(whatsappUrl),
            mode: LaunchMode.externalApplication,
          );
          launched = true;
          print('✅ WhatsApp opened successfully');
        } else {
          print('⚠️ Cannot launch URL');
          // If canLaunchUrl fails, try anyway - sometimes it fails but still works
          try {
            await launchUrl(
              Uri.parse(whatsappUrl),
              mode: LaunchMode.externalApplication,
            );
            launched = true;
            print('✅ WhatsApp opened (after retry)');
          } catch (e) {
            print('❌ Error launching: $e');
          }
        }
      } catch (e) {
        print('❌ Exception: $e');
      }

      if (launched) {
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
            SnackBar(
              content: const Text('Membuka WhatsApp Web di browser...'),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 3),
              action: SnackBarAction(
                label: 'Salin Pesan',
                textColor: Colors.white,
                onPressed: () {
                  // Copy message to clipboard
                  Clipboard.setData(ClipboardData(text: message));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Pesan disalin ke clipboard'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
              ),
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Error in WhatsApp: $e');
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
                Text('Customer: ${_getCustomerName(widget.order.customerId)}',
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
                      Text(_getProductName(line.productId, line),
                          style: const TextStyle(fontSize: 11)),
                      Text(
                          'Qty: ${line.productUomQty} | Harga: ${_currencyFormat.format(line.priceUnit)}',
                          style:
                              TextStyle(fontSize: 10, color: Colors.grey[600])),
                      if (line.analyticDistributionName.isNotEmpty &&
                          line.analyticDistributionName != '-')
                        Text('Analytic: ${line.analyticDistributionName}',
                            style: TextStyle(
                                fontSize: 10, color: Colors.grey[600])),
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

  Future<void> _openEditPage() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => SalesOrderEditPage(order: widget.order),
      ),
    );

    if (result == true) {
      // Update is successful - return to previous page to trigger refresh
      if (mounted) {
        Navigator.of(context).pop(true); // Return success to parent
      }
    }
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
                onPressed: _openEditPage,
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
                        child: const Icon(
                          Icons.message,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  // WhatsApp Button (for Sale/Confirm status - shipment tracking)
                  if (order.state.toLowerCase() == 'sale' ||
                      order.state.toLowerCase() == 'confirm') ...[
                    GestureDetector(
                      onTap: _sendWhatsAppShipment,
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
                        child: const Icon(
                          Icons.message,
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
                      'value': _getCustomerName(order.customerId),
                    },
                    {
                      'label': 'Customer ID',
                      'value': order.partnerId.toString(),
                    },
                  ]),
                  const SizedBox(height: 12),
                  if ((order.partnerStreet != null && order.partnerStreet!.isNotEmpty) ||
                      (order.partnerStreet2 != null && order.partnerStreet2!.isNotEmpty))
                    _buildInfoGrid([
                      {
                        'label': 'Alamat',
                        'value': [
                          if (order.partnerStreet != null &&
                              order.partnerStreet!.isNotEmpty)
                            order.partnerStreet,
                          if (order.partnerStreet2 != null &&
                              order.partnerStreet2!.isNotEmpty)
                            order.partnerStreet2,
                        ].join(', '),
                      },
                    ]),
                  if ((order.partnerStreet != null && order.partnerStreet!.isNotEmpty) ||
                      (order.partnerStreet2 != null && order.partnerStreet2!.isNotEmpty))
                    const SizedBox(height: 12),
                  if ((order.partnerDistrict != null &&
                          order.partnerDistrict!.isNotEmpty) ||
                      (order.partnerCity != null && order.partnerCity!.isNotEmpty) ||
                      (order.partnerState != null && order.partnerState!.isNotEmpty))
                    _buildInfoGrid([
                      {
                        'label': 'Kecamatan',
                        'value': order.partnerDistrict ?? '-',
                      },
                      {
                        'label': 'Kota',
                        'value': order.partnerCity ?? '-',
                      },
                    ]),
                  if ((order.partnerDistrict != null &&
                          order.partnerDistrict!.isNotEmpty) ||
                      (order.partnerCity != null && order.partnerCity!.isNotEmpty) ||
                      (order.partnerState != null && order.partnerState!.isNotEmpty))
                    const SizedBox(height: 12),
                  if (order.partnerState != null && order.partnerState!.isNotEmpty)
                    _buildInfoGrid([
                      {
                        'label': 'Provinsi',
                        'value': order.partnerState ?? '-',
                      },
                    ]),
                  if (order.partnerState != null && order.partnerState!.isNotEmpty)
                    const SizedBox(height: 12),
                  _buildInfoGrid([
                    {
                      'label': 'Warehouse',
                      'value': order.warehouseNameDisplay ?? 'N/A',
                    },
                    {
                      'label': 'Kurir',
                      'value': order.kurirNameDisplay ?? 'N/A',
                    },
                  ]),
                  const SizedBox(height: 12),
                  if (order.notes != null && order.notes!.isNotEmpty)
                    _buildInfoGrid([
                      {
                        'label': 'Catatan',
                        'value': order.notes ?? '-',
                      },
                    ]),
                  if (order.notes != null && order.notes!.isNotEmpty)
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
                                      _getProductName(line.productId, line),
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: theme.textTheme.bodyLarge?.color,
                                      ),
                                    ),
                                    if (line.analyticDistributionName
                                            .isNotEmpty &&
                                        line.analyticDistributionName !=
                                            '-') ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        'Analytic: ${line.analyticDistributionName}',
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
