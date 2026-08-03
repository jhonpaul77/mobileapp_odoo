import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../config/theme.dart';
import '../../../../services/sales_service.dart';
import '../../../../services/secure_storage_service.dart';
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
  final logger = Logger();

  SalesOrder? _currentOrder;

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
    _currentOrder = widget.order;
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

  /// Send follow-up via WhatsApp with order details
  Future<void> _sendWhatsAppReminder() async {
    final order = widget.order;

    // DEBUG: Print order details
    print('📞 [FOLLOWUP] Order ID: ${order.id}');
    print('📞 [FOLLOWUP] Order Name: ${order.name}');
    print('📞 [FOLLOWUP] Customer Name: ${order.customerName}');
    print('📞 [FOLLOWUP] Partner Phone: ${order.partnerPhone}');
    print('📞 [FOLLOWUP] Order Lines Count: ${order.orderLines.length}');

    // Get customer phone from partner_phone field
    String? customerPhone = order.partnerPhone;

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
      // ✅ Get logged-in username for CS name
      final storage = SecureStorageService();
      final userData = await storage.getUserData();
      final csName = userData?['username'] as String? ?? 'CS';
      print('📞 [FOLLOWUP] CS Name: $csName');

      // Get customer name
      String customerName = order.customerName;
      if (customerName.contains('(')) {
        customerName = customerName.split('(')[0].trim();
      }

      // Build order lines text
      String orderLinesText = '';
      for (var line in order.orderLines) {
        final qty = line.productUomQty.toInt();
        final product = line.productNameDisplay;
        orderLinesText += '$qty (pcs) $product\n';
      }

      // ✅ Build the follow-up message with logged-in username
      final message = '''Hai kak $customerName ($customerPhone)

Dengan saya CS $csName :

Kami sudah terima pesanannya dengan rincian sebagai berikut:
$orderLinesText
_BISA TRANSFER_ maupun _BAYAR DI TEMPAT_

Tolong isi alamat kakak dengan lengkap :
RT/RW/Nama Jalan: 
Desa/Kelurahan: 
Kecamatan: 
Kota/Kab: 
Provinsi: 

Mohon segera dikonfirmasi ya kak untuk pesanannya.

TERIMA KASIH''';

      // Format phone number correctly - extract only digits
      String formattedPhone = customerPhone.trim();
      print('🔧 [PHONE_FORMAT] Original: $customerPhone');
      
      // Remove all non-digit characters (spaces, dashes, +, etc)
      formattedPhone = formattedPhone.replaceAll(RegExp(r'[^0-9]'), '');
      print('🔧 [PHONE_FORMAT] After removing non-digits: $formattedPhone');
      
      // Remove leading 0 if exists
      if (formattedPhone.startsWith('0')) {
        formattedPhone = formattedPhone.substring(1);
        print('🔧 [PHONE_FORMAT] After removing leading 0: $formattedPhone');
      }
      
      // Remove leading 62 if exists (to avoid duplication)
      int removeCount = 0;
      while (formattedPhone.startsWith('62')) {
        formattedPhone = formattedPhone.substring(2);
        removeCount++;
      }
      if (removeCount > 0) {
        print('🔧 [PHONE_FORMAT] Removed $removeCount leading 62: $formattedPhone');
      }
      
      // Ensure it starts with 62
      if (!formattedPhone.startsWith('62')) {
        formattedPhone = '62$formattedPhone';
        print('🔧 [PHONE_FORMAT] Added 62 prefix: $formattedPhone');
      }
      
      print('✅ [PHONE_FORMAT] Final formatted phone: $formattedPhone');

      // Encode message for URL
      final encodedMessage = Uri.encodeComponent(message);

      bool launched = false;

      // Use api.whatsapp.com
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
          // If canLaunchUrl fails, try anyway
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
        // ✅ Tandai sudah di follow-up (tidak perlu counter)
        final orderId = widget.order.id;
        final prefs = await SharedPreferences.getInstance();
        final key = 'followup_sent_$orderId';
        await prefs.setBool(key, true);
        print('✅ Follow-up marked as sent');
        
        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 12),
                  Text('Follow-up berhasil dikirim'),
                ],
              ),
              backgroundColor: Colors.green,
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

    // Get customer phone from partner_phone field
    String? customerPhone = order.partnerPhone;

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

    // Check if at least kurir OR awb exists (message can be sent with either one or both)
    final hasKurirName = order.kurirName != null && order.kurirName!.isNotEmpty;
    final hasAwb = order.awb != null && order.awb.toString().isNotEmpty && order.awb.toString() != 'false';
    
    if (!hasKurirName && !hasAwb) {
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
      final kurirName = (hasKurirName ? order.kurirName : '-') ?? '-';
      final awbNumber = (hasAwb ? order.awb?.toString() : '-') ?? '-';

      // Build the shipment tracking message - per user format
      final message = '''Halo kak $customerNameOnly ($customerPhone)

Dengan saya CS Armand dari UNIK TRENDI

Memberitahukan bahwa pesanannya sudah terkirim melalui kurir $kurirName, dengan nomor resi: $awbNumber

Mohon ditunggu. Jika kedapatan kurir yang tidak mau antar paket ke lokasi, jangan lupa langsung hubungi kami ya kak.

Mohon sertakan bukti chat nya akan kami ganti rugi 100%

Paket yang terkirim tidak dapat dicancel. Jika menolak paket, maka harus mengganti biaya kirim ya kak *(penggantian ongkir jangan diberikan ke kurir)*.

Dimohon untuk membayar paket sesuai kesepakatan di awal . :-)

TERIMA KASIH''';

      // Format phone number correctly - extract only digits
      String formattedPhone = customerPhone.trim();
      print('🔧 [PHONE_FORMAT] Original: $customerPhone');
      
      // Remove all non-digit characters (spaces, dashes, +, etc)
      formattedPhone = formattedPhone.replaceAll(RegExp(r'[^0-9]'), '');
      print('🔧 [PHONE_FORMAT] After removing non-digits: $formattedPhone');
      
      // Remove leading 0 if exists
      if (formattedPhone.startsWith('0')) {
        formattedPhone = formattedPhone.substring(1);
        print('🔧 [PHONE_FORMAT] After removing leading 0: $formattedPhone');
      }
      
      // Remove leading 62 if exists (to avoid duplication)
      int removeCount = 0;
      while (formattedPhone.startsWith('62')) {
        formattedPhone = formattedPhone.substring(2);
        removeCount++;
      }
      if (removeCount > 0) {
        print('🔧 [PHONE_FORMAT] Removed $removeCount leading 62: $formattedPhone');
      }
      
      // Ensure it starts with 62
      if (!formattedPhone.startsWith('62')) {
        formattedPhone = '62$formattedPhone';
        print('🔧 [PHONE_FORMAT] Added 62 prefix: $formattedPhone');
      }
      
      print('✅ [PHONE_FORMAT] Final formatted phone: $formattedPhone');

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
        // ✅ Increment counter untuk Send WA
        final orderId = widget.order.id;
        final prefs = await SharedPreferences.getInstance();
        final key = 'wa_count_${orderId}_send';
        final currentCount = prefs.getInt(key) ?? 0;
        await prefs.setInt(key, currentCount + 1);
        print('✅ Send WA counter: +1 (total: ${currentCount + 1})');
        
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
    final result = await Navigator.of(context).push<SalesOrder?>(
      MaterialPageRoute(
        builder: (_) => SalesOrderEditPage(order: widget.order),
      ),
    );

    if (result != null) {
      // Update is successful - use the updated order returned from edit page
      logger.i('✅ Sales order updated, refreshing display...');
      
      if (mounted) {
        setState(() {
          _currentOrder = result;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('✅ Perubahan berhasil disimpan'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _confirmOrder() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Konfirmasi Transaksi'),
          content: Text(
            'Apakah Anda yakin ingin mengkonfirmasi transaksi ${widget.order.name}?\n\n'
            'Status akan berubah dari Draft menjadi Confirmed dan transaksi tidak dapat diedit lagi.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Batal'),
            ),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                minimumSize: const Size(0, 32),
              ),
              icon:
                  const Icon(Icons.check_circle, color: Colors.white, size: 16),
              label: const Text('Konfirmasi',
                  style: TextStyle(color: Colors.white, fontSize: 13)),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    // Show loading
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('⏳ Mengkonfirmasi transaksi...'),
        duration: Duration(seconds: 30),
      ),
    );

    try {
      // Call confirm API
      final salesService = SalesService();
      final result = await salesService.confirmOrder(orderId: _currentOrder!.id);

      if (!mounted) return;

      // Hide loading snackbar
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      if (result['Success'] == true) {
        // Success
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('✅ Transaksi ${widget.order.name} berhasil dikonfirmasi'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );

        // Return to list with refresh flag
        Navigator.of(context).pop(true);
      } else {
        // Failed
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Gagal konfirmasi: ${result['Message']}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final order = _currentOrder ?? widget.order;
    final isEditable = order.state.toLowerCase() == 'draft' ||
        order.state.toLowerCase() == 'sent';
    // final isCancel = order.state.toLowerCase() == 'cancel';
    // final isConfirm = order.state.toLowerCase() == 'sale' ||
    order.state.toLowerCase() == 'done';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Detail',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 18)),
        backgroundColor: Color(order.stateColor),
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          // Print Button
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Center(
              child: GestureDetector(
                onTap: _printTransaction,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.print_rounded,
                    size: 18,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
          ),
          
          // Edit Button
          if (isEditable)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Center(
                child: GestureDetector(
                  onTap: _openEditPage,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Edit',
                      style: TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          
          // Confirm Button
          if (isEditable)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: GestureDetector(
                  onTap: _confirmOrder,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Confirm',
                      style: TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
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

                  // Grid Info - Customer & Status Badge with WhatsApp Button
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Customer Info (left side)
                      Expanded(
                        child: _buildInfoGrid([
                          {
                            'label': 'Customer',
                            'value': _getCustomerName(order.customerId),
                          },
                        ]),
                      ),
                      // Status Badge & WhatsApp Button (right side, stacked)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          // Status Badge
                          if (isEditable)
                            // Open status - plain badge
                            Container(
                              margin: const EdgeInsets.only(left: 12),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Color(order.stateColor).withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                order.stateLabel,
                                style: TextStyle(
                                  color: Color(order.stateColor),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            )
                          else
                            // Sale/Confirm/Other status - colored badge
                            Container(
                              margin: const EdgeInsets.only(left: 12),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Color(order.stateColor),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                order.stateLabel,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          
                          const SizedBox(height: 6),
                          
                          // WhatsApp Button
                          if (isEditable)
                            GestureDetector(
                              onTap: _sendWhatsAppReminder,
                              child: Container(
                                margin: const EdgeInsets.only(left: 12),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF25D366).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: const Color(0xFF25D366).withValues(alpha: 0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.message_rounded,
                                      size: 14,
                                      color: Color(0xFF25D366),
                                    ),
                                    const SizedBox(width: 4),
                                    const Text(
                                      'Follow Up',
                                      style: TextStyle(
                                        color: Color(0xFF25D366),
                                        fontWeight: FontWeight.w600,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else
                            // For Sale/Confirm status - Send WA button
                            GestureDetector(
                              onTap: _sendWhatsAppShipment,
                              child: Container(
                                margin: const EdgeInsets.only(left: 12),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF25D366),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.send_rounded,
                                      size: 14,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 4),
                                    const Text(
                                      'No Resi',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                  
                  // Phone Information (di atas alamat)
                  if (order.partnerPhone != null && order.partnerPhone!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Phone',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            order.partnerPhone!,
                            style: TextStyle(
                              fontSize: 13,
                              color: theme.textTheme.bodyMedium?.color,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  // Address Information (above Warehouse)
                  if (order.partnerStreet != null || order.partnerDistrict != null || order.partnerCity != null || order.partnerState != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (order.partnerStreet != null)
                          _buildInfoRow('Alamat', order.partnerStreet!),
                        // Compact line for Kecamatan, Kota, Provinsi
                        if (order.partnerDistrict != null || order.partnerCity != null || order.partnerState != null)
                          Text(
                            '${order.partnerDistrict ?? ''} ${order.partnerCity ?? ''} ${order.partnerState ?? ''}'.trim(),
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.textTheme.bodyMedium?.color,
                            ),
                          ),
                      ],
                    ),
                  
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
                  _buildInfoGrid([
                    {
                      'label': 'AWB',
                      'value': _formatFieldValue(order.awb),
                    },
                    {
                      'label': 'Payment Term',
                      'value': order.paymentTermName ?? 'N/A',
                    },
                  ]),
                  const SizedBox(height: 12),
                  
                  // Notes
                  if (order.notes != null && order.notes!.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildCopyableInfoRow('Catatan', order.notes!),
                      ],
                    ),
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

  /// Build a single info row (label + value)
  Widget _buildInfoRow(String label, String value) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: theme.textTheme.bodySmall?.color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: theme.textTheme.bodyLarge?.color,
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  /// Build copyable info row with copy button (untuk notes/catatan)
  Widget _buildCopyableInfoRow(String label, String value) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: theme.textTheme.bodySmall?.color,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            color: theme.brightness == Brightness.dark
                ? Colors.grey[800]
                : Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  // Copy to clipboard
                  Clipboard.setData(ClipboardData(text: value));
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Row(
                        children: [
                          Icon(Icons.check_circle,
                              color: Colors.white, size: 18),
                          SizedBox(width: 8),
                          Text('Catatan disalin ke clipboard'),
                        ],
                      ),
                      backgroundColor: Colors.green,
                      duration: const Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    Icons.content_copy,
                    size: 16,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}