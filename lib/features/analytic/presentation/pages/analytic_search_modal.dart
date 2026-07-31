import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../config/theme.dart';
import '../../domain/entities/analytic.dart';
import '../providers/analytic_provider.dart';

/// AnalyticSearchModal - Searchable modal untuk memilih Analytic Distribution
class AnalyticSearchModal extends StatefulWidget {
  final Analytic? selectedAnalytic;

  const AnalyticSearchModal({
    Key? key,
    this.selectedAnalytic,
  }) : super(key: key);

  static Future<Analytic?> show(BuildContext context,
      {Analytic? selectedAnalytic}) async {
    return showDialog<Analytic?>(
      context: context,
      builder: (context) => AnalyticSearchModal(
        selectedAnalytic: selectedAnalytic,
      ),
    );
  }

  @override
  State<AnalyticSearchModal> createState() => _AnalyticSearchModalState();
}

class _AnalyticSearchModalState extends State<AnalyticSearchModal> {
  late TextEditingController _searchController;
  late AnalyticProvider _provider;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _provider = context.read<AnalyticProvider>();

    // Load analytics if not loaded yet
    if (_provider.isEmpty) {
      _provider.fetchAnalytics();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.store_rounded,
                    color: AppTheme.brandBlue, size: 24),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Pilih Analytic Distribution',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                )
              ],
            ),
            const SizedBox(height: 16),

            // Search field
            TextField(
              controller: _searchController,
              onChanged: (value) {
                _provider.search(value);
              },
              decoration: InputDecoration(
                hintText: 'Cari store...',
                prefixIcon: const Icon(Icons.search_rounded),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // List
            Consumer<AnalyticProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return const Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(),
                  );
                }

                if (provider.hasError) {
                  return Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      provider.errorMessage ?? 'Error loading analytics',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                }

                if (provider.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(20),
                    child: Text('Tidak ada analytic distribution ditemukan'),
                  );
                }

                return SizedBox(
                  height: 300,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: provider.analytics.length,
                    itemBuilder: (context, index) {
                      final analytic = provider.analytics[index];
                      final isSelected =
                          widget.selectedAnalytic?.id == analytic.id;

                      return ListTile(
                        selected: isSelected,
                        selectedTileColor:
                            AppTheme.brandBlue.withValues(alpha: 0.1),
                        title: Text(analytic.name),
                        subtitle: Text('ID: ${analytic.id}'),
                        trailing: isSelected
                            ? const Icon(Icons.check_rounded,
                                color: AppTheme.brandBlue)
                            : null,
                        onTap: () {
                          _provider.clearSearch();
                          Navigator.pop(context, analytic);
                        },
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
