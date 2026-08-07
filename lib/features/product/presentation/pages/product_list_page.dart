import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../config/theme.dart';
import '../providers/product_provider.dart';
import '../widgets/product_card.dart';
import '../widgets/product_search_bar.dart';
// import 'product_detail_page.dart'; // Hidden for now

/// Product List Page
///
/// Displays list of products with search and advanced filter functionality.
class ProductListPage extends StatefulWidget {
  const ProductListPage({super.key});

  @override
  State<ProductListPage> createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> {
  @override
  void initState() {
    super.initState();
    // Fetch products on page load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().fetchProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Daftar Produk',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<ProductProvider>(
        builder: (context, provider, child) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(
              children: [
                // Search Bar with Filter Button
                _buildSearchWithFilterBar(provider, theme),
                const SizedBox(height: 14),

                // Product List
                Expanded(
                  child: _buildBody(provider),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchWithFilterBar(ProductProvider provider, ThemeData theme) {
    return Row(
      children: [
        // Search Bar (expanded)
        Expanded(
          child: const ProductSearchBar(),
        ),
        const SizedBox(width: 8),
        // Filter Button (corong icon)
        _buildFilterButton(provider, theme),
      ],
    );
  }

  Widget _buildFilterButton(ProductProvider provider, ThemeData theme) {
    final hasActiveFilter = provider.selectedType != null;
    
    return GestureDetector(
      onTap: () => _showAdvancedFilterDialog(provider),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: hasActiveFilter
              ? AppTheme.primaryColor
              : (theme.brightness == Brightness.dark
                  ? Colors.grey[800]
                  : Colors.grey[200]),
          borderRadius: BorderRadius.circular(8),
          border: hasActiveFilter
              ? Border.all(color: AppTheme.primaryColor, width: 2)
              : null,
        ),
        child: Icon(
          Icons.tune,
          color: hasActiveFilter ? Colors.white : Colors.grey[600],
          size: 20,
        ),
      ),
    );
  }

  void _showAdvancedFilterDialog(ProductProvider provider) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Advanced Filter',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Icon(
                    Icons.close,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Filter: Jenis Barang
            const Text(
              'Jenis Barang',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            _buildFilterOptions(provider),
            const SizedBox(height: 16),

            // Clear Filter Button
            if (provider.selectedType != null)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    provider.clearAllFilters();
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.clear),
                  label: const Text('Clear Filter'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade600,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterOptions(ProductProvider provider) {
    final types = ['All', ...provider.availableTypes];
    
    return Column(
      children: types.map((type) {
        final label = type == 'All' 
            ? 'Semua' 
            : (type == 'jasa' ? 'Jasa' : 'Stok');
        final isSelected = (type == 'All' && provider.selectedType == null) ||
            (type != 'All' && provider.selectedType == type);
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: GestureDetector(
            onTap: () {
              provider.setTypeFilter(type == 'All' ? null : type);
              Navigator.pop(context);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.primaryColor.withValues(alpha: 0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected
                      ? AppTheme.primaryColor
                      : Colors.grey.shade300,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Radio<bool>(
                    value: true,
                    groupValue: isSelected,
                    onChanged: (_) {},
                  ),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
                      color: isSelected
                          ? AppTheme.primaryColor
                          : Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBody(ProductProvider provider) {
    // Loading state
    if (provider.isLoading && provider.products.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Memuat data produk...',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ],
        ),
      );
    }

    // Error state
    if (provider.hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: AppTheme.errorColor,
            ),
            const SizedBox(height: 16),
            Text(
              'Terjadi Kesalahan',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                provider.errorMessage ?? 'Unknown error',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => provider.fetchProducts(),
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    // Empty state
    if (provider.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              provider.searchQuery.isEmpty
                  ? Icons.inventory_2_outlined
                  : Icons.search_off,
              size: 64,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              provider.searchQuery.isEmpty
                  ? 'Belum ada produk'
                  : 'Tidak ada hasil pencarian',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            if (provider.searchQuery.isNotEmpty) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => provider.clearSearch(),
                child: const Text('Clear pencarian'),
              ),
            ],
          ],
        ),
      );
    }

    // Product list
    return RefreshIndicator(
      onRefresh: () => provider.fetchProducts(),
      child: Column(
        children: [
          // Product count
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${provider.productsCount} Produk',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                if (provider.searchQuery.isNotEmpty)
                  TextButton.icon(
                    onPressed: () => provider.clearSearch(),
                    icon: const Icon(Icons.close, size: 16),
                    label: const Text('Clear'),
                  ),
              ],
            ),
          ),
          // Product list
          Expanded(
            child: ListView.builder(
              itemCount: provider.products.length,
              itemBuilder: (context, index) {
                final product = provider.products[index];
                return ProductCard(
                  product: product,
                  onTap: () {
                    // ScaffoldMessenger.of(context).showSnackBar(
                    //   const SnackBar(
                    //     content: Text('Fitur detail produk akan segera hadir'),
                    //     duration: Duration(seconds: 2),
                    //   ),
                    // );

                    // Navigator.push(
                    //   context,
                    //   MaterialPageRoute(
                    //     builder: (context) =>
                    //         ProductDetailPage(product: product),
                    //   ),
                    // );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
