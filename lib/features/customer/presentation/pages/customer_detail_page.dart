import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../config/theme.dart';
import '../../../../services/config_service.dart';
import '../../../../services/sales_service.dart';
import '../../../../services/secure_storage_service.dart';
import '../../../location/data/datasources/location_remote_datasource.dart';
import '../../../sales_order/domain/entities/sales_order.dart';
import '../../../sales_order/presentation/pages/sales_order_detail_page.dart';
import '../../domain/entities/customer.dart';
import 'customer_edit_page.dart';

/// Helper class to hold customer details with resolved names
class CustomerDetails {
  final Customer customer;
  final String? districtName;
  final String? cityName;
  final String? stateName;

  CustomerDetails({
    required this.customer,
    this.districtName,
    this.cityName,
    this.stateName,
  });
}

/// CustomerDetailPage - Display detailed customer information
///
/// Shows all customer data from Odoo API in a beautiful layout
class CustomerDetailPage extends StatefulWidget {
  final Customer customer;

  const CustomerDetailPage({
    super.key,
    required this.customer,
  });

  @override
  State<CustomerDetailPage> createState() => _CustomerDetailPageState();
}

class _CustomerDetailPageState extends State<CustomerDetailPage> {
  late Future<CustomerDetails> _customerDetailsFuture;

  @override
  void initState() {
    super.initState();
    _customerDetailsFuture = _loadCustomerDetails();
  }

  Future<CustomerDetails> _loadCustomerDetails() async {
    try {
      final configService = ConfigService();
      final storage = SecureStorageService();

      final config = await configService.load();
      final db = config['database'] as String?;
      final apiKey = await storage.getAccessToken();

      if (db == null || apiKey == null) {
        return CustomerDetails(customer: widget.customer);
      }

      final locationDatasource = LocationRemoteDataSource();

      // Load location names
      String? districtName;
      String? cityName;
      String? stateName;

      if (widget.customer.districtId != null) {
        districtName = await locationDatasource.getDistrictName(
          districtId: widget.customer.districtId!,
          db: db,
          apiKey: apiKey,
        );
      }

      if (widget.customer.cityId != null) {
        cityName = await locationDatasource.getCityName(
          cityId: widget.customer.cityId!,
          db: db,
          apiKey: apiKey,
        );
      }

      if (widget.customer.stateId != null) {
        stateName = await locationDatasource.getStateName(
          stateId: widget.customer.stateId!,
          db: db,
          apiKey: apiKey,
        );
      }

      return CustomerDetails(
        customer: widget.customer,
        districtName: districtName,
        cityName: cityName,
        stateName: stateName,
      );
    } catch (e) {
      print('❌ Error loading customer details: $e');
      return CustomerDetails(customer: widget.customer);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<CustomerDetails>(
      future: _customerDetailsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(
              backgroundColor: AppTheme.primaryColor,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            body: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final details =
            snapshot.data ?? CustomerDetails(customer: widget.customer);
        return _buildDetailPage(details);
      },
    );
  }

  Widget _buildDetailPage(CustomerDetails details) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: CustomScrollView(
        slivers: [
          // Sticky Header with Avatar
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: AppTheme.primaryColor,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.white),
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          CustomerEditPage(customer: widget.customer),
                    ),
                  );
                  
                  // Refresh customer details if edit was successful
                  if (result == true && mounted) {
                    // Show success snackbar
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: const [
                            Icon(Icons.check_circle, color: Colors.white),
                            SizedBox(width: 8),
                            Text('Customer berhasil diperbarui'),
                          ],
                        ),
                        backgroundColor: AppTheme.successColor,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        margin: const EdgeInsets.all(16),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                    
                    // Refresh customer details
                    setState(() {
                      _customerDetailsFuture = _loadCustomerDetails();
                    });
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                onPressed: () {
                  _showMoreOptions(context);
                },
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryColor,
                      AppTheme.primaryColor.withValues(alpha: 0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      // Avatar
                      Hero(
                        tag: 'customer-${widget.customer.id}',
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(40),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              widget.customer.name.isNotEmpty
                                  ? widget.customer.name[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Customer Name
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          widget.customer.name,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Quick Actions
                  _buildQuickActions(),
                  const SizedBox(height: 20),

                  // Contact Information Section
                  _buildSectionHeader(
                      'Informasi Kontak', Icons.contacts_rounded),
                  const SizedBox(height: 12),
                  _buildContactSection(),
                  const SizedBox(height: 20),

                  // Address Information Section
                  _buildSectionHeader(
                      'Informasi Alamat', Icons.location_on_rounded),
                  const SizedBox(height: 12),
                  _buildAddressSection(details),
                  const SizedBox(height: 20),

                  // Additional Information
                  _buildSectionHeader('Informasi Tambahan', Icons.info_rounded),
                  const SizedBox(height: 12),
                  _buildAdditionalInfo(details),
                  const SizedBox(height: 20),

                  // Sales History Section
                  _buildSectionHeader(
                      'Riwayat Penjualan', Icons.shopping_bag_rounded),
                  const SizedBox(height: 12),
                  _buildSalesHistory(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build quick action buttons
  Widget _buildQuickActions() {
    final customer = widget.customer;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildActionButton(
              icon: Icons.phone_rounded,
              label: 'Telepon',
              color: Colors.green,
              onTap: () {
                _makePhoneCall(context, customer.phone);
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildActionButton(
              icon: Icons.message_rounded,
              label: 'WhatsApp',
              color: const Color(0xFF25D366),
              onTap: () {
                if (customer.phone != null && customer.phone!.isNotEmpty) {
                  _openWhatsApp(customer.phone!);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Nomor telepon tidak tersedia'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              },
            ),
          ),
          if (customer.email != null && customer.email!.isNotEmpty)
            const SizedBox(width: 12),
          if (customer.email != null && customer.email!.isNotEmpty)
            Expanded(
              child: _buildActionButton(
                icon: Icons.email_rounded,
                label: 'Email',
                color: Colors.blue,
                onTap: () {
                  _sendEmail(context, customer.email!);
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build section header
  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 20,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  /// Build contact information section
  Widget _buildContactSection() {
    final customer = widget.customer;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          if (customer.phone != null && customer.phone!.isNotEmpty)
            _buildDetailRow(
              icon: Icons.phone_rounded,
              iconColor: Colors.green,
              label: 'Telepon',
              value: customer.phone!,
              onCopy: () => _copyToClipboard(customer.phone!),
            ),
          if (customer.phone != null &&
              customer.phone!.isNotEmpty &&
              customer.email != null &&
              customer.email!.isNotEmpty)
            const Divider(height: 24),
          if (customer.email != null && customer.email!.isNotEmpty)
            _buildDetailRow(
              icon: Icons.email_rounded,
              iconColor: Colors.blue,
              label: 'Email',
              value: customer.email!,
              onCopy: () => _copyToClipboard(customer.email!),
            ),
          if ((customer.phone == null || customer.phone!.isEmpty) &&
              (customer.email == null || customer.email!.isEmpty))
            _buildEmptyState('Tidak ada informasi kontak'),
        ],
      ),
    );
  }

  /// Build address information section
  Widget _buildAddressSection(CustomerDetails details) {
    final customer = details.customer;
    
    // Combine street and street2
    String fullAddressLine = '';
    if (customer.street != null && customer.street!.isNotEmpty) {
      fullAddressLine = customer.street!;
    }
    if (customer.street2 != null && customer.street2!.isNotEmpty) {
      if (fullAddressLine.isNotEmpty) {
        fullAddressLine += ', ${customer.street2}';
      } else {
        fullAddressLine = customer.street2!;
      }
    }
    
    final hasAddress =
        fullAddressLine.isNotEmpty ||
            (customer.zip != null && customer.zip!.isNotEmpty) ||
            details.districtName != null ||
            details.cityName != null ||
            details.stateName != null ||
            customer.fullAddress.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: hasAddress
          ? Column(
              children: [
                if (fullAddressLine.isNotEmpty)
                  _buildDetailRow(
                    icon: Icons.home_rounded,
                    iconColor: Colors.orange,
                    label: 'Alamat',
                    value: fullAddressLine,
                    onCopy: () => _copyToClipboard(fullAddressLine),
                  ),
                if (fullAddressLine.isNotEmpty &&
                    ((customer.zip != null && customer.zip!.isNotEmpty) ||
                        details.districtName != null ||
                        details.cityName != null ||
                        details.stateName != null))
                  const Divider(height: 24),
                if (customer.zip != null && customer.zip!.isNotEmpty)
                  _buildDetailRow(
                    icon: Icons.markunread_mailbox_rounded,
                    iconColor: Colors.indigo,
                    label: 'Kode POS',
                    value: customer.zip!,
                    onCopy: () => _copyToClipboard(customer.zip!),
                  ),
                if ((customer.zip != null && customer.zip!.isNotEmpty) &&
                    details.districtName != null)
                  const Divider(height: 24),
                if (details.districtName != null)
                  _buildDetailRow(
                    icon: Icons.location_city_rounded,
                    iconColor: Colors.purple,
                    label: 'Kecamatan',
                    value: details.districtName!,
                  ),
                if ((details.districtName != null) && details.cityName != null)
                  const Divider(height: 24),
                if (details.cityName != null)
                  _buildDetailRow(
                    icon: Icons.location_city_rounded,
                    iconColor: Colors.blue,
                    label: 'Kota',
                    value: details.cityName!,
                  ),
                if ((details.cityName != null) && details.stateName != null)
                  const Divider(height: 24),
                if (details.stateName != null)
                  _buildDetailRow(
                    icon: Icons.map_rounded,
                    iconColor: Colors.teal,
                    label: 'Provinsi',
                    value: details.stateName!,
                  ),
              ],
            )
          : _buildEmptyState('Tidak ada informasi alamat'),
    );
  }

  /// Build additional information section
  Widget _buildAdditionalInfo(CustomerDetails details) {
    final customer = details.customer;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          _buildDetailRow(
            icon: Icons.fingerprint_rounded,
            iconColor: Colors.deepPurple,
            label: 'Customer ID',
            value: customer.id.toString(),
            onCopy: () => _copyToClipboard(customer.id.toString()),
          ),
        ],
      ),
    );
  }

  /// Build detail row with icon, label, and value
  Widget _buildDetailRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    VoidCallback? onCopy,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Icon
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 20,
            color: iconColor,
          ),
        ),
        const SizedBox(width: 14),

        // Label & Value
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  color: Colors.black87,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),

        // Copy button
        if (onCopy != null)
          IconButton(
            icon: Icon(
              Icons.copy_rounded,
              size: 18,
              color: Colors.grey[400],
            ),
            onPressed: onCopy,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
      ],
    );
  }

  /// Build empty state message
  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(Icons.info_outline, size: 48, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text(
              message,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build sales history section with accordion
  Widget _buildSalesHistory() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _loadSalesHistory(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError || snapshot.data == null) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: _buildEmptyState('Gagal memuat riwayat penjualan'),
          );
        }

        final result = snapshot.data!;
        if (result['Success'] != true) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: _buildEmptyState('Tidak ada riwayat penjualan'),
          );
        }

        final orders = result['Data']['items'] as List;
        if (orders.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: _buildEmptyState('Belum ada transaksi penjualan'),
          );
        }

        return _SalesHistoryAccordion(
          orders: orders,
          customerId: widget.customer.id,
          onRefreshNeeded: () {
            // Reload the customer details when order is updated
            setState(() {
              _customerDetailsFuture = _loadCustomerDetails();
            });
          },
        );
      },
    );
  }

  /// Load sales history for this customer
  Future<Map<String, dynamic>> _loadSalesHistory() async {
    try {
      final salesService = SalesService();
      final result = await salesService.getSaleOrders();

      if (result['Success'] == true) {
        final allOrders = result['Data']['items'] as List;

        // Filter orders for this customer
        final customerOrders = allOrders.where((order) {
          final partnerId = order['partner_id'];

          // Handle different formats of partner_id
          if (partnerId is int) {
            return partnerId == widget.customer.id;
          } else if (partnerId is List && partnerId.isNotEmpty) {
            return partnerId[0] == widget.customer.id;
          }

          return false;
        }).toList();

        // Sort by date (newest first)
        customerOrders.sort((a, b) {
          final dateA =
              DateTime.tryParse(a['date_order'] ?? '') ?? DateTime(1970);
          final dateB =
              DateTime.tryParse(b['date_order'] ?? '') ?? DateTime(1970);
          return dateB.compareTo(dateA);
        });

        return {
          'Success': true,
          'Data': {
            'items': customerOrders,
            'total': customerOrders.length,
          },
        };
      }

      return result;
    } catch (e) {
      print('❌ Error loading sales history: $e');
      return {
        'Success': false,
        'Message': 'Error: $e',
        'Data': {'items': [], 'total': 0},
      };
    }
  }

  /// Show more options bottom sheet
  void _showMoreOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading:
                  const Icon(Icons.share_rounded, color: AppTheme.primaryColor),
              title: const Text('Bagikan Customer'),
              onTap: () {
                Navigator.pop(context);
                _shareCustomer(context);
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.favorite_border_rounded, color: Colors.red),
              title: const Text('Tandai Favorit'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Fitur favorit akan segera hadir')),
                );
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.delete_outline_rounded, color: Colors.red),
              title: const Text('Hapus Customer'),
              onTap: () {
                Navigator.pop(context);
                _confirmDelete(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Copy to clipboard
  void _copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Text('Tersalin: $text'),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  /// Make phone call
  void _makePhoneCall(BuildContext context, String? phone) async {
    // Validate phone exists
    if (phone == null || phone.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Tidak ada nomor telepon untuk customer ini',
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
      print('📞 [PHONE CALL] Input phone: "$phone"');

      // Format phone number
      String formattedPhone = phone.trim();

      // Remove any non-digit characters except + at the beginning
      formattedPhone = formattedPhone.replaceAll(RegExp(r'[^\d+]'), '');

      print('📞 [PHONE CALL] Cleaned phone: "$formattedPhone"');

      // Handle Indonesian format
      if (formattedPhone.startsWith('0')) {
        formattedPhone = formattedPhone.substring(1);
      }
      if (!formattedPhone.startsWith('+')) {
        formattedPhone = '+62$formattedPhone';
      }

      print('📞 [PHONE CALL] Final formatted: "$formattedPhone"');

      final Uri phoneUri = Uri(scheme: 'tel', path: formattedPhone);

      print('📞 [PHONE CALL] URI: $phoneUri');

      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
        print('✅ [PHONE CALL] Successfully launched');
      } else {
        print('❌ [PHONE CALL] Cannot launch URL');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Tidak dapat membuka aplikasi telepon\nNomor: $formattedPhone'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      print('❌ [PHONE CALL] Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error membuka telepon: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// Send email
  void _sendEmail(BuildContext context, String email) async {
    try {
      final Uri emailUri = Uri(
        scheme: 'mailto',
        path: email,
        query: 'subject=Inquiry&body=',
      );

      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tidak dapat membuka aplikasi email'),
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

  /// Open WhatsApp chat
  void _openWhatsApp(String phone) async {
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nomor telepon tidak tersedia'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      // Format phone number for WhatsApp
      String formattedPhone = phone.trim().replaceAll(RegExp(r'[^\d+]'), '');
      
      // Handle Indonesian format
      if (formattedPhone.startsWith('0')) {
        formattedPhone = formattedPhone.substring(1);
      }
      if (!formattedPhone.startsWith('+')) {
        formattedPhone = '+62$formattedPhone';
      }

      // WhatsApp URI format: https://api.whatsapp.com/send?phone=PHONENUMBER
      final Uri whatsappUri = Uri.parse(
        'https://api.whatsapp.com/send?phone=$formattedPhone',
      );

      if (await canLaunchUrl(whatsappUri)) {
        await launchUrl(
          whatsappUri,
          mode: LaunchMode.externalApplication,
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Tidak dapat membuka WhatsApp\nNomor: $formattedPhone'),
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
            content: Text('Error membuka WhatsApp: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// Share customer
  void _shareCustomer(BuildContext context) async {
    final customer = widget.customer;

    // Format customer information
    final StringBuffer shareText = StringBuffer();
    shareText.writeln('📇 Customer Information');
    shareText.writeln('━━━━━━━━━━━━━━━━━━━━');
    shareText.writeln('👤 Name: ${customer.name}');
    // shareText.writeln('🆔 ID: ${customer.id}');

    if (customer.phone != null && customer.phone!.isNotEmpty) {
      shareText.writeln('📞 Phone: ${customer.phone}');
    }

    if (customer.email != null && customer.email!.isNotEmpty) {
      shareText.writeln('📧 Email: ${customer.email}');
    }

    if (customer.fullAddress.isNotEmpty) {
      shareText.writeln('📍 Address: ${customer.fullAddress}');
    }

    shareText.writeln('━━━━━━━━━━━━━━━━━━━━');
    shareText.writeln('\nShared from Mobile App Odoo');

    // Copy to clipboard as alternative to share
    await Clipboard.setData(ClipboardData(text: shareText.toString()));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                    'Informasi customer tersalin ke clipboard!\nAnda bisa paste di aplikasi lain.'),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: 'OK',
            textColor: Colors.white,
            onPressed: () {},
          ),
        ),
      );
    }
  }

  /// Confirm delete
  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Customer'),
        content: Text('Yakin ingin menghapus ${widget.customer.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}

/// Sales History Accordion Widget
class _SalesHistoryAccordion extends StatefulWidget {
  final List<dynamic> orders;
  final int customerId;
  final VoidCallback onRefreshNeeded;

  const _SalesHistoryAccordion({
    required this.orders,
    required this.customerId,
    required this.onRefreshNeeded,
  });

  @override
  State<_SalesHistoryAccordion> createState() => _SalesHistoryAccordionState();
}

class _SalesHistoryAccordionState extends State<_SalesHistoryAccordion> {
  final Set<int> _expandedIndices = {};
  final _currencyFormat =
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  String _getStateLabel(String state) {
    switch (state.toLowerCase()) {
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
        return state;
    }
  }

  Color _getStateColor(String state) {
    switch (state.toLowerCase()) {
      case 'draft':
      case 'sent':
        return const Color(0xFFFFA726); // Orange
      case 'sale':
      case 'done':
        return const Color(0xFF66BB6A); // Green
      case 'cancel':
        return const Color(0xFFEF5350); // Red
      default:
        return const Color(0xFF757575); // Grey
    }
  }

  @override
  Widget build(BuildContext context) {
    // Calculate totals
    final totalOrders = widget.orders.length;
    final totalAmount = widget.orders.fold<double>(
      0.0,
      (sum, order) =>
          sum + ((order['amount_total'] as num?)?.toDouble() ?? 0.0),
    );

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          // Summary Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Transaksi',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$totalOrders pesanan',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  height: 40,
                  width: 1,
                  color: Colors.grey[300],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Nilai',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _currencyFormat.format(totalAmount),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.successColor,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Orders List
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: widget.orders.length,
            separatorBuilder: (context, index) => Divider(
              height: 1,
              color: Colors.grey[200],
            ),
            itemBuilder: (context, index) {
              final order = widget.orders[index];
              final isExpanded = _expandedIndices.contains(index);
              final orderLines = (order['order_line'] as List?) ?? [];
              final state = order['state'] as String? ?? 'draft';
              final stateLabel = _getStateLabel(state);
              final stateColor = _getStateColor(state);

              return Column(
                children: [
                  InkWell(
                    onTap: () {
                      setState(() {
                        if (isExpanded) {
                          _expandedIndices.remove(index);
                        } else {
                          _expandedIndices.add(index);
                        }
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header Row
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      order['name'] as String,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _formatDate(
                                          order['date_order'] as String),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                isExpanded
                                    ? Icons.keyboard_arrow_up_rounded
                                    : Icons.keyboard_arrow_down_rounded,
                                color: Colors.grey[400],
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Amount and Status Row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _currencyFormat.format(
                                  (order['amount_total'] as num?)?.toDouble() ??
                                      0.0,
                                ),
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.successColor,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: stateColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  stateLabel,
                                  style: TextStyle(
                                    color: stateColor,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          // Expanded Content
                          if (isExpanded) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Order Items',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppTheme.brandBlue
                                              .withValues(alpha: 0.1),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          '${orderLines.length} item(s)',
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: AppTheme.brandBlue,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  ...orderLines.map((line) {
                                    final productName =
                                        line['product_name'] as String? ??
                                            'Unknown';
                                    final qty =
                                        (line['product_uom_qty'] as num?)
                                                ?.toDouble() ??
                                            0.0;
                                    final price = (line['price_unit'] as num?)
                                            ?.toDouble() ??
                                        0.0;
                                    final subtotal = qty * price;

                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 6,
                                            height: 6,
                                            decoration: BoxDecoration(
                                              color: AppTheme.brandBlue,
                                              borderRadius:
                                                  BorderRadius.circular(3),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  productName,
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  'Qty: ${qty.toInt()} × ${_currencyFormat.format(price)}',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Text(
                                            _currencyFormat.format(subtotal),
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.black87,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                                  const SizedBox(height: 8),
                                  ElevatedButton.icon(
                                    onPressed: () async {
                                      try {
                                        final salesOrder =
                                            SalesOrder.fromJson(order);
                                        final result =
                                            await Navigator.of(context)
                                                .push<bool>(
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                SalesOrderDetailPage(
                                              order: salesOrder,
                                            ),
                                          ),
                                        );

                                        // Refresh if order was updated
                                        if (result == true && mounted) {
                                          widget.onRefreshNeeded();
                                        }
                                      } catch (e) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text('Error: $e'),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    },
                                    icon: const Icon(Icons.visibility_rounded,
                                        size: 16),
                                    label: const Text('Lihat Detail'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.primaryColor,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8,
                                      ),
                                      textStyle: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
