import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';

import '../../../../config/theme.dart';
import '../../../../services/config_service.dart';
import '../../../../services/local_database/customer_local_database.dart';
import '../../../../services/local_database/location_local_database.dart';
import '../../../../services/local_database/payment_term_local_database.dart';
import '../../../../services/sales_service.dart';
import '../../../../services/secure_storage_service.dart';
import '../../../analytic/presentation/pages/analytic_search_modal.dart';
import '../../../customer/data/datasources/customer_remote_datasource.dart';
import '../../../customer/domain/entities/customer.dart';
import '../../../customer/presentation/pages/customer_search_modal.dart';
import '../../../location/data/datasources/location_remote_datasource.dart';
import '../../../location/domain/entities/district.dart';
import '../../../product/data/datasources/product_remote_datasource.dart';
import '../../../product/data/models/product_model.dart';
import '../../domain/entities/order_line.dart';
import '../../domain/entities/sales_order.dart';
import 'district_search_modal.dart';
import 'product_search_modal.dart';

/// Input formatter untuk menambahkan separator pada angka
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
    final numericOnly = newValue.text.replaceAll(RegExp(r'\D'), '');

    if (numericOnly.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // Add separator
    final parts = <String>[];
    for (int i = numericOnly.length - 1; i >= 0; i--) {
      if ((numericOnly.length - 1 - i) > 0 &&
          (numericOnly.length - 1 - i) % 3 == 0) {
        parts.insert(0, '.');
      }
      parts.insert(0, numericOnly[i]);
    }

    final formatted = parts.join('');

    return newValue.copyWith(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// SalesOrderEditPage - Edit Sales Order
///
/// Allows editing of sales order details and line items
class SalesOrderEditPage extends StatefulWidget {
  final SalesOrder order;

  const SalesOrderEditPage({
    super.key,
    required this.order,
  });

  @override
  State<SalesOrderEditPage> createState() => _SalesOrderEditPageState();
}

class _SalesOrderEditPageState extends State<SalesOrderEditPage> {
  final _salesService = SalesService();
  final logger = Logger();

  late final TextEditingController _customerNameController;
  late final TextEditingController _warehouseNameController;
  late final TextEditingController _kurirNameController;
  late final TextEditingController _awbController;
  late final TextEditingController _addressController;
  late final TextEditingController _districtController;
  late final TextEditingController _cityController;
  late final TextEditingController _stateController;
  late final TextEditingController _notesController;
  late final TextEditingController _paymentTermController;
  late final List<OrderLine> _orderLines;
  late final List<Map<String, TextEditingController>> _lineControllers;
  late List<ProductModel> _allProducts = [];
  late List<District> _allDistricts = [];
  late List<Customer> _allCustomers = [];
  late Map<int, String> _cityMap = {}; // cityId -> cityName
  late Map<int, String> _stateMap = {}; // stateId -> stateName
  late Map<int, int> _cityToStateMap = {}; // cityId -> stateId
  late List<Map<String, dynamic>> _paymentTerms = []; // NEW: Payment terms list
  final _currencyFormat =
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  // State variables
  bool _isLoading = false;
  int? _selectedCustomerId;
  int? _selectedPaymentTermId; // NEW: Selected payment term ID
  bool _orderSavedSuccessfully = false;
  // int? _selectedDistrictId; // Removed: unused field
  // int? _selectedCityId; // Removed: unused field

  // State variables for real-time calculation
  late Map<int, double> _lineSubtotals; // index -> subtotal

  @override
  void initState() {
    super.initState();
    final order = widget.order;

    _customerNameController = TextEditingController(text: order.customerName);
    _addressController =
        TextEditingController(text: order.partnerStreet?.toString() ?? '');
    _districtController =
        TextEditingController(text: order.partnerDistrict?.toString() ?? '');
    _cityController =
        TextEditingController(text: order.partnerCity?.toString() ?? '');
    _stateController =
        TextEditingController(text: order.partnerState?.toString() ?? '');
    _notesController =
        TextEditingController(text: order.notes?.toString() ?? '');
    _warehouseNameController =
        TextEditingController(text: order.warehouseNameDisplay ?? '');
    _kurirNameController =
        TextEditingController(text: order.kurirNameDisplay ?? '');
    _awbController = TextEditingController(text: order.awb?.toString() ?? '');
    _paymentTermController =
        TextEditingController(text: order.paymentTermName?.toString() ?? '');

    // Store IDs for API calls
    _selectedCustomerId = order.partnerId;

    // Initialize payment term selection
    _selectedPaymentTermId = order.paymentTermId;

    _orderLines = order.orderLines
        .map((line) => OrderLine(
              productId: line.productId,
              productName: line.productName, // Keep the product name from API
              productUomQty: line.productUomQty,
              analyticDistribution: line.analyticDistribution,
              priceUnit: line.priceUnit,
              priceSubtotal: line.priceSubtotal,
            ))
        .toList();

    _lineControllers = _orderLines.map((line) {
      // Parse analytic account from distribution
      String analyticAccount = '';
      if (line.analyticDistributionName.isNotEmpty &&
          line.analyticDistributionName != '-') {
        analyticAccount = line.analyticDistributionName;
      }

      return {
        'product': TextEditingController(text: line.productNameDisplay),
        'analyticAccount': TextEditingController(text: analyticAccount),
        'qty': TextEditingController(text: _formatQty(line.productUomQty)),
        'price': TextEditingController(text: _formatPrice(line.priceUnit)),
      };
    }).toList();

    // Initialize subtotals for each line
    _lineSubtotals = {};
    for (int i = 0; i < _orderLines.length; i++) {
      _lineSubtotals[i] = _orderLines[i].productUomQty * _orderLines[i].priceUnit;
    }

    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final configService = ConfigService();
      final storage = SecureStorageService();

      final config = await configService.load();
      final db = config['database'] as String?;
      final apiKey = await storage.getAccessToken();

      logger.i('🔵 Loading edit page data: db=$db, apiKey=${apiKey != null}');

      if (db == null || apiKey == null) {
        logger.e('❌ Missing config: db=$db, apiKey=$apiKey');
        return;
      }

      // Load products
      try {
        final productDatasource = ProductRemoteDataSource();
        final products =
            await productDatasource.getProducts(db: db, apiKey: apiKey);
        logger.i('✅ Loaded ${products.length} products');
        if (mounted) {
          setState(() {
            _allProducts = products;
          });
        }
      } catch (e) {
        logger.e('❌ Error loading products', error: e);
      }

      // Load customers from LOCAL DATABASE
      try {
        final customerDb = CustomerLocalDatabase();
        final customers = await customerDb.getAllCustomers();
        logger.i('✅ Loaded ${customers.length} customers from LOCAL DB');
        
        // Convert local models to entities
        final customerEntities = customers
            .map((localModel) => Customer(
              id: localModel.id,
              name: localModel.name,
              email: localModel.email,
              phone: localModel.phone,
              street: localModel.street,
              street2: localModel.street2,
              districtId: localModel.districtId,
              cityId: localModel.cityId,
              stateId: localModel.stateId,
              zip: localModel.zip,
              countryId: localModel.countryId,
            ))
            .toList();
        
        if (mounted) {
          setState(() {
            _allCustomers = customerEntities;
          });
        }
      } catch (e) {
        logger.e('❌ Error loading customers from LOCAL DB', error: e);
        // Fallback: try to load from API if local DB fails
        try {
          final customerDatasource = CustomerRemoteDataSource();
          final customers =
              await customerDatasource.getCustomers(db: db, apiKey: apiKey);
          logger.i('✅ Loaded ${customers.length} customers from API (fallback)');
          if (mounted) {
            setState(() {
              _allCustomers = customers.map((model) => model.toEntity()).toList();
            });
          }
        } catch (apiError) {
          logger.e('❌ Error loading customers from API fallback', error: apiError);
        }
      }

      // Load cities from LOCAL DATABASE
      try {
        final locationDb = LocationLocalDatabase();
        final cities = await locationDb.getAllCities();
        logger.i('✅ Loaded ${cities.length} cities from LOCAL DB');

        // Build city map and city-to-state map
        final cityMap = <int, String>{};
        final cityToStateMap = <int, int>{};
        for (final city in cities) {
          cityMap[city.id] = city.name;
          if (city.stateId != null) {
            cityToStateMap[city.id] = city.stateId!;
          }
        }

        if (mounted) {
          setState(() {
            _cityMap = cityMap;
            _cityToStateMap = cityToStateMap;
          });
        }
      } catch (e) {
        logger.e('❌ Error loading cities from LOCAL DB', error: e);
      }

      // Load states from LOCAL DATABASE
      try {
        final locationDb = LocationLocalDatabase();
        final states = await locationDb.getAllStates();
        logger.i('✅ Loaded ${states.length} states from LOCAL DB');

        // Build state map
        final stateMap = <int, String>{};
        for (final state in states) {
          stateMap[state.id] = state.name;
        }

        if (mounted) {
          setState(() {
            _stateMap = stateMap;
          });
        }
      } catch (e) {
        logger.e('❌ Error loading states from LOCAL DB', error: e);
      }

      // Load districts from LOCAL DATABASE
      try {
        final locationDb = LocationLocalDatabase();
        final districts = await locationDb.getAllDistricts();
        logger.i('✅ Loaded ${districts.length} districts from LOCAL DB');
        
        // Convert local models to domain entities
        final districtEntities = districts
            .map((localModel) => District(
              id: localModel.id,
              name: localModel.name,
              code: '', // Code not available in local DB
              cityId: localModel.cityId ?? 0,
            ))
            .toList();
        
        if (mounted) {
          setState(() {
            _allDistricts = districtEntities;
          });
        }
      } catch (e) {
        logger.e('❌ Error loading districts from LOCAL DB', error: e);
        // Fallback: try to load from API if local DB fails
        try {
          final locationDatasource = LocationRemoteDataSource();
          final districts = await locationDatasource.getAllDistricts(
            db: db,
            apiKey: apiKey,
          );
          logger.i('✅ Loaded ${districts.length} districts from API (fallback)');
          if (mounted) {
            setState(() {
              _allDistricts = districts;
            });
          }
        } catch (apiError) {
          logger.e('❌ Error loading districts from API fallback', error: apiError);
        }
      }

      // Load payment terms from local database
      try {
        final paymentTermDb = PaymentTermLocalDatabase();
        final paymentTerms = await paymentTermDb.getAllPaymentTerms();
        logger.i('✅ Loaded ${paymentTerms.length} payment terms');
        if (mounted) {
          setState(() {
            _paymentTerms = paymentTerms;
          });
        }
      } catch (e) {
        logger.e('❌ Error loading payment terms from LOCAL DB', error: e);
      }
    } catch (e) {
      logger.e('❌ Error in _loadData', error: e);
    }
  }

  Future<void> _selectProduct(int lineIndex) async {
    final selected = await showDialog<ProductModel>(
      context: context,
      builder: (_) => ProductSearchModal(allProducts: _allProducts),
    );

    if (selected != null) {
      final line = _orderLines[lineIndex];
      setState(() {
        _lineControllers[lineIndex]['product']!.text = selected.name;
        _lineControllers[lineIndex]['price']!.text =
            _formatPrice(selected.listPrice);

        // Update the order line with new product info
        _orderLines[lineIndex] = OrderLine(
          productId: selected.id,
          productName: selected.name,
          productUomQty: line.productUomQty,
          analyticDistribution: line.analyticDistribution,
          priceUnit: selected.listPrice,
          priceSubtotal: line.productUomQty * selected.listPrice,
        );
      });
    }
  }

  Future<void> _selectAnalytic(int lineIndex) async {
    final selected = await AnalyticSearchModal.show(context);

    if (selected != null) {
      setState(() {
        _lineControllers[lineIndex]['analyticAccount']!.text = selected.name;
      });
      logger.i('Selected analytic: ${selected.name} (ID: ${selected.id})');
    }
  }

  Future<void> _selectDistrict() async {
    final selected = await showDialog<District>(
      context: context,
      builder: (_) => DistrictSearchModal(
        allDistricts: _allDistricts,
        cityNames: _cityMap,
        stateNames: _stateMap,
        cityToStateMap: _cityToStateMap,
      ),
    );

    if (selected != null) {
      // Get city name from map or by looking it up
      String cityName = _cityMap[selected.cityId] ?? '';
      
      // Get state ID from city, then get state name
      int? stateId = _cityToStateMap[selected.cityId];
      String stateName = stateId != null ? (_stateMap[stateId] ?? '') : '';

      setState(() {
        // _selectedDistrictId = selected.id; // Removed: variable not used elsewhere
        // _selectedCityId = selected.cityId; // Removed: variable not used elsewhere
        _districtController.text = selected.name;
        _cityController.text = cityName;
        _stateController.text = stateName;
      });

      logger.i('Selected district: ${selected.name}, city: $cityName, state: $stateName');
    }
  }

  Future<void> _selectCustomer() async {
    final selected = await showDialog<Customer>(
      context: context,
      builder: (_) => CustomerSearchModal(allCustomers: _allCustomers),
    );

    if (selected != null) {
      setState(() {
        _selectedCustomerId = selected.id;
        _customerNameController.text = selected.name;
      });

      logger.i('Selected customer: ${selected.name} (ID: ${selected.id})');
    }
  }

  Future<void> _confirmOrder() async {
    setState(() => _isLoading = true);

    try {
      final order = widget.order;

      logger.i('📝 Confirming sales order #${order.id}...');

      final result = await _salesService.confirmOrder(orderId: order.id);

      if (!mounted) return;

      setState(() => _isLoading = false);

      if (result['Success'] == true) {
        logger.i('✅ Sales order confirmed successfully');

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('✅ Sales Order berhasil dikonfirmasi'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );

        // Close page and return success to parent
        if (mounted) {
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              Navigator.pop(context, true);
            }
          });
        }
      } else {
        logger.e('❌ Failed to confirm sales order: ${result['Message']}');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('❌ Error: ${result['Message']}'),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      logger.e('❌ Unexpected error confirming order', error: e);

      if (!mounted) return;

      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text('❌ Error: $e')),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  void dispose() {
    _customerNameController.dispose();
    _addressController.dispose();
    _districtController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _notesController.dispose();
    _warehouseNameController.dispose();
    _kurirNameController.dispose();
    _awbController.dispose();
    _paymentTermController.dispose();
    for (final controllers in _lineControllers) {
      for (final controller in controllers.values) {
        controller.dispose();
      }
    }
    super.dispose();
  }

  String _formatQty(double value) {
    // Format qty to show as integer if it's whole number (e.g., 2.0 -> "2")
    // but keep decimal if it has fractional part (e.g., 2.5 -> "2.5")
    if (value == value.toInt()) {
      return value.toInt().toString();
    }
    return value.toString();
  }

  String _formatPrice(double value) {
    final formatted = value.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (match) => '.',
        );
    return formatted;
  }

  // Recalculate subtotal for a specific line item
  void _recalculateLineSubtotal(int index) {
    final controller = _lineControllers[index];

    // Parse qty from controller
    String qtyText = controller['qty']!.text.trim();
    qtyText = qtyText.replaceAll('.', ''); // Remove thousands separator
    qtyText = qtyText.replaceAll(',', '.'); // Handle comma decimal
    final qty = double.tryParse(qtyText) ?? 0.0;

    // Parse price from controller
    String priceText = controller['price']!.text.trim();
    priceText = priceText.replaceAll('Rp ', '').replaceAll('.', '');
    priceText = priceText.replaceAll(',', '.');
    final price = double.tryParse(priceText) ?? 0.0;

    // Calculate and update subtotal
    final subtotal = qty * price;
    
    setState(() {
      _lineSubtotals[index] = subtotal;
    });

    logger.i('Line $index recalculated: qty=$qty, price=$price, subtotal=$subtotal');
  }

  // Removed unused method: _formatDateForOdoo

  Future<void> _saveChanges() async {
    // Validate required fields
    if (_selectedCustomerId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Customer harus dipilih'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    if (_districtController.text.trim().isEmpty ||
        _cityController.text.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ District dan City harus diisi'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    if (_orderLines.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Minimal 1 produk harus ditambahkan'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Validate line items: Analytic, Harga must be filled for all items
    for (int i = 0; i < _orderLines.length; i++) {
      final controller = _lineControllers[i];
      final analyticAccount = controller['analyticAccount']!.text.trim();
      final priceText = controller['price']!.text.trim();

      logger.i(
          'Item $i validation: analytic="$analyticAccount", price="$priceText"');

      if (analyticAccount.isEmpty) {
        logger.e('Item $i: Analytic Account kosong!');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '❌ Item ${i + 1}: Analytic Account harus diisi',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      if (priceText.isEmpty || priceText == '0' || priceText == 'Rp 0') {
        logger.e('Item $i: Harga kosong atau 0! priceText="$priceText"');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '❌ Item ${i + 1}: Harga harus diisi dan tidak boleh 0',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
    }

    logger.i('✅ All line items validation passed!');

    setState(() => _isLoading = true);

    try {
      final order = widget.order;

      logger.i('📝 Saving sales order changes...');
      logger.i('Order ID: ${order.id}');
      logger.i('Customer ID: $_selectedCustomerId');
      logger.i('Order lines: ${_orderLines.length}');

      // Prepare order lines for API - read qty/price from controllers (user edits)
      final apiOrderLines = _orderLines.asMap().entries.map((entry) {
        final index = entry.key;
        final line = entry.value;
        final controller = _lineControllers[index];

        // Get analytic account from controller
        final analyticAccount = controller['analyticAccount']!.text.trim();

        // Parse qty from controller (or use original if not edited)
        String qtyText = controller['qty']!.text.trim();
        qtyText = qtyText.replaceAll('.', ''); // Remove thousands separator
        qtyText = qtyText.replaceAll(',', '.'); // Handle comma decimal
        final qty = double.tryParse(qtyText) ?? line.productUomQty;

        // Parse price from controller (or use original if not edited)
        String priceText = controller['price']!.text.trim();
        priceText = priceText.replaceAll('Rp ', '').replaceAll('.', '');
        priceText = priceText.replaceAll(',', '.');
        final price = double.tryParse(priceText) ?? line.priceUnit;

        logger.i('Line $index: qty=$qtyText→$qty, price=$priceText→$price');

        return {
          'product_id': line.productId,
          'product_uom_qty': qty,
          'price_unit': price,
          'analytic_distribution':
              analyticAccount.isNotEmpty ? analyticAccount : false,
        };
      }).toList();

      // Extract phone from customer name (format: "Name (phone)")
      // Also handle direct phone number from order
      String customerPhone = order.partnerPhone ?? '';
      if (customerPhone.isEmpty || customerPhone == 'false') {
        // Try to extract from customer name (format: "Name (phone)")
        if (order.customerName.contains('(') &&
            order.customerName.contains(')')) {
          final match = RegExp(r'\((\d+)\)').firstMatch(order.customerName);
          if (match != null) {
            customerPhone = match.group(1) ?? '';
          }
        }
      }

      // Call edit API
      // Handle kurirId: could be false (boolean) from API, convert to int? or null
      int? kurirIdToSend;
      if (order.kurirId is int) {
        kurirIdToSend = order.kurirId as int;
      } else if (order.kurirId is List && (order.kurirId as List).isNotEmpty) {
        // Handle array format [id, name]
        kurirIdToSend = order.kurirId[0] as int?;
      } else {
        kurirIdToSend = null;
      }

      // Handle warehouseId: could be int or [id, name]
      int warehouseIdToSend = 1;
      if (order.warehouseId is int) {
        warehouseIdToSend = order.warehouseId as int;
      } else if (order.warehouseId is List &&
          (order.warehouseId as List).isNotEmpty) {
        // Handle array format [id, name]
        warehouseIdToSend = order.warehouseId[0] as int? ?? 1;
      }

      // Get current values for fields - preserve original if not edited
      String districtToSend = _districtController.text.trim();
      String cityToSend = _cityController.text.trim();
      String stateToSend = _stateController.text.trim();
      String awbToSend = _awbController.text.trim();

      // Get notes - preserve original if field is empty (not edited)
      String notesToSend = _notesController.text.trim();
      if (notesToSend.isEmpty && order.notes != null) {
        // If notes field is empty but original had notes, keep the original
        notesToSend = order.notes!;
      }

      print('🔍 DEBUG: _selectedPaymentTermId = $_selectedPaymentTermId');
      print('🔍 DEBUG: order.paymentTermId = ${order.paymentTermId}');
      print('🔍 DEBUG: _paymentTermController.text = ${_paymentTermController.text}');

      final result = await _salesService.editSaleOrder(
        id: order.id,
        partnerId: _selectedCustomerId!,
        partnerPhone: customerPhone,
        partnerDistrict: districtToSend,
        partnerCity: cityToSend,
        partnerState: stateToSend,
        dateOrder: order.dateOrder, // Already in string format "YYYY-MM-DD"
        warehouseId: warehouseIdToSend,
        kurirId: kurirIdToSend,
        awb: awbToSend.isEmpty ? null : awbToSend,
        state: order.state,
        notes: notesToSend.isEmpty ? null : notesToSend,
        paymentTermId: _selectedPaymentTermId,
        orderLines: apiOrderLines,
      );

      if (!mounted) return;

      setState(() => _isLoading = false);

      if (result['Success'] == true) {
        logger.i('✅ Sales order updated successfully');

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('✅ Sales Order berhasil diupdate'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );

        // Wait a moment then pop with updated order data
        if (!mounted) return;
        
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            // Build updated order from current UI state
            final updatedOrderLines = _orderLines.asMap().entries.map((entry) {
              final index = entry.key;
              final line = entry.value;
              final controller = _lineControllers[index];

              // Parse qty and price from controllers
              String qtyText = controller['qty']!.text.trim();
              qtyText = qtyText.replaceAll('.', '');
              qtyText = qtyText.replaceAll(',', '.');
              final qty = double.tryParse(qtyText) ?? line.productUomQty;

              String priceText = controller['price']!.text.trim();
              priceText = priceText.replaceAll('Rp ', '').replaceAll('.', '');
              priceText = priceText.replaceAll(',', '.');
              final price = double.tryParse(priceText) ?? line.priceUnit;

              return OrderLine(
                productId: line.productId,
                productName: line.productName,
                productUomQty: qty,
                analyticDistribution: line.analyticDistribution,
                priceUnit: price,
                priceSubtotal: qty * price,
              );
            }).toList();

            // Calculate new amounts
            final newAmountTotal = updatedOrderLines.fold(
              0.0,
              (sum, line) => sum + (line.productUomQty * line.priceUnit),
            );

            // Create updated sales order by copying and updating only changed fields
            final updatedOrder = SalesOrder(
              id: widget.order.id,
              name: widget.order.name,
              partnerId: _selectedCustomerId ?? widget.order.partnerId,
              partnerName: widget.order.partnerName,
              partnerPhone: widget.order.partnerPhone,
              partnerStreet: _addressController.text.isNotEmpty
                  ? _addressController.text
                  : widget.order.partnerStreet,
              partnerStreet2: widget.order.partnerStreet2,
              partnerDistrict: _districtController.text.isNotEmpty
                  ? _districtController.text
                  : widget.order.partnerDistrict,
              partnerCity: _cityController.text.isNotEmpty
                  ? _cityController.text
                  : widget.order.partnerCity,
              partnerState: _stateController.text.isNotEmpty
                  ? _stateController.text
                  : widget.order.partnerState,
              dateOrder: widget.order.dateOrder,
              state: widget.order.state,
              warehouseId: widget.order.warehouseId,
              warehouseName: widget.order.warehouseName,
              kurirId: widget.order.kurirId,
              kurirName: widget.order.kurirName,
              awb: _awbController.text.isNotEmpty
                  ? _awbController.text
                  : widget.order.awb,
              notes: _notesController.text.isNotEmpty
                  ? _notesController.text
                  : widget.order.notes,
              paymentTermId: _selectedPaymentTermId,
              paymentTermName: _paymentTermController.text.isNotEmpty
                  ? _paymentTermController.text
                  : widget.order.paymentTermName,
              orderCount: widget.order.orderCount,
              orderLines: updatedOrderLines,
              amountTotal: newAmountTotal,
            );

            Navigator.of(context).pop(updatedOrder);
          }
        });
      } else {
        logger.e('❌ Failed to update sales order: ${result['Message']}');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('❌ Error: ${result['Message']}'),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      logger.e('❌ Unexpected error saving changes', error: e);

      if (!mounted) return;

      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text('❌ Error: $e')),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _addLineItem() {
    setState(() {
      _orderLines.add(OrderLine(
        productId: 0,
        productUomQty: 1.0,
        analyticDistribution: null,
        priceUnit: 0.0,
      ));
      final newIndex = _orderLines.length - 1;
      _lineControllers.add({
        'product': TextEditingController(text: ''),
        'analyticAccount': TextEditingController(text: ''),
        'qty': TextEditingController(text: '1'),
        'price': TextEditingController(text: '0'),
      });
      // Initialize subtotal for new line
      _lineSubtotals[newIndex] = 0.0;
    });
  }

  void _removeLineItem(int index) {
    setState(() {
      for (var controller in _lineControllers[index].values) {
        controller.dispose();
      }
      _orderLines.removeAt(index);
      _lineControllers.removeAt(index);
      
      // Remove subtotal for deleted line and rebuild map indices
      _lineSubtotals.remove(index);
      // Rebuild map keys to be sequential (0, 1, 2, ...)
      final newSubtotals = <int, double>{};
      _lineSubtotals.forEach((oldIndex, value) {
        if (oldIndex > index) {
          newSubtotals[oldIndex - 1] = value;
        } else {
          newSubtotals[oldIndex] = value;
        }
      });
      _lineSubtotals = newSubtotals;
    });
  }

  Widget _buildEditField(
    String label,
    TextEditingController controller, {
    TextInputType keyboardType = TextInputType.text,
    bool readOnly = false,
    String? prefixText,
    int maxLines = 1,
    bool isPrice = false,
    bool isQty = false,
    double fontSize = 13,
    ValueChanged<String>? onChanged,
  }) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: theme.textTheme.bodySmall?.color,
            ),
          ),
          const SizedBox(height: 4),
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            readOnly: readOnly,
            maxLines: maxLines,
            onChanged: onChanged,
            inputFormatters: isPrice
                ? [
                    FilteringTextInputFormatter.digitsOnly,
                    _ThousandsSeparatorInputFormatter(),
                  ]
                : isQty
                    ? [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'[0-9.]'),
                        ),
                      ]
                    : null,
            style: TextStyle(
              fontSize: fontSize,
              color: theme.textTheme.bodyLarge?.color,
            ),
            decoration: InputDecoration(
              prefixText: prefixText,
              filled: true,
              fillColor: readOnly
                  ? (theme.brightness == Brightness.dark
                      ? Colors.grey[800]
                      : Colors.grey[100])
                  : (theme.brightness == Brightness.dark
                      ? Colors.grey[800]
                      : Colors.white),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: theme.brightness == Brightness.dark
                      ? Colors.grey[700]!
                      : Colors.grey[300]!,
                  width: 1,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: theme.brightness == Brightness.dark
                      ? Colors.grey[700]!
                      : Colors.grey[300]!,
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide:
                    const BorderSide(color: AppTheme.primaryColor, width: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLineItemCard(int index) {
    final theme = Theme.of(context);
    final controllers = _lineControllers[index];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark
            ? Colors.grey[800]
            : Colors.grey[50],
        border: Border.all(
          color: theme.brightness == Brightness.dark
              ? Colors.grey[700]!
              : Colors.grey[200]!,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Item ${index + 1}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: Colors.white,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 18, color: Colors.red),
                onPressed: () => _removeLineItem(index),
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
              )
            ],
          ),
          const SizedBox(height: 10),
          // Product field - Simple Clickable Row
          Padding(
            padding: const EdgeInsets.only(bottom: 9),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Product',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: theme.textTheme.bodySmall?.color,
                  ),
                ),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: _allProducts.isEmpty ? null : () => _selectProduct(index),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: theme.brightness == Brightness.dark
                          ? Colors.grey[800]
                          : Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: theme.brightness == Brightness.dark
                            ? Colors.grey[700]!
                            : Colors.grey[300]!,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            controllers['product']!.text.isEmpty
                                ? 'Pilih Product'
                                : controllers['product']!.text,
                            style: TextStyle(
                              fontSize: 12,
                              color: controllers['product']!.text.isEmpty
                                  ? Colors.grey[400]
                                  : theme.textTheme.bodyLarge?.color,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 14,
                          color: theme.textTheme.bodySmall?.color,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Analytic Account field - Simple Clickable Row
          Padding(
            padding: const EdgeInsets.only(bottom: 9),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Analytic Account',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: theme.textTheme.bodySmall?.color,
                  ),
                ),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: () => _selectAnalytic(index),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: theme.brightness == Brightness.dark
                          ? Colors.grey[800]
                          : Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: theme.brightness == Brightness.dark
                            ? Colors.grey[700]!
                            : Colors.grey[300]!,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            controllers['analyticAccount']!.text.isEmpty
                                ? 'Pilih Account'
                                : controllers['analyticAccount']!.text,
                            style: TextStyle(
                              fontSize: 12,
                              color: controllers['analyticAccount']!.text.isEmpty
                                  ? Colors.grey[400]
                                  : theme.textTheme.bodyLarge?.color,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 14,
                          color: theme.textTheme.bodySmall?.color,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
            Row(
              children: [
                Expanded(
                  flex: 1,
                  child: _buildEditField(
                    'Qty',
                    controllers['qty']!,
                    keyboardType: TextInputType.number,
                    isQty: true,
                    onChanged: (_) => _recalculateLineSubtotal(index),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: _buildEditField(
                    'Price',
                    controllers['price']!,
                    keyboardType: TextInputType.number,
                    prefixText: 'Rp ',
                    isPrice: true,
                    onChanged: (_) => _recalculateLineSubtotal(index),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: AppTheme.primaryColor.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Subtotal:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: theme.textTheme.bodyMedium?.color,
                    ),
                  ),
                  Text(
                    _currencyFormat.format(
                      _lineSubtotals[index] ?? 0.0,
                    ),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final order = widget.order;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Edit Transaksi',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order Header Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.cardTheme.color,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.brightness == Brightness.dark
                      ? Colors.grey[700]!
                      : Colors.grey[200]!,
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(
                        alpha:
                            theme.brightness == Brightness.dark ? 0.3 : 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sales Order No',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: theme.textTheme.bodySmall?.color,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        order.name,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: theme.textTheme.bodyLarge?.color,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Order Date',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: theme.textTheme.bodySmall?.color,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        order.dateOrderFormatted,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: theme.textTheme.bodyLarge?.color,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Details Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.cardTheme.color,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.brightness == Brightness.dark
                      ? Colors.grey[700]!
                      : Colors.grey[200]!,
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(
                        alpha:
                            theme.brightness == Brightness.dark ? 0.3 : 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Order Details',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: theme.textTheme.bodyMedium?.color,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Divider(
                    color: theme.brightness == Brightness.dark
                        ? Colors.grey[700]
                        : Colors.grey[200],
                    height: 1,
                  ),
                  const SizedBox(height: 10),
                  // Customer Field - Simple Clickable Row
                  Text(
                    'Customer',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: theme.textTheme.bodySmall?.color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: _allCustomers.isEmpty ? null : _selectCustomer,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: theme.brightness == Brightness.dark
                            ? Colors.grey[800]
                            : Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: theme.brightness == Brightness.dark
                              ? Colors.grey[700]!
                              : Colors.grey[300]!,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              _customerNameController.text.isEmpty
                                  ? 'Pilih Customer'
                                  : _customerNameController.text,
                              style: TextStyle(
                                fontSize: 12,
                                color: _customerNameController.text.isEmpty
                                    ? Colors.grey[400]
                                    : theme.textTheme.bodyLarge?.color,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 14,
                            color: theme.textTheme.bodySmall?.color,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 9),
                  // Phone Display (Read-only)
                  Text(
                    'Phone',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: theme.textTheme.bodySmall?.color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: theme.brightness == Brightness.dark
                          ? Colors.grey[800]
                          : Colors.grey[50],
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: theme.brightness == Brightness.dark
                            ? Colors.grey[700]!
                            : Colors.grey[300]!,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      widget.order.partnerPhone ?? '-',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.textTheme.bodyLarge?.color,
                      ),
                    ),
                  ),
                  const SizedBox(height: 9),
                  _buildEditField('Address', _addressController, maxLines: 2, fontSize: 11),
                  const SizedBox(height: 9),
                  
                  // Simplified Location Display (State, City, District in one line)
                  Text(
                    'Location',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: theme.textTheme.bodySmall?.color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: _allDistricts.isEmpty ? null : _selectDistrict,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: theme.brightness == Brightness.dark
                            ? Colors.grey[800]
                            : Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: theme.brightness == Brightness.dark
                              ? Colors.grey[700]!
                              : Colors.grey[300]!,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              _stateController.text.isEmpty
                                  ? 'Pilih Lokasi'
                                  : '${_stateController.text}, ${_cityController.text}, ${_districtController.text}',
                              style: TextStyle(
                                fontSize: 12,
                                color: _stateController.text.isEmpty
                                    ? Colors.grey[400]
                                    : theme.textTheme.bodyLarge?.color,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 14,
                            color: theme.textTheme.bodySmall?.color,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 9),
                  
                  // Warehouse and Kurir in one row
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Warehouse',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: theme.textTheme.bodySmall?.color,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _warehouseNameController.text.isEmpty
                                  ? '-'
                                  : _warehouseNameController.text,
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.textTheme.bodyMedium?.color,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Kurir',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: theme.textTheme.bodySmall?.color,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _kurirNameController.text.isEmpty
                                  ? '-'
                                  : _kurirNameController.text,
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.textTheme.bodyMedium?.color,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 9),
                  
                  // AWB without box
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AWB',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: theme.textTheme.bodySmall?.color,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _awbController.text.isEmpty
                            ? '-'
                            : _awbController.text,
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.textTheme.bodyMedium?.color,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 9),
                  
                  // Payment Term - Seragam dengan Customer Style
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Payment Term',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: theme.textTheme.bodySmall?.color,
                        ),
                      ),
                      const SizedBox(height: 4),
                      GestureDetector(
                        onTap: _paymentTerms.isEmpty
                            ? null
                            : () async {
                                final selected = await showDialog<Map<String, dynamic>>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Select Payment Term'),
                                    content: SingleChildScrollView(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: _paymentTerms.map((term) {
                                          return ListTile(
                                            title: Text(term['name'] ?? 'Unknown'),
                                            onTap: () {
                                              Navigator.pop(ctx, term);
                                            },
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                  ),
                                );

                                if (selected != null) {
                                  setState(() {
                                    _selectedPaymentTermId = selected['id'] as int?;
                                    _paymentTermController.text = selected['name'] ?? '';
                                  });
                                }
                              },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 9,
                          ),
                          decoration: BoxDecoration(
                            color: theme.brightness == Brightness.dark
                                ? Colors.grey[800]
                                : Colors.white,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: theme.brightness == Brightness.dark
                                  ? Colors.grey[700]!
                                  : Colors.grey[300]!,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  _paymentTermController.text.isEmpty
                                      ? 'Pilih Payment Term'
                                      : _paymentTermController.text,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: _paymentTermController.text.isEmpty
                                        ? Colors.grey[400]
                                        : theme.textTheme.bodyLarge?.color,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                Icons.arrow_drop_down,
                                color: Colors.grey[400],
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 9),
                  
                  // Notes without box
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Notes',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: theme.textTheme.bodySmall?.color,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _notesController.text.isEmpty
                            ? '-'
                            : _notesController.text,
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.textTheme.bodyMedium?.color,
                          height: 1.4,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Line Items Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.cardTheme.color,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.brightness == Brightness.dark
                      ? Colors.grey[700]!
                      : Colors.grey[200]!,
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(
                        alpha:
                            theme.brightness == Brightness.dark ? 0.3 : 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Line Items',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: theme.textTheme.bodyMedium?.color,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ..._orderLines.asMap().entries.map((entry) {
                    return _buildLineItemCard(entry.key);
                  }),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _addLineItem,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add Line Item'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        side: BorderSide(
                          color: AppTheme.primaryColor.withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Summary Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.cardTheme.color,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.brightness == Brightness.dark
                      ? Colors.grey[700]!
                      : Colors.grey[200]!,
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(
                        alpha:
                            theme.brightness == Brightness.dark ? 0.3 : 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Items:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        _orderLines.length.toString(),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Divider(
                    color: theme.brightness == Brightness.dark
                        ? Colors.grey[700]
                        : Colors.grey[200],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Grand Total:',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        _currencyFormat.format(
                          _lineSubtotals.values.fold(0.0, (sum, value) => sum + value),
                        ),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Action Buttons
            if (!_orderSavedSuccessfully)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed:
                          _isLoading ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey[700],
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        side: BorderSide(color: Colors.grey[300]!, width: 1),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveChanges,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        disabledBackgroundColor: Colors.grey[400],
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Save Changes',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              )
            else
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed:
                          _isLoading ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey[700],
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        side: BorderSide(color: Colors.grey[300]!, width: 1),
                      ),
                      child: const Text(
                        'Close',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _confirmOrder,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        disabledBackgroundColor: Colors.grey[400],
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Confirm Order',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
