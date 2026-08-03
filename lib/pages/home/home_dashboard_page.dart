import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nextpsa/features/customer/presentation/providers/customer_provider.dart';
import 'package:nextpsa/pages/home/widgets/dashboard_stats_card.dart';
import 'package:nextpsa/services/secure_storage_service.dart';
import 'package:nextpsa/services/status_bar_service.dart';
import 'package:nextpsa/config/sales_quotes.dart';
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
      provider.syncLocations(); // Sync locations (States, Cities, Districts) to local DB
      provider.loadLocationStats(); // Load stats after sync
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
                  // DEBUG INFO CARD - Show API Key and Username
                  _buildDebugInfoCard(theme),
                  const SizedBox(height: 16),
                  
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

  // 7 Motivational quotes for CS - rotated daily
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

