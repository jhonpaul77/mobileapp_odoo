import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pintarx/config/theme.dart';
import 'package:pintarx/widgets/common/app_header.dart';
import 'package:pintarx/widgets/common/section_header.dart';
import 'package:pintarx/services/status_bar_service.dart';
import 'package:pintarx/pages/home/home_page.dart';
import 'package:pintarx/pages/sales/customer/customer_list_page.dart';
import 'package:pintarx/pages/sales/transaction/sales_page.dart';
import 'package:pintarx/pages/sales/transaction/transaction_list_page.dart';


class PenjualanPage extends StatefulWidget {
  const PenjualanPage({super.key});

  @override
  State<PenjualanPage> createState() => _PenjualanPageState();
}

class _PenjualanPageState extends State<PenjualanPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      StatusBarService.setDarkStatusBar();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(0),
        child: AppBar(
          elevation: 0,
          backgroundColor: AppTheme.backgroundColor,
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark,
          ),
        ),
      ),
      body: _buildPenjualanPage(),
    );
  }

  Widget _buildPenjualanPage() {
    return CustomScrollView(
      slivers: [
        // STICKY HEADER
        SliverAppBar(
          floating: false,
          pinned: true,
          snap: false,
          elevation: 0,
          backgroundColor: AppTheme.backgroundColor,
          collapsedHeight: 100,
          expandedHeight: 100,
          toolbarHeight: 100,
          automaticallyImplyLeading: false,
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
          ),
          flexibleSpace: FlexibleSpaceBar(
            collapseMode: CollapseMode.none,
            background: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: AppHeader(
                title: "Penjualan",
                subtitle: "Kelola transaksi, customer & produk",
                showDate: true,
                onNotificationTap: null,
              ),
            ),
          ),
        ),

        // SCROLLABLE CONTENT
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 28, 16, 100),
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
                  onActionTap: () {},
                ),
                const SizedBox(height: 14),
                _buildRecentTransactionsPlaceholder(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
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
              const Text(
                "Quick Actions",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
  child: _buildQuickActionButton(
    "Transaksi Baru",
    Icons.add_shopping_cart_rounded,
    AppTheme.successColor,
    () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const SalesPage(),
        ),
      );
    },
  ),
),

              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionButton(
                  "Daftar Transaksi",
                  Icons.list_rounded,
                  AppTheme.primaryColor,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const TransactionListPage(),
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3), width: 1.5),
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
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
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
              Icon(Icons.trending_up_rounded, color: AppTheme.primaryColor, size: 20),
              const SizedBox(width: 8),
              const Text(
                "Statistik Penjualan",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  "Transaksi",
                  "234",
                  Icons.shopping_cart_rounded,
                  Colors.blue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
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
          padding: EdgeInsets.only(bottom: entry.key == menus.length - 1 ? 0 : 12),
          child: _buildMenuCard(entry.value),
        );
      }).toList(),
    );
  }

  Widget _buildMenuCard(Map<String, dynamic> menu) {
    return GestureDetector(
      onTap: () {
         if (menu["route"] == "customers") {
     Navigator.push(
       context,
       MaterialPageRoute(
         builder: (context) => const CustomerListPage(),
       ),
     );
   }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${menu["title"]} - Coming Soon'),
            duration: const Duration(milliseconds: 800),
          ),
        );
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
              color: (menu["gradient"] as List<Color>)[0].withOpacity(0.3),
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
                color: Colors.white.withOpacity(0.25),
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
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_rounded,
              color: Colors.white.withOpacity(0.7),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentTransactionsPlaceholder() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!, width: 1),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.inbox_rounded,
              size: 48,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 12),
            Text(
              "Belum ada transaksi",
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Mulai dengan membuat transaksi penjualan baru",
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}