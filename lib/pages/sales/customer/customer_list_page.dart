import 'package:flutter/material.dart';
import 'package:pintarx/config/theme.dart';

class CustomerListPage extends StatefulWidget {
  const CustomerListPage({super.key});

  static final List<Map<String, dynamic>> _demoCustomers = [
    {
      'id': 1,
      'name': 'PT Maju Jaya',
      'email': 'info@majujaya.com',
      'phone': '+62 812-3456-7890',
      'city': 'Jakarta',
      'address': 'Jl. Merdeka No. 45, Jakarta',
      'type': 'Perusahaan',
    },
    {
      'id': 2,
      'name': 'CV Sumber Makmur',
      'email': 'cs@sumbermakmur.co.id',
      'phone': '+62 813-9876-5432',
      'city': 'Bandung',
      'address': 'Jl. Sudirman No. 78, Bandung',
      'type': 'CV',
    },
    {
      'id': 3,
      'name': 'UD Berkah Jaya',
      'email': 'berkah@mail.com',
      'phone': '+62 811-2233-4455',
      'city': 'Bekasi',
      'address': 'Jl. Veteran No. 12, Bekasi',
      'type': 'UD',
    },
    {
      'id': 4,
      'name': 'PT Agro Mandiri',
      'email': 'agro@mandiri.com',
      'phone': '+62 816-7788-9900',
      'city': 'Surabaya',
      'address': 'Jl. Delima No. 22, Surabaya',
      'type': 'Perusahaan',
    },
    {
      'id': 5,
      'name': 'Toko Jaya Sentosa',
      'email': 'toko@jayasentosa.com',
      'phone': '+62 817-1122-3344',
      'city': 'Medan',
      'address': 'Jl. Ahmad Yani No. 15, Medan',
      'type': 'Toko',
    },
    {
      'id': 6,
      'name': 'PT Dinamis Sejahtera',
      'email': 'dinamis@sejahtera.id',
      'phone': '+62 818-5566-7788',
      'city': 'Semarang',
      'address': 'Jl. Gatot Subroto No. 88, Semarang',
      'type': 'Perusahaan',
    },
  ];

  @override
  State<CustomerListPage> createState() => _CustomerListPageState();
}

class _CustomerListPageState extends State<CustomerListPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  List<Map<String, dynamic>> get _filteredCustomers {
    final query = _searchQuery.trim().toLowerCase();
    List<Map<String, dynamic>> filtered = CustomerListPage._demoCustomers;

    // Filter by search query
    if (query.isNotEmpty) {
      filtered = filtered.where((customer) {
        return (customer['name'] as String).toLowerCase().contains(query) ||
            (customer['phone'] as String).toLowerCase().contains(query) ||
            (customer['city'] as String).toLowerCase().contains(query);
      }).toList();
    }

    return filtered;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final customers = _filteredCustomers;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Daftar Customer',
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
                hintText: 'Cari customer atau kota...',
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

            // Customer List
            Expanded(
              child: customers.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.people_outline,
                              size: 64, color: Colors.grey[300]),
                          const SizedBox(height: 16),
                          Text(
                            'Tidak ada customer',
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
                      itemCount: customers.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final customer = customers[index];

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
                                // Header: Name & Phone
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        customer['name'] as String,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.black87,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryColor
                                            .withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(Icons.phone_rounded,
                                              size: 12,
                                              color: AppTheme.primaryColor),
                                          const SizedBox(width: 4),
                                          Text(
                                            customer['phone'] as String,
                                            style: const TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                              color: AppTheme.primaryColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),

                                // Type & Address
                                Row(
                                  children: [
                                    Icon(Icons.location_on_rounded,
                                        size: 14, color: AppTheme.primaryColor),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        '${customer['city']}, ${customer['address']}',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.grey[600],
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
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
