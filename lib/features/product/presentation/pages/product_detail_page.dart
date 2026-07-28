import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../../config/theme.dart';
import '../../domain/entities/product.dart';

/// ProductDetailPage - Display detailed product information
///
/// Shows all product data from Odoo API in a beautiful layout
class ProductDetailPage extends StatelessWidget {
  final Product product;

  const ProductDetailPage({
    super.key,
    required this.product,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: CustomScrollView(
        slivers: [
          // Sticky Header with Product Info
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: AppTheme.primaryColor,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                onPressed: () {
                  _showMoreOptions(context);
                },
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryColor,
                      AppTheme.primaryColor.withValues(alpha: 0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      // Product Icon
                      Hero(
                        tag: 'product-${product.id}',
                        child: Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(
                            product.isStorable
                                ? Icons.inventory_2_rounded
                                : Icons.shopping_bag_rounded,
                            size: 50,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      // Product Name
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          product.name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            height: 1.3,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Price Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          currencyFormat.format(product.listPrice),
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Quick Stats Cards
                  _buildQuickStats(context),
                  const SizedBox(height: 20),

                  // Product Information Section
                  _buildSectionHeader('Informasi Produk', Icons.info_rounded),
                  const SizedBox(height: 12),
                  _buildProductInfoSection(),
                  const SizedBox(height: 20),

                  // Pricing Section
                  _buildSectionHeader(
                      'Informasi Harga', Icons.attach_money_rounded),
                  const SizedBox(height: 12),
                  _buildPricingSection(currencyFormat),
                  const SizedBox(height: 20),

                  // Technical Details
                  _buildSectionHeader('Detail Teknis', Icons.settings_rounded),
                  const SizedBox(height: 12),
                  _buildTechnicalSection(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build quick stats cards
  Widget _buildQuickStats(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.category_rounded,
            label: 'Tipe',
            value: _getProductTypeLabel(),
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.inventory_rounded,
            label: 'Stok',
            value: product.isStorable ? 'Ya' : 'Tidak',
            color: product.isStorable ? Colors.green : Colors.orange,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.tag_rounded,
            label: 'ID',
            value: product.id.toString(),
            color: Colors.purple,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 24, color: color),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  /// Build section header
  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 20,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  /// Build product information section
  Widget _buildProductInfoSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          _buildDetailRow(
            icon: Icons.label_rounded,
            iconColor: Colors.blue,
            label: 'Nama Produk',
            value: product.name,
            onCopy: () => _copyToClipboard(product.name),
          ),
          const Divider(height: 24),
          _buildDetailRow(
            icon: Icons.qr_code_rounded,
            iconColor: Colors.green,
            label: 'Kode Produk',
            value: product.defaultCode ?? 'Tidak ada kode',
            onCopy: product.defaultCode != null
                ? () => _copyToClipboard(product.defaultCode!)
                : null,
          ),
          const Divider(height: 24),
          _buildDetailRow(
            icon: Icons.numbers_rounded,
            iconColor: Colors.purple,
            label: 'Product ID',
            value: product.id.toString(),
            onCopy: () => _copyToClipboard(product.id.toString()),
          ),
        ],
      ),
    );
  }

  /// Build pricing section
  Widget _buildPricingSection(NumberFormat currencyFormat) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          _buildDetailRow(
            icon: Icons.sell_rounded,
            iconColor: Colors.orange,
            label: 'Harga Jual',
            value: currencyFormat.format(product.listPrice),
            valueStyle: const TextStyle(
              fontSize: 18,
              color: Colors.black87,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Divider(height: 24),
          // Price breakdown (example calculation)
          _buildPriceBreakdown(currencyFormat),
        ],
      ),
    );
  }

  Widget _buildPriceBreakdown(NumberFormat currencyFormat) {
    // Example calculations
    final ppn = product.listPrice * 0.11; // PPN 11%
    final priceBeforeTax = product.listPrice - ppn;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          _buildPriceRow(
            'Harga Sebelum Pajak',
            currencyFormat.format(priceBeforeTax),
            isSubtext: true,
          ),
          const SizedBox(height: 8),
          _buildPriceRow(
            'PPN 11%',
            currencyFormat.format(ppn),
            isSubtext: true,
          ),
          const Divider(height: 16),
          _buildPriceRow(
            'Total Harga',
            currencyFormat.format(product.listPrice),
            isBold: true,
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, String value,
      {bool isBold = false, bool isSubtext = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isSubtext ? 12 : 14,
            color: isSubtext ? Colors.grey[600] : Colors.black87,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isSubtext ? 12 : 14,
            color: isSubtext ? Colors.grey[700] : Colors.black87,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ],
    );
  }

  /// Build technical section
  Widget _buildTechnicalSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          _buildDetailRow(
            icon: Icons.category_rounded,
            iconColor: Colors.teal,
            label: 'Tipe Produk',
            value: _getProductTypeLabel(),
          ),
          const Divider(height: 24),
          _buildDetailRow(
            icon: Icons.inventory_2_rounded,
            iconColor: product.isStorable ? Colors.green : Colors.orange,
            label: 'Dapat Disimpan',
            value: product.isStorable ? 'Ya (Storable)' : 'Tidak (Service)',
          ),
          const Divider(height: 24),
          _buildBooleanIndicator(
            'Status Stok',
            product.isStorable,
            trueLabel: 'Produk Fisik',
            falseLabel: 'Produk Layanan',
            trueIcon: Icons.check_circle_rounded,
            falseIcon: Icons.cancel_rounded,
          ),
        ],
      ),
    );
  }

  /// Build detail row with icon, label, and value
  Widget _buildDetailRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    TextStyle? valueStyle,
    VoidCallback? onCopy,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Icon
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 20,
            color: iconColor,
          ),
        ),
        const SizedBox(width: 14),

        // Label & Value
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: valueStyle ??
                    const TextStyle(
                      fontSize: 15,
                      color: Colors.black87,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
              ),
            ],
          ),
        ),

        // Copy button
        if (onCopy != null)
          IconButton(
            icon: Icon(
              Icons.copy_rounded,
              size: 18,
              color: Colors.grey[400],
            ),
            onPressed: onCopy,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
      ],
    );
  }

  /// Build boolean indicator
  Widget _buildBooleanIndicator(
    String label,
    bool value, {
    required String trueLabel,
    required String falseLabel,
    required IconData trueIcon,
    required IconData falseIcon,
  }) {
    final isTrue = value;
    final color = isTrue ? Colors.green : Colors.orange;
    final displayLabel = isTrue ? trueLabel : falseLabel;
    final displayIcon = isTrue ? trueIcon : falseIcon;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(displayIcon, size: 24, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  displayLabel,
                  style: TextStyle(
                    fontSize: 14,
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Get product type label
  String _getProductTypeLabel() {
    switch (product.type.toLowerCase()) {
      case 'consu':
        return 'Consumable';
      case 'service':
        return 'Service';
      case 'product':
        return 'Storable Product';
      default:
        return product.type;
    }
  }

  /// Show more options bottom sheet
  void _showMoreOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading:
                  const Icon(Icons.share_rounded, color: AppTheme.primaryColor),
              title: const Text('Bagikan Produk'),
              onTap: () {
                Navigator.pop(context);
                _shareProduct(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.add_shopping_cart_rounded,
                  color: Colors.green),
              title: const Text('Tambah ke Keranjang'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Fitur keranjang akan segera hadir')),
                );
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.favorite_border_rounded, color: Colors.red),
              title: const Text('Tandai Favorit'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Fitur favorit akan segera hadir')),
                );
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.delete_outline_rounded, color: Colors.red),
              title: const Text('Hapus Produk'),
              onTap: () {
                Navigator.pop(context);
                _confirmDelete(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Copy to clipboard
  void _copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
  }

  /// Share product
  void _shareProduct(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Fitur share akan segera hadir')),
    );
    // TODO: Implement share using share_plus package
  }

  /// Confirm delete
  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Produk'),
        content: Text('Yakin ingin menghapus ${product.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
              // TODO: Implement delete product API
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}
