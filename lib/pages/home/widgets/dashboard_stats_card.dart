import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../config/theme.dart';
import '../../../features/customer/presentation/providers/customer_provider.dart';

/// Dashboard Stats Card - Display Customer & Location Stats
///
/// Shows:
/// - Total customers synced
/// - Total states, cities, districts
/// - Last sync time
/// - Quick sync buttons
class DashboardStatsCard extends StatelessWidget {
  const DashboardStatsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Consumer<CustomerProvider>(
      builder: (context, provider, _) {
        final totalCustomers = provider.customersCount;
        final locationStats = provider.locationStats;
        final states = locationStats['states'] ?? 0;
        final cities = locationStats['cities'] ?? 0;
        final districts = locationStats['districts'] ?? 0;
        final syncStats = provider.syncStats;
        final lastSync = syncStats['lastSync'] as String?;

        // Format last sync time
        String lastSyncText = 'Never';
        if (lastSync != null) {
          try {
            final lastSyncTime = DateTime.parse(lastSync);
            final now = DateTime.now();
            final diff = now.difference(lastSyncTime);

            if (diff.inMinutes < 1) {
              lastSyncText = 'Just now';
            } else if (diff.inMinutes < 60) {
              lastSyncText = '${diff.inMinutes}m ago';
            } else if (diff.inHours < 24) {
              lastSyncText = '${diff.inHours}h ago';
            } else {
              lastSyncText = '${diff.inDays}d ago';
            }
          } catch (e) {
            lastSyncText = 'Unknown';
          }
        }

        return Container(
          padding: const EdgeInsets.all(16),
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
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.dashboard,
                      color: AppTheme.primaryColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Database Summary',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: theme.textTheme.bodyLarge?.color,
                          ),
                        ),
                        Text(
                          'Last sync: $lastSyncText',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Stats Row (Horizontal)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildStatCard(
                      label: 'Customers',
                      value: totalCustomers.toString(),
                      icon: Icons.people_rounded,
                      color: Colors.blue,
                      theme: theme,
                    ),
                    const SizedBox(width: 12),
                    _buildStatCard(
                      label: 'States',
                      value: states.toString(),
                      icon: Icons.location_on_rounded,
                      color: Colors.purple,
                      theme: theme,
                    ),
                    const SizedBox(width: 12),
                    _buildStatCard(
                      label: 'Cities',
                      value: cities.toString(),
                      icon: Icons.apartment_rounded,
                      color: Colors.orange,
                      theme: theme,
                    ),
                    const SizedBox(width: 12),
                    _buildStatCard(
                      label: 'Districts',
                      value: districts.toString(),
                      icon: Icons.location_city_rounded,
                      color: Colors.green,
                      theme: theme,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: _buildActionButton(
                      label: 'Sync Customers',
                      icon: Icons.people,
                      color: Colors.blue,
                      isLoading: provider.isSyncing,
                      onTap: () => _showSyncCustomersDialog(context, provider),
                      theme: theme,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildActionButton(
                      label: 'Sync Locations',
                      icon: Icons.location_on,
                      color: Colors.purple,
                      isLoading: false,
                      onTap: () => _showSyncLocationsDialog(context, provider),
                      theme: theme,
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

  /// Build individual stat card
  Widget _buildStatCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required ThemeData theme,
  }) {
    return Container(
      width: 100,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: theme.textTheme.bodyLarge?.color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  /// Build action button
  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required bool isLoading,
    required VoidCallback onTap,
    required ThemeData theme,
  }) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoading)
              SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              )
            else
              Icon(icon, color: color, size: 14),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Show sync customers dialog
  void _showSyncCustomersDialog(
    BuildContext context,
    CustomerProvider provider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sync Customers?'),
        content: const Text(
          'This will sync all customers from the server. This may take a few moments.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _performSync(context, provider);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
            ),
            child: const Text('Sync'),
          ),
        ],
      ),
    );
  }

  /// Show sync locations dialog
  void _showSyncLocationsDialog(
    BuildContext context,
    CustomerProvider provider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sync Locations?'),
        content: const Text(
          'This will sync all states, cities, and districts from the server.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _performLocationSync(context, provider);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
            ),
            child: const Text('Sync'),
          ),
        ],
      ),
    );
  }

  /// Perform customer sync
  Future<void> _performSync(
    BuildContext context,
    CustomerProvider provider,
  ) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              SizedBox(width: 8),
              Expanded(child: Text('Syncing customers...')),
            ],
          ),
          backgroundColor: Colors.blue,
        ),
      );

      final result = await provider.syncCustomers();

      // Refresh stats after sync complete
      await provider.loadLocationStats();

      if (context.mounted && result != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ ${result.newCount} new | ✏️ ${result.updatedCount} updated',
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sync failed: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  /// Perform location sync
  Future<void> _performLocationSync(
    BuildContext context,
    CustomerProvider provider,
  ) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              SizedBox(width: 8),
              Expanded(child: Text('Syncing locations...')),
            ],
          ),
          backgroundColor: Colors.purple,
        ),
      );

      await provider.syncLocations();

      // Refresh stats after sync complete
      await provider.loadLocationStats();

      if (context.mounted) {
        final stats = provider.locationStats;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ ${stats['states']} states | ${stats['cities']} cities | ${stats['districts']} districts',
            ),
            backgroundColor: Colors.purple,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sync failed: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }
}
