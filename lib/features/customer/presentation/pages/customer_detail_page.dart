import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../config/theme.dart';
import '../../../../services/config_service.dart';
import '../../../../services/secure_storage_service.dart';
import '../../../location/data/datasources/location_remote_datasource.dart';
import '../../../sales_order/domain/entities/sales_order.dart';
import '../../../sales_order/presentation/pages/sales_order_detail_page.dart';
import '../../../sales_order/presentation/providers/sales_order_provider.dart';
import '../../domain/entities/customer.dart';
import '../providers/customer_provider.dart';
import 'customer_edit_page.dart';
import 'customer_transaction_history_page.dart';

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

  /// Parse customer name to remove phone number in parentheses
  /// Example: "John Doe (081234567890)" -> "John Doe"
  String _parseCustomerName(String name) {
    // Remove phone number in parentheses: (phone) or (phone number)
    // Pattern: (digits and optional spaces/dashes)
    final cleanName =
        name.replaceAll(RegExp(r'\s*\([0-9\s\-+]+\)\s*'), '').trim();
    return cleanName.isNotEmpty ? cleanName : name;
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

      // Get fresh customer data from provider
      final provider = context.read<CustomerProvider>();
      final freshCustomer = provider.getCustomerById(widget.customer.id);
      final customerToUse = freshCustomer ?? widget.customer;

      final locationDatasource = LocationRemoteDataSource();

      // Load location names
      String? districtName;
      String? cityName;
      String? stateName;

      if (customerToUse.districtId != null) {
        districtName = await locationDatasource.getDistrictName(
          districtId: customerToUse.districtId!,
          db: db,
          apiKey: apiKey,
        );
      }

      if (customerToUse.cityId != null) {
        cityName = await locationDatasource.getCityName(
          cityId: customerToUse.cityId!,
          db: db,
          apiKey: apiKey,
        );
      }

      if (customerToUse.stateId != null) {
        stateName = await locationDatasource.getStateName(
          stateId: customerToUse.stateId!,
          db: db,
          apiKey: apiKey,
        );
      }

      return CustomerDetails(
        customer: customerToUse,
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
    final theme = Theme.of(context);

    return FutureBuilder<CustomerDetails>(
      future: _customerDetailsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(
              backgroundColor: theme.appBarTheme.backgroundColor,
              leading: IconButton(
                icon: Icon(Icons.arrow_back,
                    color: theme.appBarTheme.iconTheme?.color),
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
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // Sticky Header with Avatar
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: theme.appBarTheme.backgroundColor,
            leading: IconButton(
              icon: Icon(Icons.arrow_back,
                  color: theme.appBarTheme.iconTheme?.color),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon:
                    Icon(Icons.edit, color: theme.appBarTheme.iconTheme?.color),
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          CustomerEditPage(customer: widget.customer),
                    ),
                  );

                  // Reload customer details if edit was successful
                  if (result == true && mounted) {
                    setState(() {
                      _customerDetailsFuture = _loadCustomerDetails();
                    });
                  }
                },
              ),
              IconButton(
                icon: Icon(Icons.more_vert,
                    color: theme.appBarTheme.iconTheme?.color),
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
                              _parseCustomerName(widget.customer.name)
                                      .isNotEmpty
                                  ? _parseCustomerName(widget.customer.name)[0]
                                      .toUpperCase()
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
                          _parseCustomerName(widget.customer.name),
                          style: const TextStyle(
                            fontSize: 18,
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
                  // Contact Information Section (with integrated action buttons)
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

  /// Build section header
  Widget _buildSectionHeader(String title, IconData icon) {
    final theme = Theme.of(context);

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
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: theme.textTheme.bodyLarge?.color,
          ),
        ),
      ],
    );
  }

  /// Build contact information section with integrated action buttons
  Widget _buildContactSection() {
    final theme = Theme.of(context);
    final customer = widget.customer;
    final hasPhone = customer.phone != null && customer.phone!.isNotEmpty;
    final hasEmail = customer.email != null && customer.email!.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.brightness == Brightness.dark
              ? Colors.grey[700]!
              : Colors.grey[200]!,
        ),
      ),
      child: Column(
        children: [
          // Phone Row with Action Buttons below
          if (hasPhone)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Phone Info
                _buildDetailRow(
                  icon: Icons.phone_rounded,
                  iconColor: const Color(0xFF4CAF50),
                  label: 'Telepon',
                  value: customer.phone!,
                  onCopy: () => _copyToClipboard(customer.phone!),
                ),
                const SizedBox(height: 12),
                // Action Buttons (below phone number)
                Row(
                  children: [
                    const SizedBox(width: 44), // Align with text after icon
                    // Call Button
                    _buildSmallIconButton(
                      icon: Icons.phone_rounded,
                      color: const Color(0xFF4CAF50),
                      tooltip: 'Telepon',
                      onTap: () => _makePhoneCall(context, customer.phone),
                    ),
                    const SizedBox(width: 10),
                    // WhatsApp Button
                    _buildSmallIconButton(
                      icon: Icons.phone,
                      color: const Color(0xFF25D366),
                      tooltip: 'WhatsApp',
                      onTap: () => _openWhatsApp(context, customer.phone!),
                    ),
                  ],
                ),
              ],
            ),
          if (hasPhone && hasEmail) const Divider(height: 24),

          // Email Row with Action Button below
          if (hasEmail)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Email Info
                _buildDetailRow(
                  icon: Icons.email_rounded,
                  iconColor: const Color(0xFF2196F3),
                  label: 'Email',
                  value: customer.email!,
                  onCopy: () => _copyToClipboard(customer.email!),
                ),
                const SizedBox(height: 12),
                // Action Button (below email)
                Row(
                  children: [
                    const SizedBox(width: 44), // Align with text after icon
                    // Send Email Button
                    _buildSmallIconButton(
                      icon: Icons.email_rounded,
                      color: const Color(0xFF2196F3),
                      tooltip: 'Kirim Email',
                      onTap: () => _sendEmail(context, customer.email!),
                    ),
                  ],
                ),
              ],
            ),

          // Empty State
          if (!hasPhone && !hasEmail)
            _buildEmptyState('Tidak ada informasi kontak'),
        ],
      ),
    );
  }

  /// Build small icon button for inline actions
  Widget _buildSmallIconButton({
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.25),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }

  /// Build address information section
  Widget _buildAddressSection(CustomerDetails details) {
    final theme = Theme.of(context);
    final customer = details.customer;
    final hasAddress =
        (customer.street != null && customer.street!.isNotEmpty) ||
            (customer.street2 != null && customer.street2!.isNotEmpty) ||
            (customer.zip != null && customer.zip!.isNotEmpty) ||
            details.districtName != null ||
            details.cityName != null ||
            details.stateName != null ||
            customer.fullAddress.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.brightness == Brightness.dark
              ? Colors.grey[700]!
              : Colors.grey[200]!,
        ),
      ),
      child: hasAddress
          ? Column(
              children: [
                if (customer.fullAddress.isNotEmpty)
                  _buildDetailRow(
                    icon: Icons.location_on_rounded,
                    iconColor: Colors.red,
                    label: 'Alamat Lengkap',
                    value: customer.fullAddress,
                    onCopy: () => _copyToClipboard(customer.fullAddress),
                  ),
                if (customer.fullAddress.isNotEmpty &&
                    ((customer.street != null && customer.street!.isNotEmpty) ||
                        (customer.street2 != null &&
                            customer.street2!.isNotEmpty) ||
                        (customer.zip != null && customer.zip!.isNotEmpty) ||
                        details.districtName != null ||
                        details.cityName != null ||
                        details.stateName != null))
                  const Divider(height: 24),
                if (customer.street != null && customer.street!.isNotEmpty)
                  _buildDetailRow(
                    icon: Icons.home_rounded,
                    iconColor: Colors.orange,
                    label: 'Alamat',
                    value: customer.street!,
                    onCopy: () => _copyToClipboard(customer.street!),
                  ),
                if (customer.street != null &&
                    customer.street!.isNotEmpty &&
                    customer.street2 != null &&
                    customer.street2!.isNotEmpty)
                  const Divider(height: 24),
                if (customer.street2 != null && customer.street2!.isNotEmpty)
                  _buildDetailRow(
                    icon: Icons.home_work_rounded,
                    iconColor: Colors.deepOrange,
                    label: 'Alamat Lanjutan',
                    value: customer.street2!,
                    onCopy: () => _copyToClipboard(customer.street2!),
                  ),
                if ((customer.street2 != null &&
                        customer.street2!.isNotEmpty) &&
                    (details.districtName != null ||
                        details.cityName != null ||
                        details.stateName != null))
                  const Divider(height: 24),
                if (details.districtName != null)
                  _buildDetailRow(
                    icon: Icons.location_city_rounded,
                    iconColor: Colors.purple,
                    label: 'Kelurahan',
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
                // Always show Kode POS (even if empty)
                const Divider(height: 24),
                _buildDetailRow(
                  icon: Icons.markunread_mailbox_rounded,
                  iconColor: Colors.indigo,
                  label: 'Kode POS',
                  value: (customer.zip != null && customer.zip!.isNotEmpty)
                      ? customer.zip!
                      : '-',
                  onCopy: (customer.zip != null && customer.zip!.isNotEmpty)
                      ? () => _copyToClipboard(customer.zip!)
                      : null,
                ),
              ],
            )
          : _buildEmptyState('Tidak ada informasi alamat'),
    );
  }

  /// Build additional information section
  Widget _buildAdditionalInfo(CustomerDetails details) {
    final theme = Theme.of(context);
    final customer = details.customer;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.brightness == Brightness.dark
              ? Colors.grey[700]!
              : Colors.grey[200]!,
        ),
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
    final theme = Theme.of(context);

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
                  color: theme.textTheme.bodySmall?.color,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  color: theme.textTheme.bodyLarge?.color,
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
              color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5),
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
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(
              Icons.info_outline,
              size: 48,
              color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: TextStyle(
                fontSize: 14,
                color: theme.textTheme.bodySmall?.color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build sales history section with summary (show only 5 recent)
  Widget _buildSalesHistory() {
    final theme = Theme.of(context);

    return FutureBuilder<Map<String, dynamic>>(
      future: _loadSalesHistory(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.cardTheme.color,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.brightness == Brightness.dark
                    ? Colors.grey[700]!
                    : Colors.grey[200]!,
              ),
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
              color: theme.cardTheme.color,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.brightness == Brightness.dark
                    ? Colors.grey[700]!
                    : Colors.grey[200]!,
              ),
            ),
            child: _buildEmptyState('Gagal memuat riwayat penjualan'),
          );
        }

        final result = snapshot.data!;
        if (result['Success'] != true) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.cardTheme.color,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.brightness == Brightness.dark
                    ? Colors.grey[700]!
                    : Colors.grey[200]!,
              ),
            ),
            child: _buildEmptyState('Tidak ada riwayat penjualan'),
          );
        }

        final orders = result['Data']['items'] as List;
        if (orders.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.cardTheme.color,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.brightness == Brightness.dark
                    ? Colors.grey[700]!
                    : Colors.grey[200]!,
              ),
            ),
            child: _buildEmptyState('Belum ada transaksi penjualan'),
          );
        }

        // Convert to SalesOrder entities
        final allTransactions =
            orders.map((json) => SalesOrder.fromJson(json)).toList();

        // Take only 5 most recent
        final recentTransactions = allTransactions.take(5).toList();
        final hasMore = allTransactions.length > 5;

        return _buildTransactionHistorySummary(
          allTransactions: allTransactions,
          recentTransactions: recentTransactions,
          hasMore: hasMore,
        );
      },
    );
  }

  /// Load sales history for this customer
  Future<Map<String, dynamic>> _loadSalesHistory() async {
    try {
      print(
          '🔍 [SALES_HISTORY] Loading for customer ID: ${widget.customer.id}');

      // Use the SalesOrderProvider to reuse cached data
      final provider = Provider.of<SalesOrderProvider>(context, listen: false);

      // If provider already has orders, use them
      if (provider.orders.isNotEmpty) {
        print(
            '📦 [SALES_HISTORY] Using cached orders from Provider: ${provider.orders.length}');

        final allOrders = provider.orders;

        // Filter orders for this customer
        final customerOrders = allOrders.where((order) {
          // SalesOrder entity has customerId getter that extracts int from partnerId
          final orderCustomerId = order.customerId;
          final match = orderCustomerId == widget.customer.id;
          if (match) {
            print(
                '   ✅ Match: Order ${order.name} - customerId: $orderCustomerId == ${widget.customer.id}');
          }
          return match;
        }).toList();

        print(
            '🔍 [SALES_HISTORY] Filtered orders for customer ${widget.customer.id}: ${customerOrders.length}');

        // Sort by date (newest first)
        customerOrders.sort((a, b) => b.dateOrder.compareTo(a.dateOrder));

        // Convert back to Map format for compatibility
        final ordersJson =
            customerOrders.map((order) => order.toJson()).toList();

        return {
          'Success': true,
          'Data': {
            'items': ordersJson,
            'total': ordersJson.length,
          },
        };
      }

      // If provider is empty, fetch fresh data
      print('🔄 [SALES_HISTORY] Provider empty, fetching fresh data...');
      await provider.fetchSalesOrders();

      // Now use the fetched data
      if (provider.orders.isNotEmpty) {
        final customerOrders = provider.orders.where((order) {
          return order.customerId == widget.customer.id;
        }).toList();

        customerOrders.sort((a, b) => b.dateOrder.compareTo(a.dateOrder));
        final ordersJson =
            customerOrders.map((order) => order.toJson()).toList();

        return {
          'Success': true,
          'Data': {
            'items': ordersJson,
            'total': ordersJson.length,
          },
        };
      }

      // If still empty, no orders available
      print('❌ [SALES_HISTORY] No orders available after fetch');
      return {
        'Success': true,
        'Data': {'items': [], 'total': 0},
      };
    } catch (e) {
      print('❌ [SALES_HISTORY] Error loading sales history: $e');
      return {
        'Success': false,
        'Message': 'Error: $e',
        'Data': {'items': [], 'total': 0},
      };
    }
  }

  /// Build transaction history summary widget
  Widget _buildTransactionHistorySummary({
    required List<SalesOrder> allTransactions,
    required List<SalesOrder> recentTransactions,
    required bool hasMore,
  }) {
    final theme = Theme.of(context);
    final currencyFormat =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    // Calculate stats
    final totalRevenue = allTransactions.fold(
      0.0,
      (sum, tx) =>
          sum + (tx.state.toLowerCase() != 'cancel' ? tx.amountTotal : 0.0),
    );

    return Container(
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.brightness == Brightness.dark
              ? Colors.grey[700]!
              : Colors.grey[200]!,
        ),
      ),
      child: Column(
        children: [
          // Header with Stats
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
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Text(
                      'Total Transaksi',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.textTheme.bodySmall?.color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${allTransactions.length}x',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: theme.dividerColor,
                ),
                Column(
                  children: [
                    Text(
                      'Total Belanja',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.textTheme.bodySmall?.color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      currencyFormat.format(totalRevenue),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Recent Transactions (Max 5)
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(12),
            itemCount: recentTransactions.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final tx = recentTransactions[index];
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                leading: CircleAvatar(
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
                title: Text(
                  tx.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                ),
                subtitle: Row(
                  children: [
                    Text(
                      tx.dateOrderFormatted,
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.textTheme.bodySmall?.color,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Color(tx.stateColor).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        tx.stateLabel,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Color(tx.stateColor),
                        ),
                      ),
                    ),
                  ],
                ),
                trailing: Text(
                  currencyFormat.format(tx.amountTotal),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryColor,
                  ),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SalesOrderDetailPage(order: tx),
                    ),
                  );
                },
              );
            },
          ),

          // "View All" Button (if more than 5)
          if (hasMore)
            Padding(
              padding: const EdgeInsets.all(12),
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CustomerTransactionHistoryPage(
                        customerId: widget.customer.id,
                        customerName: widget.customer.name,
                        transactions: allTransactions,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.history, size: 16),
                label: Text('Lihat Semua (${allTransactions.length})'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  textStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Show more options bottom sheet
  void _showMoreOptions(BuildContext context) {
    final theme = Theme.of(context);

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
                color: theme.dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // const SizedBox(height: 20),
            // ListTile(
            //   leading:
            //       const Icon(Icons.share_rounded, color: AppTheme.primaryColor),
            //   title: const Text('Bagikan Customer'),
            //   onTap: () {
            //     Navigator.pop(context);
            //     _shareCustomer(context);
            //   },
            // ),
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
            // ListTile(
            //   leading:
            //       const Icon(Icons.delete_outline_rounded, color: Colors.red),
            //   title: const Text('Hapus Customer'),
            //   onTap: () {
            //     Navigator.pop(context);
            //     _confirmDelete(context);
            //   },
            // ),
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

  /// Open WhatsApp
  void _openWhatsApp(BuildContext context, String phone) async {
    // Validate phone exists
    if (phone.isEmpty) {
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
      print('💬 [WHATSAPP] Input phone: "$phone"');

      // Format phone number for WhatsApp
      String formattedPhone = phone.trim();

      // Remove any non-digit characters except + at the beginning
      formattedPhone = formattedPhone.replaceAll(RegExp(r'[^\d+]'), '');

      print('💬 [WHATSAPP] Cleaned phone: "$formattedPhone"');

      // Handle Indonesian format
      if (formattedPhone.startsWith('0')) {
        formattedPhone = '62${formattedPhone.substring(1)}';
      } else if (formattedPhone.startsWith('+')) {
        formattedPhone = formattedPhone.substring(1);
      } else if (!formattedPhone.startsWith('62')) {
        formattedPhone = '62$formattedPhone';
      }

      print('💬 [WHATSAPP] Final formatted: "$formattedPhone"');

      // WhatsApp URL format: https://wa.me/6281234567890
      final Uri whatsappUri = Uri.parse('https://wa.me/$formattedPhone');

      print('💬 [WHATSAPP] URI: $whatsappUri');

      if (await canLaunchUrl(whatsappUri)) {
        await launchUrl(
          whatsappUri,
          mode: LaunchMode.externalApplication,
        );
        print('✅ [WHATSAPP] Successfully launched');
      } else {
        print('❌ [WHATSAPP] Cannot launch URL');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Tidak dapat membuka WhatsApp\nPastikan WhatsApp terinstall\nNomor: +$formattedPhone'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      print('❌ [WHATSAPP] Error: $e');
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
    final theme = Theme.of(context);

    // Calculate totals
    final totalOrders = widget.orders.length;
    final totalAmount = widget.orders.fold<double>(
      0.0,
      (sum, order) =>
          sum + ((order['amount_total'] as num?)?.toDouble() ?? 0.0),
    );

    return Container(
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.brightness == Brightness.dark
              ? Colors.grey[700]!
              : Colors.grey[200]!,
        ),
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
                          color: theme.textTheme.bodySmall?.color,
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
                  color: theme.dividerColor,
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
                          color: theme.textTheme.bodySmall?.color,
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
              color: theme.dividerColor,
            ),
            itemBuilder: (context, index) {
              final order = widget.orders[index];
              final isExpanded = _expandedIndices.contains(index);
              final orderLines = (order['order_lines'] as List?) ?? [];
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
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: theme.textTheme.bodyLarge?.color,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _formatDate(
                                          order['date_order'] as String),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: theme.textTheme.bodySmall?.color,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                isExpanded
                                    ? Icons.keyboard_arrow_up_rounded
                                    : Icons.keyboard_arrow_down_rounded,
                                color: theme.iconTheme.color
                                    ?.withValues(alpha: 0.5),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

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
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: theme.brightness == Brightness.dark
                                    ? Colors.grey[850]
                                    : Colors.grey[50],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Order Items',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color:
                                              theme.textTheme.bodyMedium?.color,
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
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                    color: theme.textTheme
                                                        .bodyMedium?.color,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  'Qty: ${qty.toInt()} × ${_currencyFormat.format(price)}',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    color: theme.textTheme
                                                        .bodySmall?.color,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Text(
                                            _currencyFormat.format(subtotal),
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: theme
                                                  .textTheme.bodyLarge?.color,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                                  const SizedBox(height: 5),
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
                                        size: 14),
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
