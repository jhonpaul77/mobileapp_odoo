import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nextpsa/features/customer/presentation/providers/customer_provider.dart';
import 'package:nextpsa/pages/home/widgets/dashboard_stats_card.dart';
import 'package:nextpsa/services/status_bar_service.dart';
import 'package:provider/provider.dart';

/// Home Dashboard Page
///
/// Main dashboard showing:
/// - Database summary (customers, states, cities, districts)
/// - Quick sync options
/// - Key statistics
class HomeDashboardPage extends StatefulWidget {
  const HomeDashboardPage({super.key});

  @override
  State<HomeDashboardPage> createState() => _HomeDashboardPageState();
}

class _HomeDashboardPageState extends State<HomeDashboardPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      StatusBarService.setDarkStatusBar();
      // Load stats
      final provider = context.read<CustomerProvider>();
      provider.fetchCustomers();
      provider.loadSyncStats();
      provider.loadLocationStats();
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
      body: _buildDashboard(theme),
    );
  }

  Widget _buildDashboard(ThemeData theme) {
    return CustomScrollView(
      slivers: [
        // HEADER
        SliverAppBar(
          floating: false,
          pinned: true,
          snap: false,
          elevation: 0,
          backgroundColor: theme.scaffoldBackgroundColor,
          collapsedHeight: 60,
          expandedHeight: 60,
          toolbarHeight: 60,
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
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Dashboard',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                ),
              ),
            ),
          ),
        ),

        // CONTENT
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // DATABASE STATS CARD
                  const DashboardStatsCard(),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

