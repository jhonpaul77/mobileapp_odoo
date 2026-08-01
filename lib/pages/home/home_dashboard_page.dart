import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nextpsa/features/customer/presentation/providers/customer_provider.dart';
import 'package:nextpsa/pages/home/widgets/dashboard_stats_card.dart';
import 'package:nextpsa/services/secure_storage_service.dart';
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

  Widget _buildDebugInfoCard(ThemeData theme) {
    return FutureBuilder<Map<String, String>>(
      future: _getDebugInfo(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final info = snapshot.data!;
        final apiKey = info['apiKey'] ?? 'N/A';
        final username = info['username'] ?? 'N/A';

        return Container(
          decoration: BoxDecoration(
            color: theme.primaryColor.withValues(alpha: 0.1),
            border: Border.all(
              color: theme.primaryColor.withValues(alpha: 0.3),
              width: 1,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.info_outlined,
                    size: 16,
                    color: theme.primaryColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Login Info',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: theme.primaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              
              // Username
              Row(
                children: [
                  Text(
                    'User:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: theme.textTheme.bodySmall?.color,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      username,
                      style: TextStyle(
                        fontSize: 12,
                        fontFamily: 'Courier',
                        color: theme.textTheme.bodyLarge?.color,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              // API Key - Full display
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'API Key:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: theme.textTheme.bodySmall?.color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.brightness == Brightness.dark 
                          ? Colors.black26 
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: theme.dividerColor,
                        width: 0.5,
                      ),
                    ),
                    child: SelectableText(
                      apiKey,
                      style: TextStyle(
                        fontSize: 11,
                        fontFamily: 'Courier',
                        color: theme.textTheme.bodyLarge?.color,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<Map<String, String>> _getDebugInfo() async {
    try {
      final storage = SecureStorageService();
      final apiKey = await storage.getAccessToken() ?? 'Not set';
      final userData = await storage.getUserData();
      final username = userData?['username'] ?? 'Unknown';

      return {
        'apiKey': apiKey,
        'username': username.toString(),
      };
    } catch (e) {
      return {
        'apiKey': 'Error: $e',
        'username': 'Error loading',
      };
    }
  }
}

