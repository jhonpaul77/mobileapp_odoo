// lib/pages/home/widgets/kpi_cards.dart

import 'package:flutter/material.dart';
import 'package:pintarx/config/theme.dart';
import '../utils/formatters.dart';
import '../data/dummy_data.dart';

class KPICards extends StatelessWidget {
  const KPICards({super.key});

  Widget _buildKPICard(
    String title,
    String value,
    IconData icon,
    Color color,
    String trend,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
        border: Border.all(
          color: AppTheme.borderColor,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          )
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Title + Icon
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Value
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),

          // Trend Badge
          Text(
            trend,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stats = DummyData.dashboardStats;

    return Column(
      children: [
        // Row 1: Total Penjualan + Total Pengeluaran
        Row(
          children: [
            Expanded(
              child: _buildKPICard(
                "Total Penjualan",
                Formatters.formatCurrency(stats["totalSales"] as num),
                Icons.trending_up_rounded,
                AppTheme.successColor,
                "+12%",
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildKPICard(
                "Total Pengeluaran",
                Formatters.formatCurrency(stats["totalExpenses"] as num),
                Icons.trending_down_rounded,
                AppTheme.errorColor,
                "+5%",
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Row 2: Nilai Inventory + Profit Bersih
        Row(
          children: [
            Expanded(
              child: _buildKPICard(
                "Nilai Inventory",
                Formatters.formatCurrency(stats["inventoryValue"] as num),
                Icons.inventory_2_rounded,
                AppTheme.brandGreen,
                "Normal",
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildKPICard(
                "Profit Bersih",
                Formatters.formatCurrency(stats["profit"] as num),
                Icons.account_balance_wallet_rounded,
                AppTheme.brandBlue,
                "+8%",
              ),
            ),
          ],
        ),
      ],
    );
  }
}