// lib/pages/home/home_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pintarx/config/theme.dart';
import 'package:pintarx/pages/profile/setting_profile.dart';
import 'package:pintarx/pages/sales/penjualan_page.dart';
import 'package:pintarx/services/status_bar_service.dart';
import 'package:pintarx/widgets/common/app_bottom_nav.dart';
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
      const PenjualanPage(), // Index 0 - Penjualan
      const SettingProfile(), // Index 1 - Profile
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
          systemOverlayStyle: const SystemUiOverlayStyle(
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
}
