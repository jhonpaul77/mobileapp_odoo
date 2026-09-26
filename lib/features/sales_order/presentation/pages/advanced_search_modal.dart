import 'package:flutter/material.dart';

import '../../../../config/theme.dart';

/// Advanced Search Modal - Comprehensive filter dialog
/// 
/// Allows users to set multiple filters:
/// - Status (All, Open, Confirm, Sale, Cancel)
/// - Date Range (Today, Yesterday, This Week, This Month)
/// - WA Status (Sent / Not Sent)
class AdvancedSearchModal extends StatefulWidget {
  final Set<String>? initialWAStatus;
  final String? initialDateFilter;
  final String? initialStatusFilter;

  const AdvancedSearchModal({
    super.key,
    this.initialWAStatus,
    this.initialDateFilter,
    this.initialStatusFilter,
  });

  @override
  State<AdvancedSearchModal> createState() => _AdvancedSearchModalState();
}

class _AdvancedSearchModalState extends State<AdvancedSearchModal> {
  String? _selectedStatus;
  String? _selectedDate;
  Set<String> _selectedWAStatus = {};

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.initialStatusFilter;
    _selectedDate = widget.initialDateFilter;
    _selectedWAStatus = Set.from(widget.initialWAStatus ?? {});
  }

  void _applyFilters() {
    final result = {
      'statusFilter': _selectedStatus,
      'dateFilter': _selectedDate,
      'waStatus': _selectedWAStatus,
    };
    Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 700),
        decoration: BoxDecoration(
          color: theme.cardTheme.color,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Advanced Search',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status Filter
                    _buildSectionLabel('Status'),
                    const SizedBox(height: 10),
                    _buildStatusFilter(),
                    const SizedBox(height: 16),

                    // Date Filter
                    _buildSectionLabel('Tanggal'),
                    const SizedBox(height: 10),
                    _buildDateFilter(),
                    const SizedBox(height: 16),

                    // WA Status Filter
                    _buildSectionLabel('WA Status'),
                    const SizedBox(height: 10),
                    _buildWAStatusFilter(),
                  ],
                ),
              ),
            ),

            // Footer - Action Buttons
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: theme.brightness == Brightness.dark
                        ? Colors.grey[800]!
                        : Colors.grey[200]!,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _applyFilters,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text(
                        'Apply',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: Colors.grey,
      ),
    );
  }

  Widget _buildStatusFilter() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildFilterChip('All', null, 'status'),
        _buildFilterChip('Open', 'Open', 'status'),
        _buildFilterChip('Confirm', 'Confirm', 'status'),
        _buildFilterChip('Sale', 'Sale', 'status'),
        _buildFilterChip('Cancel', 'Cancel', 'status'),
      ],
    );
  }

  Widget _buildDateFilter() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildFilterChip('Today', 'today', 'date'),
        _buildFilterChip('Yesterday', 'yesterday', 'date'),
        _buildFilterChip('This Week', 'thisWeek', 'date'),
        _buildFilterChip('This Month', 'thisMonth', 'date'),
      ],
    );
  }

  Widget _buildWAStatusFilter() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildWAStatusChip('Sudah Kirim WA', 'sent'),
        _buildWAStatusChip('Belum Kirim WA', 'not_sent'),
      ],
    );
  }

  Widget _buildFilterChip(String label, String? value, String type) {
    final theme = Theme.of(context);
    bool isSelected = false;

    if (type == 'status') {
      isSelected = _selectedStatus == value;
    } else if (type == 'date') {
      isSelected = _selectedDate == value;
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          if (type == 'status') {
            _selectedStatus = isSelected ? null : value;
          } else if (type == 'date') {
            _selectedDate = isSelected ? null : value;
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryColor.withValues(alpha: 0.15)
              : theme.brightness == Brightness.dark
                  ? Colors.grey[800]
                  : Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryColor
                : theme.brightness == Brightness.dark
                    ? Colors.grey[700]!
                    : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? AppTheme.primaryColor
                : theme.textTheme.bodyMedium?.color,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildWAStatusChip(String label, String value) {
    final theme = Theme.of(context);
    final isSelected = _selectedWAStatus.contains(value);

    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedWAStatus.remove(value);
          } else {
            _selectedWAStatus.add(value);
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryColor.withValues(alpha: 0.15)
              : theme.brightness == Brightness.dark
                  ? Colors.grey[800]
                  : Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryColor
                : theme.brightness == Brightness.dark
                    ? Colors.grey[700]!
                    : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? AppTheme.primaryColor
                : theme.textTheme.bodyMedium?.color,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
