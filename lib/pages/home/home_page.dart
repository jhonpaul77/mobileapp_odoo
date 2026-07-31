// lib/pages/home/home_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nextpsa/config/theme.dart';
import 'package:nextpsa/pages/home/home_dashboard_page.dart';
import 'package:nextpsa/pages/profile/setting_profile.dart';
import 'package:nextpsa/pages/sales/penjualan_page.dart';
import 'package:nextpsa/services/status_bar_service.dart';
import 'package:nextpsa/widgets/common/app_bottom_nav.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  // Bottom Navigation Items - 3 menu: Dashboard, Penjualan, Profile
  final List<BottomNavItem> _navItems = const [
    BottomNavItem(icon: Icons.dashboard_rounded, label: 'Dashboard'),
    BottomNavItem(icon: Icons.shopping_bag_rounded, label: 'Penjualan'),
    BottomNavItem(icon: Icons.person_rounded, label: 'Profile'),
  ];

  @override
  void initState() {
    super.initState();

    // Set status bar untuk HomePage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      StatusBarService.setDarkStatusBar();
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      const HomeDashboardPage(), // Index 0 - Dashboard
      const PenjualanPage(),     // Index 1 - Penjualan
      const SettingProfile(),    // Index 2 - Profile
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

