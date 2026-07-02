// lib/pages/home/home_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pintarx/config/theme.dart';
import 'package:pintarx/widgets/common/app_bottom_nav.dart';
import 'package:pintarx/widgets/common/app_header.dart';
import 'package:pintarx/widgets/common/section_header.dart';
import 'package:pintarx/pages/profile/profile_page.dart';
import 'package:pintarx/pages/settings/setting_page.dart';
import 'package:pintarx/pages/sales/penjualan_page.dart';
import 'package:pintarx/services/status_bar_service.dart';
import 'package:pintarx/pages/profile/setting_profile.dart';

// TODO: Import dashboard widgets nanti
import 'widgets/kpi_cards.dart';
import 'widgets/menu_utama.dart';
// import 'widgets/penjualan_terbaru.dart';
// import 'widgets/stok_peringatan.dart';
// import 'widgets/progress_produksi.dart';
// import 'widgets/pengeluaran_terkini.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  // Bottom Navigation Items
  final List<BottomNavItem> _navItems = const [
    BottomNavItem(icon: Icons.shopping_bag_rounded, label: 'Penjualan'),
    BottomNavItem(icon: Icons.person_rounded, label: 'Profile'),
  ];

  @override
  void initState() {
    super.initState();
    
    // Set status bar untuk HomePage (background biru, icon putih)
   WidgetsBinding.instance.addPostFrameCallback((_) {
      StatusBarService.setDarkStatusBar();
        });
  }
  @override
  Widget build(BuildContext context) {
    final pages = [
      const PenjualanPage(),                                    // Index 0 - Penjualan
      const SettingProfile(),                                   // Index 1 - Profile
    ];

    final currentIndex = _selectedIndex.clamp(0, pages.length - 1);
    if (currentIndex != _selectedIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _selectedIndex = currentIndex);
      });
    }

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
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: child,
        ),
        child: pages[_selectedIndex],
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: _navItems,
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // 📊 DASHBOARD PAGE (Index 0) - CustomScrollView + SliverAppBar
  // ═══════════════════════════════════════════════════════════════
  Widget _buildDashboard() {
    return CustomScrollView(
      slivers: [
        // ✅ STICKY HEADER
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
                title: "Dashboard",
                subtitle: "Aplikasi Pintar - Versi 1.0.0",
                showDate: true,
                onNotificationTap: () {
                  setState(() => _selectedIndex = 3);
                },
              ),
            ),
          ),
        ),

        // ✅ SCROLLABLE CONTENT
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 28, 16, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // KPI SECTION
                const KPICards(),
                const SizedBox(height: 28),

                // MENU GRID
                const MenuUtama(),
                const SizedBox(height: 32),

                // PENJUALAN TERBARU
                SectionHeader(
                  title: "Penjualan Terbaru",
                  icon: Icons.shopping_bag_rounded,
                  onActionTap: () {
                    // Navigate to sales page
                  },
                ),
                const SizedBox(height: 14),
                // const PenjualanTerbaru(),
                const SizedBox(height: 32),

                // STOK PERINGATAN
                SectionHeader(
                  title: "Stok Peringatan",
                  icon: Icons.warning_amber_rounded,
                  iconColor: AppTheme.warningColor,
                  onActionTap: () {
                    // Navigate to inventory page
                  },
                ),
                const SizedBox(height: 14),
                // const StokPeringatan(),
                const SizedBox(height: 32),

                // PROGRESS PRODUKSI
                SectionHeader(
                  title: "Progress Produksi",
                  icon: Icons.factory_rounded,
                  iconColor: AppTheme.brandOrange,
                  onActionTap: () {
                    // Navigate to production page
                  },
                ),
                const SizedBox(height: 14),
                // const ProgressProduksi(),
                const SizedBox(height: 32),

                // PENGELUARAN TERKINI
                SectionHeader(
                  title: "Pengeluaran Terkini",
                  icon: Icons.receipt_rounded,
                  iconColor: AppTheme.errorColor,
                  onActionTap: () {
                    // Navigate to expenses page
                  },
                ),
                const SizedBox(height: 14),
                // const PengeluaranTerkini(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // 📄 EMPTY PAGE PLACEHOLDER
  // ═══════════════════════════════════════════════════════════════
  Widget _buildEmptyPage(String title, IconData icon) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: AppHeader(
            title: title,
            showDate: false,
            subtitle: "Coming Soon",
            onNotificationTap: () {
              setState(() => _selectedIndex = 3);
            },
          ),
        ),
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 80,
                  color: Colors.grey[300],
                ),
                const SizedBox(height: 16),
                Text(
                  "Halaman dalam pengembangan",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}