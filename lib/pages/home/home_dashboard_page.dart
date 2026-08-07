import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nextpsa/features/customer/presentation/providers/customer_provider.dart';
import 'package:nextpsa/pages/home/widgets/dashboard_stats_card.dart';
import 'package:nextpsa/services/secure_storage_service.dart';
import 'package:nextpsa/services/status_bar_service.dart';
import 'package:nextpsa/config/sales_quotes.dart';
import 'package:package_info_plus/package_info_plus.dart';
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
  bool _isSyncButtonDisabledOnFirstLoad = true; // Disable tombol sync setelah pertama kali load

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      StatusBarService.setDarkStatusBar();
      // Load stats dari local database (data sudah di-sync saat login di SyncSplashPage)
      final provider = context.read<CustomerProvider>();
      provider.loadLocationStats(); // Load locations from local DB
      provider.loadSyncStats(); // Load sync timestamp
      
      // Auto-enable sync button after 3 seconds (allow user to see fresh data first)
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _isSyncButtonDisabledOnFirstLoad = false;
          });
          print('✅ [DASHBOARD] Sync button enabled');
        }
      });
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
                  // APP VERSION INFO CARD
                  _buildVersionInfoCard(theme),
                  const SizedBox(height: 16),

                  // DEBUG INFO CARD - Show API Key and Username
                  _buildDebugInfoCard(theme),
                  const SizedBox(height: 16),
                  
                  // DATABASE STATS CARD
                  DashboardStatsCard(isFirstLoadDisabled: _isSyncButtonDisabledOnFirstLoad),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // 7 Motivational quotes for CS - rotated daily
  Widget _buildVersionInfoCard(ThemeData theme) {
    return FutureBuilder<String>(
      future: _getAppVersion(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final version = snapshot.data ?? 'Unknown';

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                theme.primaryColor.withValues(alpha: 0.08),
                theme.primaryColor.withValues(alpha: 0.02),
              ],
            ),
            border: Border.all(
              color: theme.primaryColor.withValues(alpha: 0.2),
              width: 1,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: theme.primaryColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'App Version',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: theme.textTheme.bodySmall?.color,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: theme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  version,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: theme.primaryColor,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<String> _getAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      return 'V ${packageInfo.version} (${packageInfo.buildNumber})';
    } catch (e) {
      return 'V Unknown';
    }
  }

  Widget _buildDebugInfoCard(ThemeData theme) {
    return FutureBuilder<Map<String, String>>(
      future: _getMotivationData(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final data = snapshot.data!;
        final username = data['username'] ?? 'User';
        final quote = data['quote'] ?? '';

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                theme.primaryColor.withValues(alpha: 0.15),
                theme.primaryColor.withValues(alpha: 0.05),
              ],
            ),
            border: Border.all(
              color: theme.primaryColor.withValues(alpha: 0.3),
              width: 1,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting with username
              Row(
                children: [
                  Icon(
                    Icons.waving_hand,
                    size: 22,
                    color: theme.primaryColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Hello, $username! 👋',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: theme.textTheme.bodyLarge?.color,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              
              // Motivational Quote
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.brightness == Brightness.dark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.white.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      size: 18,
                      color: theme.primaryColor,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        quote,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: theme.textTheme.bodyMedium?.color,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<Map<String, String>> _getMotivationData() async {
    try {
      // Get username
      final storage = SecureStorageService();
      final userData = await storage.getUserData();
      final username = userData?['username'] as String? ?? 'User';
      
      // Get random sales/motivation quote
      final quote = SalesQuotes.getRandomQuote();

      return {
        'username': username,
        'quote': quote,
      };
    } catch (e) {
      return {
        'username': 'User',
        'quote': SalesQuotes.getRandomQuote(),
      };
    }
  }
}

