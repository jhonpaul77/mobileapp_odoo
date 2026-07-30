import 'package:flutter/material.dart';
import 'package:pintarx/config/theme.dart';

class ProductListPage extends StatefulWidget {
  const ProductListPage({super.key});

  static final List<Map<String, dynamic>> _demoProducts = [
    {
      'id': 1,
      'name': 'Paket A',
      'sku': 'PKT-001',
      'category': 'Paket',
      'price': 325000.0,
      'stock': 150,
      'description': 'Paket hemat untuk kebutuhan sehari-hari',
      'image': null,
    },
    {
      'id': 2,
      'name': 'Paket B',
      'sku': 'PKT-002',
      'category': 'Paket',
      'price': 875000.0,
      'stock': 85,
      'description': 'Paket premium dengan harga terjangkau',
      'image': null,
    },
    {
      'id': 3,
      'name': 'Produk C',
      'sku': 'PRD-003',
      'category': 'Produk',
      'price': 180000.0,
      'stock': 250,
      'description': 'Produk berkualitas tinggi',
      'image': null,
    },
    {
      'id': 4,
      'name': 'Produk D',
      'sku': 'PRD-004',
      'category': 'Produk',
      'price': 320000.0,
      'stock': 120,
      'description': 'Produk pilihan dengan banyak keuntungan',
      'image': null,
    },
    {
      'id': 5,
      'name': 'Produk E',
      'sku': 'PRD-005',
      'category': 'Produk',
      'price': 345000.0,
      'stock': 0,
      'description': 'Produk eksklusif (sedang kosong)',
      'image': null,
    },
    {
      'id': 6,
      'name': 'Produk F',
      'sku': 'PRD-006',
      'category': 'Produk',
      'price': 412500.0,
      'stock': 75,
      'description': 'Produk terbaru dengan fitur lengkap',
      'image': null,
    },
  ];

  @override
  State<ProductListPage> createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  List<Map<String, dynamic>> get _filteredProducts {
    final query = _searchQuery.trim().toLowerCase();
    List<Map<String, dynamic>> filtered = ProductListPage._demoProducts;

    // Filter by search query
    if (query.isNotEmpty) {
      filtered = filtered.where((product) {
        return (product['name'] as String).toLowerCase().contains(query) ||
            (product['sku'] as String).toLowerCase().contains(query);
      }).toList();
    }

    return filtered;
  }

  String _formatCurrency(double value) {
    final formatted = value.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (match) => '.',
        );
    return 'Rp $formatted';
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final products = _filteredProducts;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Daftar Produk',
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.w600, fontSize: 18),
        ),
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: Column(
          children: [
            // Search Bar
            TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Cari produk atau SKU...',
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
            const SizedBox(height: 14),

            // Product List
            Expanded(
              child: products.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.shopping_bag_outlined,
                              size: 64, color: Colors.grey[300]),
                          const SizedBox(height: 16),
                          Text(
                            'Tidak ada produk',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      itemCount: products.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final product = products[index];
                        final isOutOfStock = (product['stock'] as int) == 0;

                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border:
                                Border.all(color: Colors.grey[200]!, width: 1),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Header: Name
                                Text(
                                  product['name'] as String,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black87,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 1),

                                // SKU
                                Text(
                                  'SKU: ${product['sku']}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 2),

                                // Bottom: Price & Stock
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _formatCurrency(
                                          product['price'] as double),
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.successColor,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: isOutOfStock
                                            ? Colors.red.withValues(alpha: 0.1)
                                            : Colors.green
                                                .withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        isOutOfStock
                                            ? 'Kosong'
                                            : 'Stok: ${product['stock']}',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: isOutOfStock
                                              ? Colors.red
                                              : Colors.green,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
