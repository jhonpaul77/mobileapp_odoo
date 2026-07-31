import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:nextpsa/config/theme.dart';
import 'package:nextpsa/features/customer/presentation/pages/customer_list_page.dart';
import 'package:nextpsa/features/product/presentation/pages/product_list_page.dart';
import 'package:nextpsa/features/sales_order/presentation/pages/sales_order_detail_page.dart';
import 'package:nextpsa/features/sales_order/presentation/pages/sales_order_list_page.dart';
import 'package:nextpsa/features/sales_order/presentation/providers/sales_order_provider.dart';
import 'package:nextpsa/pages/sales/notification/sales_notification_page.dart';
import 'package:nextpsa/pages/sales/transaction/transaction_create_page.dart';
import 'package:nextpsa/services/status_bar_service.dart';
import 'package:nextpsa/widgets/common/app_header.dart';
import 'package:nextpsa/widgets/common/section_header.dart';
import 'package:provider/provider.dart';

class PenjualanPage extends StatefulWidget {
  const PenjualanPage({super.key});

  @override
  State<PenjualanPage> createState() => _PenjualanPageState();
}

class _PenjualanPageState extends State<PenjualanPage> {
  final _currencyFormat =
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      StatusBarService.setDarkStatusBar();
      // Fetch sales orders for recent transaction
      context.read<SalesOrderProvider>().fetchSalesOrders();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(0),
        child: AppBar(
          elevation: 0,
          backgroundColor: theme.scaffoldBackgroundColor,
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: theme.brightness == Brightness.dark
                ? Brightness.light
                : Brightness.dark,
          ),
        ),
      ),
      body: _buildPenjualanPage(),
    );
  }

  Widget _buildPenjualanPage() {
    final theme = Theme.of(context);

    return CustomScrollView(
      slivers: [
        // STICKY HEADER
        SliverAppBar(
          floating: false,
          pinned: true,
          snap: false,
          elevation: 0,
          backgroundColor: theme.scaffoldBackgroundColor,
          collapsedHeight: 100,
          expandedHeight: 100,
          toolbarHeight: 100,
          automaticallyImplyLeading: false,
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: theme.brightness == Brightness.dark
                ? Brightness.light
                : Brightness.dark,
          ),
          flexibleSpace: FlexibleSpaceBar(
            collapseMode: CollapseMode.none,
            background: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: AppHeader(
                title: "Penjualan",
                subtitle: "Kelola transaksi, customer & produk",
                showDate: true,
                onNotificationTap: () {
                  // Navigate to notification page
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SalesNotificationPage(),
                    ),
                  );
                },
              ),
            ),
          ),
        ),

        // SCROLLABLE CONTENT
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // QUICK ACTIONS
                _buildQuickActionsCard(),
                const SizedBox(height: 28),

                // MENU PENJUALAN
                SectionHeader(
                  title: "Menu Penjualan",
                  icon: Icons.apps_rounded,
                  onActionTap: () {},
                ),
                const SizedBox(height: 16),
                _buildMenuCards(),
                const SizedBox(height: 32),

                // TRANSAKSI TERBARU
                SectionHeader(
                  title: "Transaksi Terbaru",
                  icon: Icons.history_rounded,
                  onActionTap: () {
                    // Navigate to sales order list page
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SalesOrderListPage(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 14),
                _buildRecentTransactions(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionsCard() {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(16),
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
            blurRadius: 12,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bolt_rounded, color: AppTheme.primaryColor, size: 20),
              const SizedBox(width: 8),
              Text(
                "Quick Actions",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: theme.textTheme.bodyLarge?.color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: _buildQuickActionButton(
                  "Transaksi Baru",
                  Icons.add_shopping_cart_rounded,
                  AppTheme.successColor,
                  () async {
                    // Navigate to TransactionCreatePage (Production with Odoo API)
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const TransactionCreatePage(),
                      ),
                    );

                    // Refresh sales orders if a new order was created
                    if (result == true && mounted) {
                      context.read<SalesOrderProvider>().fetchSalesOrders();
                    }
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildQuickActionButton(
                  "Daftar Transaksi",
                  Icons.list_rounded,
                  AppTheme.primaryColor,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SalesOrderListPage(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
          // Subtle shadow for depth
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.15),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                // Ensure text is always readable
                shadows: theme.brightness == Brightness.dark
                    ? [
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 4,
                        ),
                      ]
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCards() {
    final menus = [
      {
        "title": "Transaksi Penjualan",
        "subtitle": "Riwayat & buat transaksi",
        "icon": Icons.point_of_sale_rounded,
        "gradient": [const Color(0xFF667EEA), const Color(0xFF764BA2)],
        "route": "transactions",
      },
      {
        "title": "Customer",
        "subtitle": "Kelola data pelanggan",
        "icon": Icons.people_rounded,
        "gradient": [const Color(0xFFF093FB), const Color(0xFFF5576C)],
        "route": "customers",
      },
      {
        "title": "Produk",
        "subtitle": "Kelola produk & stok",
        "icon": Icons.inventory_2_rounded,
        "gradient": [const Color(0xFF4FACFE), const Color(0xFF00F2FE)],
        "route": "products",
      },
    ];

    return Column(
      children: menus.asMap().entries.map((entry) {
        return Padding(
          padding:
              EdgeInsets.only(bottom: entry.key == menus.length - 1 ? 0 : 12),
          child: _buildMenuCard(entry.value),
        );
      }).toList(),
    );
  }

  Widget _buildMenuCard(Map<String, dynamic> menu) {
    return GestureDetector(
      onTap: () {
        if (menu["route"] == "transactions") {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const SalesOrderListPage(),
            ),
          );
        } else if (menu["route"] == "customers") {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CustomerListPage(),
            ),
          );
        } else if (menu["route"] == "products") {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ProductListPage(),
            ),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: menu["gradient"] as List<Color>,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color:
                  (menu["gradient"] as List<Color>)[0].withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                menu["icon"] as IconData,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    menu["title"],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    menu["subtitle"],
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_rounded,
              color: Colors.white.withValues(alpha: 0.7),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentTransactions() {
    final theme = Theme.of(context);

    return Consumer<SalesOrderProvider>(
      builder: (context, provider, child) {
        // Loading state
        if (provider.isLoading && provider.orders.isEmpty) {
          return Container(
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
            ),
            child: Center(
              child: Column(
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 12),
                  Text(
                    "Memuat transaksi...",
                    style: TextStyle(
                      color: theme.textTheme.bodyMedium?.color,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // Error state
        if (provider.hasError) {
          return Container(
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
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: Colors.red[300],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Gagal memuat transaksi",
                    style: TextStyle(
                      color: theme.textTheme.bodyMedium?.color,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // Empty state
        if (provider.isEmpty) {
          return Container(
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
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.inbox_rounded,
                    size: 48,
                    color: theme.brightness == Brightness.dark
                        ? Colors.grey[600]
                        : Colors.grey[300],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Belum ada transaksi",
                    style: TextStyle(
                      color: theme.textTheme.bodyMedium?.color,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Mulai dengan membuat transaksi penjualan baru",
                    style: TextStyle(
                      color: theme.textTheme.bodySmall?.color,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // Show latest transaction (first one)
        final latestOrder = provider.orders.first;

        return Column(
          children: [
            // Transaction Card
            GestureDetector(
              onTap: () async {
                final result = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        SalesOrderDetailPage(order: latestOrder),
                  ),
                );

                // Refresh if order was updated
                if (result == true && mounted) {
                  context.read<SalesOrderProvider>().fetchSalesOrders();
                }
              },
              child: Container(
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
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header: SO Number + Status Badge
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              latestOrder.name,
                              style: TextStyle(
                                fontSize: 16,
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
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Color(latestOrder.stateColor)
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: Color(latestOrder.stateColor)
                                    .withValues(alpha: 0.3),
                              ),
                            ),
                            child: Text(
                              latestOrder.stateLabel,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Color(latestOrder.stateColor),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const Divider(height: 20, thickness: 1),

                      // Customer Info
                      _buildInfoRow(
                        icon: Icons.person_outline,
                        iconColor: AppTheme.brandBlue,
                        iconBgColor: AppTheme.brandBlue.withValues(alpha: 0.1),
                        label: 'Customer',
                        value: latestOrder.customerName,
                      ),

                      // Date Order
                      _buildInfoRow(
                        icon: Icons.calendar_today_outlined,
                        iconColor: Colors.orange,
                        iconBgColor: Colors.orange.withValues(alpha: 0.1),
                        label: 'Tanggal',
                        value: latestOrder.dateOrderFormatted,
                      ),

                      // Total Amount
                      _buildInfoRow(
                        icon: Icons.attach_money,
                        iconColor: Colors.green,
                        iconBgColor: Colors.green.withValues(alpha: 0.1),
                        label: 'Total',
                        value: _currencyFormat.format(latestOrder.amountTotal),
                        valueStyle: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // View All Button
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SalesOrderListPage(),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTheme.primaryColor.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.list_rounded,
                      color: AppTheme.primaryColor,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Lihat Semua Transaksi',
                      style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Build info row with icon, label, and value
  Widget _buildInfoRow({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String label,
    required String value,
    TextStyle? valueStyle,
  }) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon Container
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 16,
              color: iconColor,
            ),
          ),
          const SizedBox(width: 12),

          // Label & Value
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.textTheme.bodySmall?.color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: valueStyle ??
                      TextStyle(
                        fontSize: 13,
                        color: theme.textTheme.bodyMedium?.color,
                        fontWeight: FontWeight.w500,
                        height: 1.3,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

