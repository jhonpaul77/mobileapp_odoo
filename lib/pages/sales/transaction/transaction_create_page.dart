import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';

import '../../../config/api_config.dart';
import '../../../features/customer/data/datasources/customer_remote_datasource.dart';
import '../../../features/sales_order/domain/entities/order_line.dart';
import '../../../features/sales_order/domain/entities/sales_order.dart';
import '../../../features/sales_order/presentation/pages/sales_order_detail_page.dart';
import '../../../services/api_service.dart';
import '../../../services/config_service.dart';
import '../../../services/sales_service.dart';
import '../../../services/secure_storage_service.dart';
import '../../../services/secure_storage_service.dart';

/// Create Sales Order Page
///
/// Halaman untuk membuat Sales Order baru dengan API Odoo yang baru.
///
/// Simplified flow: Customer → Products → Submit
///
/// Features:
/// - Customer selection with search
/// - Multiple order lines
/// - Auto date order (today)
/// - Analytic account selection per line
/// - Editable price per line
/// - Save Draft → Confirm Order flow
///
/// API Endpoint: POST /create_sale_order, PUT /confirm_order
class TransactionCreatePage extends StatefulWidget {
  const TransactionCreatePage({super.key});

  @override
  State<TransactionCreatePage> createState() => _TransactionCreatePageState();
}

/// Formatter untuk price input dengan thousands separator
class _ThousandsSeparatorInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // Remove all non-digit characters
    final digitsOnly = newValue.text.replaceAll(RegExp(r'[^\d]'), '');

    if (digitsOnly.isEmpty) {
      return const TextEditingValue(text: '');
    }

    // Format with thousands separator
    final number = int.parse(digitsOnly);
    final formatted = _formatWithThousandsSeparator(number);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  String _formatWithThousandsSeparator(int number) {
    final str = number.toString();
    final parts = str.split('').reversed.toList();
    final List<String> formatted = [];

    for (var i = 0; i < parts.length; i++) {
      if (i > 0 && i % 3 == 0) {
        formatted.add('.');
      }
      formatted.add(parts[i]);
    }

    return formatted.reversed.join('');
  }
}

class _TransactionCreatePageState extends State<TransactionCreatePage> {
  final _formKey = GlobalKey<FormState>();
  final _salesService = SalesService();
  final logger = Logger();

  // Form Controllers
  final _notesController = TextEditingController();

  // Form State - simplified
  List<Map<String, dynamic>> _orderLines = [];

  // Customer selection
  Map<String, dynamic>? _selectedCustomer;

  // Data Lists
  List<dynamic> _customers = [];
  List<dynamic> _products = [];
  List<dynamic> _analyticAccounts = []; // NEW: Analytic accounts

  // Loading States
  bool _isLoading = false;
  bool _isLoadingCustomers = true;
  bool _isLoadingProducts = true;
  bool _isLoadingAnalytics = true; // NEW: Loading state for analytics

  // Order State - for Save → Confirm flow
  int? _createdOrderId; // NEW: Store created order ID
  String? _createdOrderName; // NEW: Store created order name
  bool _isOrderSaved = false; // NEW: Track if order is saved
  bool _isConfirming = false; // NEW: Loading state for confirm action

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    // Add initial empty order line using postFrameCallback to avoid context error
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _orderLines.add({
            'product_id': null,
            'product_name': '',
            'product_uom_qty': 1.0,
            'analytic_distribution': false,
            'analytic_account_id': null, // NEW: Analytic account ID
            'analytic_account_name': '', // NEW: Analytic account name
            'price_unit': 0.0,
          });
        });
      }
    });
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    await Future.wait([
      _loadCustomers(),
      _loadProducts(),
      _loadAnalyticAccounts(), // NEW: Load analytic accounts
    ]);
  }

  Future<void> _loadCustomers() async {
    setState(() {
      _isLoadingCustomers = true;
    });

    try {
      logger.i('� [LOAD_CUSTOMERS] Starting to load customers...');

      // Import yang diperlukan sudah ada di top file
      final secureStorage = SecureStorageService();
      final configService = ConfigService();

      // Get database from config
      final config = await configService.load();
      final database = config['database'] as String?;

      // Get API key from secure storage
      final apiKey = await secureStorage.getAccessToken();

      logger.i('   Database: $database');
      logger.i('   API Key exists: ${apiKey != null}');

      // Validate authentication
      if (database == null || database.isEmpty) {
        throw Exception(
            'Database not configured. Please logout and configure server settings.');
      }

      if (apiKey == null || apiKey.isEmpty) {
        throw Exception('Not authenticated. Please login first.');
      }

      // Use Clean Architecture approach like Customer List Page
      final datasource = CustomerRemoteDataSource();
      final customerModels = await datasource.getCustomers(
        db: database,
        apiKey: apiKey,
      );

      logger.i(
          '✅ [LOAD_CUSTOMERS] API SUCCESS: ${customerModels.length} customers');

      if (customerModels.isNotEmpty) {
        // Get raw API response to preserve location names [id, name] format
        final dio = ApiService().dio;

        try {
          final rawResponse = await dio.get(
            ApiConfig.getCustomer,
            options: Options(
              headers: {
                'db': database,
                'api-key': apiKey,
              },
            ),
          );

          final rawCustomers = rawResponse.data as List;

          // Convert to Map format for dropdown with location names preserved
          final customerList = rawCustomers.map((raw) {
            return {
              'id': raw['id'],
              'name': raw['name'],
              'phone': raw['phone'],
              'street': raw['street'],
              'street2': raw['street2'],
              // Preserve raw format [id, name] for location fields
              'district_id': raw['district_id'],
              'city_id': raw['city_id'],
              'state_id': raw['state_id'],
              'zip': raw['zip'],
              'email': raw['email'],
            };
          }).toList();

          setState(() {
            _customers = customerList;
            _isLoadingCustomers = false;
          });

          // Debug: Print first 3 customers
          for (var i = 0;
              i < (customerList.length > 3 ? 3 : customerList.length);
              i++) {
            logger.i(
                '   Customer ${i + 1}: ${customerList[i]['name']} (ID: ${customerList[i]['id']})');
          }
        } catch (e) {
          // Fallback: if raw response fails, use models without location names
          logger.w(
              '⚠️ [LOAD_CUSTOMERS] Could not get raw response, using models: $e');

          final customerList = customerModels.map((model) {
            return {
              'id': model.id,
              'name': model.name,
              'phone': model.phone,
              'street': model.street,
              'street2': model.street2,
              'district_id': model.districtId,
              'city_id': model.cityId,
              'state_id': model.stateId,
              'zip': model.zip,
              'email': model.email,
            };
          }).toList();

          setState(() {
            _customers = customerList;
            _isLoadingCustomers = false;
          });
        }

        // Show success message
        // if (mounted) {
        //   ScaffoldMessenger.of(context).showSnackBar(
        //     SnackBar(
        //       content:
        //           Text('✅ Loaded ${customerList.length} customers from API'),
        //       backgroundColor: Colors.green,
        //       duration: const Duration(seconds: 2),
        //     ),
        //   );
        // }
      } else {
        // API returned empty array
        // logger.w('⚠️ [LOAD_CUSTOMERS] API returned empty customer list');

        setState(() {
          _customers = [];
          _isLoadingCustomers = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('⚠️ No customers found in database'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e, stackTrace) {
      logger.e('❌ [LOAD_CUSTOMERS] Error loading customers', error: e);
      logger.e('   Stack trace: $stackTrace');

      setState(() {
        _customers = [];
        _isLoadingCustomers = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoadingProducts = true;
    });

    try {
      logger.i('📦 [LOAD_PRODUCTS] Starting to load products...');

      // Import yang diperlukan sudah ada di top file
      final secureStorage = SecureStorageService();
      final configService = ConfigService();

      // Get database from config
      final config = await configService.load();
      final database = config['database'] as String?;

      // Get API key from secure storage
      final apiKey = await secureStorage.getAccessToken();

      logger.i('   Database: $database');
      logger.i('   API Key exists: ${apiKey != null}');

      // Validate authentication
      if (database == null || database.isEmpty) {
        throw Exception(
            'Database not configured. Please logout and configure server settings.');
      }

      if (apiKey == null || apiKey.isEmpty) {
        throw Exception('Not authenticated. Please login first.');
      }

      // Use API service directly to get all product fields (qty_available, etc)
      final dio = ApiService().dio;
      final response = await dio.get(
        ApiConfig.getProductSale,
        options: Options(
          headers: {
            'db': database,
            'api-key': apiKey,
          },
        ),
      );

      logger.i('✅ [LOAD_PRODUCTS] Response status: ${response.statusCode}');
      logger.i('   Response type: ${response.data.runtimeType}');

      // Parse response - bisa berupa List langsung atau String JSON
      List<dynamic> productList;

      if (response.data is String) {
        // Response is JSON string, need to parse
        logger.i('   Parsing JSON string response...');
        final parsed = json.decode(response.data);
        productList = parsed as List;
      } else if (response.data is List) {
        // Response is already List
        productList = response.data as List;
      } else {
        throw Exception(
            'Unexpected response type: ${response.data.runtimeType}');
      }

      logger.i('✅ [LOAD_PRODUCTS] API SUCCESS: ${productList.length} products');

      if (productList.isNotEmpty) {
        setState(() {
          _products = productList;
          _isLoadingProducts = false;
        });

        // Debug: Print first 3 products
        for (var i = 0;
            i < (productList.length > 3 ? 3 : productList.length);
            i++) {
          logger.i(
              '   Product ${i + 1}: ${productList[i]['name']} (ID: ${productList[i]['id']})');
        }
      } else {
        // API returned empty array
        logger.w('⚠️ [LOAD_PRODUCTS] API returned empty product list');

        setState(() {
          _products = [];
          _isLoadingProducts = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('⚠️ No products found in database'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e, stackTrace) {
      logger.e('❌ [LOAD_PRODUCTS] Error loading products', error: e);
      logger.e('   Stack trace: $stackTrace');

      setState(() {
        _products = [];
        _isLoadingProducts = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<void> _loadAnalyticAccounts() async {
    setState(() {
      _isLoadingAnalytics = true;
    });

    try {
      logger.i('📊 [LOAD_ANALYTICS] Starting to load analytic accounts...');

      final secureStorage = SecureStorageService();
      final configService = ConfigService();

      final config = await configService.load();
      final database = config['database'] as String?;
      final apiKey = await secureStorage.getAccessToken();

      logger.i('   Database: $database');
      logger.i('   API Key exists: ${apiKey != null}');

      if (database == null || database.isEmpty) {
        throw Exception(
            'Database not configured. Please logout and configure server settings.');
      }

      if (apiKey == null || apiKey.isEmpty) {
        throw Exception('Not authenticated. Please login first.');
      }

      final dio = ApiService().dio;
      final response = await dio.get(
        ApiConfig.getAnalytic,
        options: Options(
          headers: {
            'db': database,
            'api-key': apiKey,
          },
        ),
      );

      logger.i('✅ [LOAD_ANALYTICS] Response status: ${response.statusCode}');

      List<dynamic> analyticList;
      if (response.data is String) {
        final parsed = json.decode(response.data);
        analyticList = parsed as List;
      } else if (response.data is List) {
        analyticList = response.data as List;
      } else {
        throw Exception(
            'Unexpected response type: ${response.data.runtimeType}');
      }

      logger
          .i('✅ [LOAD_ANALYTICS] API SUCCESS: ${analyticList.length} accounts');

      setState(() {
        _analyticAccounts = analyticList;
        _isLoadingAnalytics = false;
      });

      if (analyticList.isNotEmpty) {
        for (var i = 0;
            i < (analyticList.length > 3 ? 3 : analyticList.length);
            i++) {
          logger.i(
              '   Analytic ${i + 1}: ${analyticList[i]['name']} (ID: ${analyticList[i]['id']})');
        }
      }
    } catch (e, stackTrace) {
      logger.e('❌ [LOAD_ANALYTICS] Error loading analytic accounts', error: e);
      logger.e('   Stack trace: $stackTrace');

      setState(() {
        _analyticAccounts = [];
        _isLoadingAnalytics = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error loading analytics: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  void _addNewOrderLine() {
    // Validasi 1: Customer harus dipilih dulu
    if (_selectedCustomer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Pilih customer terlebih dahulu'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // Validasi 2: cek apakah baris terakhir sudah diisi
    if (_orderLines.isNotEmpty) {
      final lastLine = _orderLines.last;

      // Cek apakah produk sudah dipilih
      if (lastLine['product_id'] == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                '⚠️ Pilih produk terlebih dahulu sebelum menambah baris baru'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }

      // Cek apakah qty sudah diisi (> 0)
      if (lastLine['product_uom_qty'] <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ Jumlah produk harus lebih dari 0'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }
    }

    // Validasi passed, tambah baris baru
    setState(() {
      _orderLines.add({
        'product_id': null,
        'product_name': '',
        'product_uom_qty': 1.0,
        'analytic_distribution': false,
        'analytic_account_id': null, // NEW: Analytic account ID
        'analytic_account_name': '', // NEW: Analytic account name
        'price_unit': 0.0,
      });
    });
  }

  /// Show custom search dialog for analytic account selection
  Future<Map<String, dynamic>?> _showAnalyticAccountSearchDialog() async {
    if (_isLoadingAnalytics) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Analytic accounts masih loading, mohon tunggu...'),
          backgroundColor: Colors.orange,
        ),
      );
      return null;
    }

    if (_analyticAccounts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tidak ada analytic account tersedia'),
          backgroundColor: Colors.red,
        ),
      );
      return null;
    }

    String searchQuery = '';
    List<dynamic> filteredAccounts = _analyticAccounts;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Cari Analytic Account'),
              contentPadding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              content: SizedBox(
                width: double.maxFinite,
                height: MediaQuery.of(context).size.height * 0.6,
                child: Column(
                  children: [
                    // Search TextField
                    TextField(
                      autofocus: true,
                      decoration: const InputDecoration(
                        hintText: 'Ketik nama analytic account...',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                      onChanged: (value) {
                        setDialogState(() {
                          searchQuery = value.toLowerCase();
                          filteredAccounts = _analyticAccounts.where((account) {
                            final name = (account['name'] ?? '')
                                .toString()
                                .toLowerCase();
                            return name.contains(searchQuery);
                          }).toList();
                        });
                      },
                    ),
                    const SizedBox(height: 12),

                    // Analytic Account List
                    Expanded(
                      child: filteredAccounts.isEmpty
                          ? const Center(
                              child: Text(
                                'Tidak ada analytic account ditemukan',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey,
                                ),
                              ),
                            )
                          : ListView.builder(
                              padding: EdgeInsets.zero,
                              itemCount: filteredAccounts.length,
                              itemBuilder: (context, index) {
                                final account = filteredAccounts[index];

                                return InkWell(
                                  onTap: () {
                                    Navigator.pop(dialogContext, account);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      border: Border(
                                        bottom: BorderSide(
                                          color: Colors.grey.shade200,
                                          width: 0.5,
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        // Analytic Icon
                                        CircleAvatar(
                                          radius: 16,
                                          backgroundColor:
                                              const Color(0xFF10B981)
                                                  .withValues(alpha: 0.1),
                                          child: const Icon(
                                            Icons.analytics_outlined,
                                            size: 16,
                                            color: Color(0xFF10B981),
                                          ),
                                        ),
                                        const SizedBox(width: 10),

                                        // Analytic Info
                                        Expanded(
                                          child: Text(
                                            account['name'] ?? '',
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),

                                        // Arrow Icon
                                        Icon(
                                          Icons.arrow_forward_ios,
                                          size: 12,
                                          color: Colors.grey.shade400,
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
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Batal'),
                ),
              ],
            );
          },
        );
      },
    );

    return result;
  }

  /// Show custom search dialog for product selection (used in order line)
  Future<Map<String, dynamic>?> _showProductSearchDialog() async {
    if (_isLoadingProducts) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Products masih loading, mohon tunggu...'),
          backgroundColor: Colors.orange,
        ),
      );
      return null;
    }

    if (_products.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tidak ada produk tersedia'),
          backgroundColor: Colors.red,
        ),
      );
      return null;
    }

    String searchQuery = '';
    List<dynamic> filteredProducts = _products;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Cari Produk'),
              contentPadding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              content: SizedBox(
                width: double.maxFinite,
                height: MediaQuery.of(context).size.height * 0.7,
                child: Column(
                  children: [
                    // Search TextField
                    TextField(
                      autofocus: true,
                      decoration: const InputDecoration(
                        hintText: 'Ketik nama produk atau kode...',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                      onChanged: (value) {
                        setDialogState(() {
                          searchQuery = value.toLowerCase();
                          filteredProducts = _products.where((product) {
                            final name = (product['name'] ?? '')
                                .toString()
                                .toLowerCase();
                            final code = (product['default_code'] ?? '')
                                .toString()
                                .toLowerCase();
                            return name.contains(searchQuery) ||
                                code.contains(searchQuery);
                          }).toList();
                        });
                      },
                    ),
                    const SizedBox(height: 12),

                    // Product List
                    Expanded(
                      child: filteredProducts.isEmpty
                          ? const Center(
                              child: Text(
                                'Tidak ada produk ditemukan',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey,
                                ),
                              ),
                            )
                          : ListView.builder(
                              padding: EdgeInsets.zero,
                              itemCount: filteredProducts.length,
                              itemBuilder: (context, index) {
                                final product = filteredProducts[index];
                                final price = product['list_price'] ?? 0.0;
                                final stock = product['qty_available'] ?? 0.0;
                                final code = product['default_code'];

                                return InkWell(
                                  onTap: () {
                                    Navigator.pop(dialogContext, product);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      border: Border(
                                        bottom: BorderSide(
                                          color: Colors.grey.shade200,
                                          width: 0.5,
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        // Product Icon
                                        CircleAvatar(
                                          radius: 16,
                                          backgroundColor:
                                              const Color(0xFF10B981)
                                                  .withValues(alpha: 0.1),
                                          child: const Icon(
                                            Icons.inventory_2,
                                            size: 16,
                                            color: Color(0xFF10B981),
                                          ),
                                        ),
                                        const SizedBox(width: 10),

                                        // Product Info
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                product['name'] ?? '',
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 2),
                                              Row(
                                                children: [
                                                  if (code != null &&
                                                      code != false)
                                                    Container(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                        horizontal: 6,
                                                        vertical: 2,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color:
                                                            Colors.blue.shade50,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(4),
                                                      ),
                                                      child: Text(
                                                        code.toString(),
                                                        style: TextStyle(
                                                          fontSize: 10,
                                                          color: Colors
                                                              .blue.shade700,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                        ),
                                                      ),
                                                    ),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    'Rp ${_formatCurrency(price)}',
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      color:
                                                          Colors.green.shade700,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                  const Spacer(),
                                                  Text(
                                                    'Stock: ${stock.toStringAsFixed(0)}',
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      color:
                                                          Colors.grey.shade600,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),

                                        // Arrow Icon
                                        Icon(
                                          Icons.arrow_forward_ios,
                                          size: 12,
                                          color: Colors.grey.shade400,
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
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Batal'),
                ),
              ],
            );
          },
        );
      },
    );

    return result;
  }

  void _removeOrderLine(int index) {
    setState(() {
      _orderLines.removeAt(index);
    });
  }

  void _updateOrderLine(int index, String field, dynamic value) {
    setState(() {
      _orderLines[index][field] = value;
    });
  }

  String _formatDateForOdoo(DateTime date) {
    // Format: YYYY-MM-DD HH:MM:SS (Odoo format with time)
    final year = date.year;
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    final second = date.second.toString().padLeft(2, '0');
    return '$year-$month-$day $hour:$minute:$second';
  }

  String _formatCurrency(double amount) {
    // Format currency dengan separator ribuan (titik)
    // Example: 1000 → "1.000", 50000 → "50.000", 1250000 → "1.250.000"
    final intAmount = amount.toInt();
    final parts = intAmount.toString().split('');
    final reversed = parts.reversed.toList();
    final List<String> formatted = [];

    for (var i = 0; i < reversed.length; i++) {
      if (i > 0 && i % 3 == 0) {
        formatted.add('.');
      }
      formatted.add(reversed[i]);
    }

    return formatted.reversed.join('');
  }

  /// Extract location name from Odoo location field
  ///
  /// Odoo returns location fields in format: [id, name]
  /// Example: [623, "Jawa Timur"]
  ///
  /// Returns:
  /// - name (String) if input is List with 2 elements
  /// - empty string if input is null, false, or invalid
  String _extractLocationName(dynamic locationField) {
    if (locationField == null || locationField == false) {
      return '';
    }

    // If it's a List (expected format: [id, name])
    if (locationField is List) {
      if (locationField.isEmpty) return '';
      if (locationField.length == 1) {
        // Only ID, no name - return empty
        return '';
      }
      // Return name (index 1), safely convert to String
      return locationField[1]?.toString() ?? '';
    }

    // If it's already a String (fallback case)
    if (locationField is String) {
      return locationField;
    }

    // If it's an int (only ID provided)
    if (locationField is int) {
      return ''; // Can't resolve ID to name without lookup
    }

    // Unknown format
    logger
        .w('⚠️ Unexpected location field format: ${locationField.runtimeType}');
    return '';
  }

  double _calculateTotal() {
    return _orderLines.fold(0.0, (sum, line) {
      return sum + (line['product_uom_qty'] * line['price_unit']);
    });
  }

  /// Show custom search dialog for customer selection
  Future<void> _showCustomerSearchDialog() async {
    String searchQuery = '';
    List<Map<String, dynamic>> filteredCustomers =
        _customers.cast<Map<String, dynamic>>();

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Cari Customer'),
              contentPadding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              content: SizedBox(
                width: double.maxFinite,
                height: MediaQuery.of(context).size.height * 0.6,
                child: Column(
                  children: [
                    // Search TextField
                    TextField(
                      autofocus: true,
                      decoration: const InputDecoration(
                        hintText: 'Ketik nama customer...',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                      onChanged: (value) {
                        setDialogState(() {
                          searchQuery = value.toLowerCase();
                          filteredCustomers = _customers
                              .where((customer) {
                                final name = (customer['name'] ?? '')
                                    .toString()
                                    .toLowerCase();
                                final phone = (customer['phone'] ?? '')
                                    .toString()
                                    .toLowerCase();
                                return name.contains(searchQuery) ||
                                    phone.contains(searchQuery);
                              })
                              .toList()
                              .cast<Map<String, dynamic>>();
                        });
                      },
                    ),
                    const SizedBox(height: 12),

                    // Customer List
                    Expanded(
                      child: filteredCustomers.isEmpty
                          ? const Center(
                              child: Text(
                                'Tidak ada customer ditemukan',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey,
                                ),
                              ),
                            )
                          : ListView.builder(
                              padding: EdgeInsets.zero,
                              itemCount: filteredCustomers.length,
                              itemBuilder: (context, index) {
                                final customer = filteredCustomers[index];
                                return InkWell(
                                  onTap: () {
                                    Navigator.pop(dialogContext, customer);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      border: Border(
                                        bottom: BorderSide(
                                          color: Colors.grey.shade200,
                                          width: 0.5,
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        // Avatar
                                        CircleAvatar(
                                          radius: 16,
                                          backgroundColor:
                                              const Color(0xFF0A64AF)
                                                  .withValues(alpha: 0.1),
                                          child: const Icon(
                                            Icons.person,
                                            size: 16,
                                            color: Color(0xFF0A64AF),
                                          ),
                                        ),
                                        const SizedBox(width: 10),

                                        // Customer Info
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                customer['name'] ?? '',
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                customer['phone'] ?? '-',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.grey.shade600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),

                                        // Arrow Icon
                                        Icon(
                                          Icons.arrow_forward_ios,
                                          size: 12,
                                          color: Colors.grey.shade400,
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
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Batal'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null) {
      setState(() {
        _selectedCustomer = result;
      });
      logger.i('Selected customer: ${result['name']}');
    }
  }

  Future<void> _saveDraft() async {
    // Rename from _submitOrder, sekarang hanya save draft (tidak navigate away)

    // POIN 2: Validasi form, customer, dan product lines
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Mohon lengkapi form yang required'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Validasi customer harus dipilih
    if (_selectedCustomer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Customer harus dipilih'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Validasi minimal 1 produk
    if (_orderLines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Minimal 1 produk harus ditambahkan'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Validasi semua order lines harus terisi product_id dan qty
    for (var i = 0; i < _orderLines.length; i++) {
      final line = _orderLines[i];

      // Cek product_id
      if (line['product_id'] == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⚠️ Produk ${i + 1} belum dipilih'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Cek qty harus > 0
      if (line['product_uom_qty'] == null || line['product_uom_qty'] <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⚠️ Jumlah produk ${i + 1} harus lebih dari 0'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Cek analytic account mandatory
      if (line['analytic_distribution'] == null || 
          line['analytic_distribution'] == false || 
          (line['analytic_distribution'] is String && line['analytic_distribution'].isEmpty)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⚠️ Analytic Account produk ${i + 1} harus dipilih'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Cek price harus > 0
      if (line['price_unit'] == null || line['price_unit'] <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⚠️ Harga produk ${i + 1} harus lebih dari 0'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      logger.i('📦 [SAVE_DRAFT] Creating sales order (draft)...');

      // POIN 3: Extract customer data
      final customerName = _selectedCustomer!['name'] ?? '';
      final customerPhone = _selectedCustomer!['phone'] ?? '';
      final customerStreet = _selectedCustomer!['street'] ?? '';
      final customerStreet2 = _selectedCustomer!['street2'] ?? '';

      // Extract location info from customer
      String customerState = '';
      String customerCity = '';
      String customerDistrict = '';

      try {
        customerState = _extractLocationName(_selectedCustomer!['state_id']);
      } catch (e) {
        logger.e('❌ Error extracting state: $e');
        customerState = '';
      }

      try {
        customerCity = _extractLocationName(_selectedCustomer!['city_id']);
      } catch (e) {
        logger.e('❌ Error extracting city: $e');
        customerCity = '';
      }

      try {
        customerDistrict =
            _extractLocationName(_selectedCustomer!['district_id']);
      } catch (e) {
        logger.e('❌ Error extracting district: $e');
        customerDistrict = '';
      }

      logger.i('   Customer: $customerName');
      logger.i('   Phone: $customerPhone');
      logger.i('   State: $customerState');
      logger.i('   City: $customerCity');
      logger.i('   District: $customerDistrict');
      logger.i('   Products: ${_orderLines.length}');

      // Get current user & API key for logging
      final storage = SecureStorageService();
      final currentUser = await storage.getUserData();
      final currentApiKey = await storage.getAccessToken();
      
      logger.i('🔐 [SAVE_DRAFT] Current User: ${currentUser?['username']}');
      logger.i('🔐 [SAVE_DRAFT] API Key: ${currentApiKey?.substring(0, 12)}...');

      // POIN 4: Call API - always save as DRAFT
      final result = await _salesService.createSaleOrder(
        partnerName: customerName,
        partnerPhone: customerPhone,
        partnerStreet: customerStreet,
        partnerStreet2: customerStreet2.isNotEmpty ? customerStreet2 : null,
        partnerDistrict: customerDistrict,
        partnerCity: customerCity,
        partnerState: customerState,
        dateOrder: _formatDateForOdoo(DateTime.now()),
        warehouseId: 1,
        kurirId: null,
        awb: null,
        notes:
            _notesController.text.isEmpty ? null : _notesController.text.trim(),
        state: 'draft', // Always draft when created
        orderLines: _orderLines
            .map((line) => {
                  'product_id': line['product_id'],
                  'product_uom_qty': line['product_uom_qty'],
                  'analytic_distribution': line['analytic_distribution'],
                  'price_unit': line['price_unit'],
                })
            .toList(),
      );

      if (!mounted) return;

      setState(() => _isLoading = false);

      if (result['Success'] == true) {
        // ✅ Get current user info for comprehensive logging
        final storage = SecureStorageService();
        final currentUser = await storage.getUserData();
        final currentApiKey = await storage.getAccessToken();
        final currentDb = await ConfigService().getDatabase();
        final currentUrl = await ConfigService().getUrl();
        
        final username = currentUser?['username'] ?? 'Unknown';
        final apiKeyShort = currentApiKey?.substring(0, 12) ?? 'NOT SET';
        
        logger.i('═════════════════════════════════════════════════════════════');
        logger.i('✅ [CREATE_SO_SUCCESS] Sales Order Created Successfully');
        logger.i('═════════════════════════════════════════════════════════════');
        logger.i('');
        logger.i('📋 REQUEST INFO:');
        logger.i('   User: $username');
        logger.i('   API Key: $apiKeyShort...');
        logger.i('   Database: $currentDb');
        logger.i('   Server URL: $currentUrl');
        logger.i('   Timestamp: ${DateTime.now().toIso8601String()}');
        logger.i('');
        logger.i('📊 RESPONSE DATA:');
        logger.i('   Full result: $result');
        logger.i('   Result type: ${result.runtimeType}');
        logger.i('   Data key exists: ${result.containsKey('Data')}');
        logger.i('   Response Data: ${result['Data']}');
        logger.i('   Response Data type: ${result['Data']?.runtimeType}');

        // Extract order ID and name from response
        final orderData = result['Data'];

        // Safety check for orderData type
        if (orderData == null) {
          throw Exception('Response Data is null');
        }

        logger.i('');
        logger.i('📦 ORDER DATA:');
        logger.i('   Order Data type: ${orderData.runtimeType}');
        logger.i('   Order Data: $orderData');

        try {
          // Extract ID - handle both int and String
          final dynamic rawId = orderData['id'];
          if (rawId is int) {
            _createdOrderId = rawId;
          } else if (rawId is String) {
            _createdOrderId = int.tryParse(rawId) ?? 0;
          } else {
            logger.e('   Unexpected ID type: ${rawId.runtimeType}');
            _createdOrderId = 0;
          }

          _createdOrderName =
              orderData['name']?.toString() ?? 'SO-$_createdOrderId';

          logger.i('   Order ID: $_createdOrderId');
          logger.i('   Order Name: $_createdOrderName');
          logger.i('');
          logger.i('✅ SUCCESS SUMMARY:');
          logger.i('   ├─ Sales Order: $_createdOrderName');
          logger.i('   ├─ Order ID: $_createdOrderId');
          logger.i('   ├─ Created By: $username');
          logger.i('   ├─ Database: $currentDb');
          logger.i('   └─ Time: ${DateTime.now().toIso8601String()}');
          logger.i('═════════════════════════════════════════════════════════════');
        } catch (e, stackTrace) {
          logger.e('   Error extracting order data: $e');
          logger.e('   Stack trace: $stackTrace');

          // Fallback: try to extract from different response format
          if (orderData is Map) {
            logger.i('   Trying alternative extraction...');
            _createdOrderId = 0;
            _createdOrderName = 'SO-Unknown';
          } else {
            throw Exception(
                'Invalid order data format: ${orderData.runtimeType}');
          }
        }

        setState(() {
          _isOrderSaved = true; // Track that order is saved
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Transaksi tersimpan: $_createdOrderName'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 1),
          ),
        );

        // Navigate to detail page
        if (mounted && _createdOrderId != null) {
          // Extract date_order dari response backend
          final dateOrderFromBackend = orderData['date_order']?.toString() ?? 
              DateTime.now().toIso8601String();

          // Wait a bit for snackbar
          await Future.delayed(const Duration(milliseconds: 300));

          if (mounted) {
            // Create SalesOrder entity for detail page
            final salesOrder = SalesOrder(
              id: _createdOrderId!,
              name: _createdOrderName ?? 'SO-$_createdOrderId',
              partnerId: _selectedCustomer!['id'],
              partnerName: _selectedCustomer!['name'],
              dateOrder: dateOrderFromBackend,
              amountTotal: _calculateTotal(),
              state: 'draft', // Draft state
              warehouseId: 1,
              warehouseName: 'Warehouse',
              kurirId: null,
              kurirName: null,
              awb: null,
              orderCount: _orderLines.length,
              orderLines: _orderLines
                  .map((line) => OrderLine(
                        productId: [line['product_id'], line['product_name']],
                        productName: line['product_name'],
                        productUomQty: line['product_uom_qty'],
                        analyticDistribution: line['analytic_distribution'],
                        priceUnit: line['price_unit'],
                        priceSubtotal:
                            line['product_uom_qty'] * line['price_unit'],
                      ))
                  .toList(),
            );

            // Navigate to detail (replace current page)
            final result = await Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => SalesOrderDetailPage(order: salesOrder),
              ),
            );

            // If returned from detail, go back to list
            if (mounted && result != null) {
              Navigator.pop(context, true);
            }
          }
        }

        // DO NOT show confirm button here - will be shown in detail page
      } else {
        logger.e('❌ [SAVE_DRAFT] Failed: ${result['Message']}');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Gagal: ${result['Message']}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e, stackTrace) {
      setState(() => _isLoading = false);
      logger.e('❌ [SAVE_DRAFT] Unexpected error',
          error: e, stackTrace: stackTrace);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  Future<void> _confirmOrder() async {
    if (_createdOrderId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Order ID tidak ditemukan'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isConfirming = true);

    try {
      logger.i('✅ [CONFIRM] Confirming order #$_createdOrderId...');

      final result =
          await _salesService.confirmOrder(orderId: _createdOrderId!);

      if (!mounted) return;

      setState(() => _isConfirming = false);

      if (result['Success'] == true) {
        logger.i('✅ [CONFIRM] Order confirmed successfully');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Order $_createdOrderName dikonfirmasi'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );

        // NOW navigate back with refresh flag
        Navigator.pop(context, true);
      } else {
        logger.e('❌ [CONFIRM] Failed: ${result['Message']}');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Gagal konfirmasi: ${result['Message']}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e, stackTrace) {
      setState(() => _isConfirming = false);
      logger.e('❌ [CONFIRM] Unexpected error',
          error: e, stackTrace: stackTrace);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Debug state
    logger.d('🎨 [BUILD] TransactionCreatePage');
    logger.d('   _isLoadingCustomers: $_isLoadingCustomers');
    logger.d('   _customers.length: ${_customers.length}');
    logger.d('   _selectedCustomer: $_selectedCustomer');
    logger.d('   _isLoadingProducts: $_isLoadingProducts');
    logger.d('   _products.length: ${_products.length}');
    logger.d('   _orderLines.length: ${_orderLines.length}');

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Transaksi Baru'),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarIconBrightness: theme.brightness == Brightness.dark
              ? Brightness.light
              : Brightness.dark,
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Customer Information Section
            _buildSectionTitle(theme, 'Informasi Customer'),
            _buildCustomerSection(theme),

            const SizedBox(height: 24),

            // Order Lines Section
            _buildSectionTitle(theme, 'Daftar Produk'),
            _buildOrderLinesSection(theme),

            const SizedBox(height: 8),

            // Add Product Button
            OutlinedButton.icon(
              onPressed: _addNewOrderLine,
              icon: const Icon(Icons.add_shopping_cart, size: 18),
              label: const Text('Beli Produk Lain'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),

            const SizedBox(height: 10),

            // Total
            _buildTotalCard(theme),

            const SizedBox(height: 10),

            // Submit Button - Changes based on state
            if (!_isOrderSaved) ...[
              // Before save: Show "Simpan Transaksi" button
              ElevatedButton(
                onPressed: _isLoading ? null : _saveDraft,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: const Color(0xFF0A64AF),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Simpan Transaksi',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
              ),
            ] else ...[
              // After save: Show order info and "Konfirmasi Order" button
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade200, width: 2),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.check_circle,
                            color: Colors.green.shade700, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Draft Tersimpan',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.green.shade700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _createdOrderName ?? '-',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.green.shade900,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _isConfirming ? null : _confirmOrder,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: Colors.green.shade700,
                        minimumSize: const Size(double.infinity, 48),
                      ),
                      child: _isConfirming
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Konfirmasi Order',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: theme.textTheme.bodyLarge?.color,
        ),
      ),
    );
  }

  Widget _buildCustomerSection(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.brightness == Brightness.dark
              ? Colors.grey[700]!
              : Colors.grey[200]!,
        ),
      ),
      child: Column(
        children: [
          // Customer Selection with Search Dialog (Custom Implementation)
          InkWell(
            onTap: _isLoadingCustomers || _customers.isEmpty
                ? null
                : _showCustomerSearchDialog,
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: 'Pilih Customer *',
                border: const OutlineInputBorder(),
                prefixIcon: _isLoadingCustomers
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: Padding(
                          padding: EdgeInsets.all(12.0),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : const Icon(Icons.person),
                suffixIcon: _selectedCustomer != null
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              // ANALISA POIN 1: User Friendly - boleh ganti customer meski sudah ada produk
                              // Saat ganti customer, otomatis clear semua produk
                              final hasSelectedProducts = _orderLines
                                  .any((line) => line['product_id'] != null);

                              if (hasSelectedProducts) {
                                // Tampilkan dialog konfirmasi
                                showDialog(
                                  context: context,
                                  builder: (dialogContext) => AlertDialog(
                                    title: const Text('Konfirmasi'),
                                    content: const Text(
                                        'Mengganti customer akan menghapus semua produk yang sudah dipilih. Lanjutkan?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(dialogContext),
                                        child: const Text('Batal'),
                                      ),
                                      ElevatedButton(
                                        onPressed: () {
                                          Navigator.pop(dialogContext);
                                          setState(() {
                                            _selectedCustomer = null;
                                            // Clear semua produk
                                            _orderLines.clear();
                                            // Tambah 1 baris kosong
                                            _orderLines.add({
                                              'product_id': null,
                                              'product_name': '',
                                              'product_uom_qty': 1.0,
                                              'analytic_distribution': false,
                                              'analytic_account_id': null,
                                              'analytic_account_name': '',
                                              'price_unit': 0.0,
                                            });
                                          });
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                        ),
                                        child: const Text(
                                          'Ya, Hapus',
                                          style: TextStyle(color: Colors.white),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                                return;
                              }

                              // Jika tidak ada produk, langsung clear customer
                              setState(() {
                                _selectedCustomer = null;
                              });
                            },
                          ),
                          const Icon(Icons.search, size: 20),
                        ],
                      )
                    : const Icon(Icons.search),
              ),
              child: Text(
                _selectedCustomer != null
                    ? _selectedCustomer!['name'] ?? ''
                    : (_isLoadingCustomers
                        ? 'Memuat...'
                        : 'Tap untuk cari customer'),
                style: TextStyle(
                  color: _selectedCustomer != null
                      ? theme.textTheme.bodyLarge?.color
                      : Colors.grey,
                ),
              ),
            ),
          ),

          // Show customer details if selected
          if (_selectedCustomer != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.brightness == Brightness.dark
                    ? Colors.grey[800]
                    : Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Detail Customer:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: theme.textTheme.bodySmall?.color,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildCustomerInfoRow(
                    Icons.phone,
                    'Phone',
                    _selectedCustomer!['phone'] ?? '-',
                    theme,
                  ),
                  _buildCustomerInfoRow(
                    Icons.location_on,
                    'Alamat',
                    _selectedCustomer!['street'] ?? '-',
                    theme,
                  ),
                  if (_selectedCustomer!['street2'] != null &&
                      _selectedCustomer!['street2'] != '')
                    _buildCustomerInfoRow(
                      Icons.home,
                      'RT/RW',
                      _selectedCustomer!['street2'] ?? '-',
                      theme,
                    ),
                  if (_selectedCustomer!['zip'] != null)
                    _buildCustomerInfoRow(
                      Icons.pin_drop,
                      'Kode Pos',
                      _selectedCustomer!['zip'] ?? '-',
                      theme,
                    ),
                  if (_selectedCustomer!['email'] != null &&
                      _selectedCustomer!['email'] != '')
                    _buildCustomerInfoRow(
                      Icons.email,
                      'Email',
                      _selectedCustomer!['email'] ?? '-',
                      theme,
                    ),
                ],
              ),
            ),
          ],

          // Show warning if no customers loaded
          if (!_isLoadingCustomers && _customers.isEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded,
                      color: Colors.orange.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Tidak ada customer. Pastikan Anda sudah login.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCustomerInfoRow(
      IconData icon, String label, String value, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 14, color: theme.textTheme.bodySmall?.color),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: theme.textTheme.bodySmall?.color,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 11,
                color: theme.textTheme.bodyMedium?.color,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderLinesSection(ThemeData theme) {
    if (_orderLines.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: theme.cardTheme.color,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.brightness == Brightness.dark
                ? Colors.grey[700]!
                : Colors.grey[200]!,
          ),
        ),
        child: Column(
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 8),
            Text(
              'Belum ada produk',
              style: TextStyle(
                color: theme.textTheme.bodySmall?.color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Klik tombol di bawah untuk menambah produk',
              style: TextStyle(
                fontSize: 12,
                color: theme.textTheme.bodySmall?.color,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: _orderLines.asMap().entries.map((entry) {
        final index = entry.key;
        final line = entry.value;

        return _buildOrderLineCard(theme, index, line);
      }).toList(),
    );
  }

  Widget _buildOrderLineCard(
      ThemeData theme, int index, Map<String, dynamic> line) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.brightness == Brightness.dark
              ? Colors.grey[700]!
              : Colors.grey[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Produk ${index + 1}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => _removeOrderLine(index),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Product Selection with Search Dialog (Like Customer)
          InkWell(
            onTap: _isLoadingProducts || _products.isEmpty
                ? null
                : () async {
                    final result = await _showProductSearchDialog();
                    if (result != null) {
                      setState(() {
                        _orderLines[index]['product_id'] = result['id'];
                        _orderLines[index]['product_name'] = result['name'];
                        _orderLines[index]['price_unit'] =
                            result['list_price'] ?? 0.0;
                      });
                    }
                  },
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: 'Pilih Produk *',
                border: const OutlineInputBorder(),
                prefixIcon: _isLoadingProducts
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: Padding(
                          padding: EdgeInsets.all(12.0),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : const Icon(Icons.inventory_2),
                suffixIcon: line['product_id'] != null
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setState(() {
                                _orderLines[index]['product_id'] = null;
                                _orderLines[index]['product_name'] = '';
                                _orderLines[index]['price_unit'] = 0.0;
                              });
                            },
                          ),
                          const Icon(Icons.search, size: 20),
                        ],
                      )
                    : const Icon(Icons.search),
              ),
              child: Text(
                line['product_id'] != null
                    ? line['product_name'] ?? ''
                    : (_isLoadingProducts
                        ? 'Memuat...'
                        : 'Tap untuk cari produk'),
                style: TextStyle(
                  color: line['product_id'] != null
                      ? theme.textTheme.bodyLarge?.color
                      : Colors.grey,
                ),
              ),
            ),
          ),

          // Show product details if selected
          if (line['product_id'] != null) ...[
            const SizedBox(height: 16),

            // Price Input (Editable)
            TextFormField(
              key: ValueKey('price_${line['product_id']}'),
              initialValue: _formatCurrency(line['price_unit']),
              decoration: const InputDecoration(
                labelText: 'Harga Satuan (Rp) *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.payments),
                hintText: 'Contoh: 50.000',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                _ThousandsSeparatorInputFormatter(),
              ],
              onChanged: (value) {
                // Remove dots and parse to double
                final cleanValue = value.replaceAll('.', '');
                final price = double.tryParse(cleanValue) ?? 0.0;
                _updateOrderLine(index, 'price_unit', price);
              },
            ),

            const SizedBox(height: 12),

            // Analytic Account Selection with Search Dialog
            InkWell(
              onTap: _isLoadingAnalytics ||
                      _analyticAccounts.isEmpty ||
                      _isOrderSaved
                  ? null
                  : () async {
                      final result = await _showAnalyticAccountSearchDialog();
                      if (result != null) {
                        setState(() {
                          _orderLines[index]['analytic_account_id'] =
                              result['id'];
                          _orderLines[index]['analytic_account_name'] =
                              result['name'];
                          // Format as required by API
                          _orderLines[index]['analytic_distribution'] =
                              result['name'];
                        });
                      }
                    },
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Analytic Account',
                  border: const OutlineInputBorder(),
                  prefixIcon: _isLoadingAnalytics
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: Padding(
                            padding: EdgeInsets.all(12.0),
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : const Icon(Icons.analytics_outlined),
                  suffixIcon: line['analytic_account_id'] != null
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: _isOrderSaved
                                  ? null
                                  : () {
                                      setState(() {
                                        _orderLines[index]
                                            ['analytic_account_id'] = null;
                                        _orderLines[index]
                                            ['analytic_account_name'] = '';
                                        _orderLines[index]
                                            ['analytic_distribution'] = false;
                                      });
                                    },
                            ),
                            const Icon(Icons.search, size: 20),
                          ],
                        )
                      : const Icon(Icons.search),
                ),
                child: Text(
                  line['analytic_account_id'] != null
                      ? line['analytic_account_name'] ?? ''
                      : (_isLoadingAnalytics
                          ? 'Memuat...'
                          : 'Tap untuk cari (opsional)'),
                  style: TextStyle(
                    color: line['analytic_account_id'] != null
                        ? Theme.of(context).textTheme.bodyLarge?.color
                        : Colors.grey,
                  ),
                ),
              ),
            ),
          ],

          const SizedBox(height: 12),

          // Quantity Input
          TextFormField(
            initialValue: line['product_uom_qty'].toString(),
            decoration: const InputDecoration(
              labelText: 'Jumlah *',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.shopping_basket),
            ),
            keyboardType: TextInputType.number,
            enabled: line['product_id'] != null,
            onChanged: (value) {
              final qty = double.tryParse(value) ?? 1.0;
              _updateOrderLine(index, 'product_uom_qty', qty);
            },
          ),

          // Show subtotal if product selected
          if (line['product_id'] != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0A64AF).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Subtotal:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0A64AF),
                    ),
                  ),
                  Text(
                    'Rp ${_formatCurrency(line['product_uom_qty'] * line['price_unit'])}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0A64AF),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTotalCard(ThemeData theme) {
    final total = _calculateTotal();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0A64AF).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF0A64AF),
          width: 2,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'TOTAL',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0A64AF),
            ),
          ),
          Text(
            'Rp ${_formatCurrency(total)}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0A64AF),
            ),
          ),
        ],
      ),
    );
  }
}
