import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../../config/theme.dart';
import '../../domain/entities/sales_order.dart';
import '../../domain/entities/order_line.dart';
import '../../../product/data/datasources/product_remote_datasource.dart';
import '../../../product/data/models/product_model.dart';
import '../../../location/data/datasources/location_remote_datasource.dart';
import '../../../location/domain/entities/district.dart';
import '../../../../services/config_service.dart';
import '../../../../services/secure_storage_service.dart';
import 'product_search_modal.dart';
import 'district_search_modal.dart';

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
  late final TextEditingController _customerNameController;
  late final TextEditingController _warehouseIdController;
  late final TextEditingController _kurirIdController;
  late final TextEditingController _awbController;
  late final TextEditingController _addressController;
  late final TextEditingController _districtController;
  late final TextEditingController _cityController;
  late final List<OrderLine> _orderLines;
  late final List<Map<String, TextEditingController>> _lineControllers;
  late List<ProductModel> _allProducts = [];
  late List<District> _allDistricts = [];
  late Map<int, String> _cityMap = {}; // cityId -> cityName
  bool _loadingData = false;
  final _currencyFormat =
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    final order = widget.order;

    _customerNameController =
        TextEditingController(text: order.customerName);
    _addressController =
        TextEditingController(text: order.address?.toString() ?? '');
    _districtController =
        TextEditingController(text: order.district?.toString() ?? '');
    _cityController =
        TextEditingController(text: order.city?.toString() ?? '');
    _warehouseIdController = TextEditingController(
        text: order.warehouseId?.toString() ?? '');
    _kurirIdController =
        TextEditingController(text: order.kurirId?.toString() ?? '');
    _awbController = TextEditingController(text: order.awb?.toString() ?? '');

    _orderLines = order.orderLines
        .map((line) => OrderLine(
              productId: line.productId,
              productUomQty: line.productUomQty,
              analyticDistribution: line.analyticDistribution,
              priceUnit: line.priceUnit,
              priceSubtotal: line.priceSubtotal,
            ))
        .toList();

    _lineControllers = _orderLines.map((line) {
      // Parse analytic account from distribution
      String analyticAccount = '';
      if (line.analyticDistribution != null &&
          line.analyticDistribution!.isNotEmpty) {
        final entries = line.analyticDistribution!.entries.toList();
        analyticAccount = entries.map((e) => '${e.key}: ${e.value}%').join(', ');
      }

      return {
        'product': TextEditingController(text: line.productName),
        'analyticAccount': TextEditingController(text: analyticAccount),
        'qty': TextEditingController(text: line.productUomQty.toString()),
        'price': TextEditingController(
            text: _formatPrice(line.priceUnit)),
      };
    }).toList();

    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() => _loadingData = true);

      final configService = ConfigService();
      final storage = SecureStorageService();

      final config = await configService.load();
      final db = config['database'] as String?;
      final apiKey = await storage.getAccessToken();

      print('🔵 Loading edit page data: db=$db, apiKey=${apiKey != null}');

      if (db == null || apiKey == null) {
        print('❌ Missing config: db=$db, apiKey=$apiKey');
        return;
      }

      // Load products
      try {
        final productDatasource = ProductRemoteDataSource();
        final products = await productDatasource.getProducts(db: db, apiKey: apiKey);
        print('✅ Loaded ${products.length} products');
        if (mounted) {
          setState(() {
            _allProducts = products;
          });
        }
      } catch (e) {
        print('❌ Error loading products: $e');
      }

      // Load cities
      try {
        final locationDatasource = LocationRemoteDataSource();
        final cities = await locationDatasource.getCities(
          db: db,
          apiKey: apiKey,
        );
        print('✅ Loaded ${cities.length} cities');
        
        // Build city map
        final cityMap = <int, String>{};
        for (final city in cities) {
          cityMap[city.id] = city.name;
        }
        
        if (mounted) {
          setState(() {
            _cityMap = cityMap;
          });
        }
      } catch (e) {
        print('❌ Error loading cities: $e');
      }

      // Load districts
      try {
        final locationDatasource = LocationRemoteDataSource();
        final districts = await locationDatasource.getAllDistricts(
          db: db,
          apiKey: apiKey,
        );
        print('✅ Loaded ${districts.length} districts');
        if (mounted) {
          setState(() {
            _allDistricts = districts;
          });
        }
      } catch (e) {
        print('❌ Error loading districts: $e');
      }
    } catch (e) {
      print('❌ Error in _loadData: $e');
    } finally {
      if (mounted) setState(() => _loadingData = false);
    }
  }

  Future<void> _selectProduct(int lineIndex) async {
    final selected = await showDialog<ProductModel>(
      context: context,
      builder: (_) => ProductSearchModal(allProducts: _allProducts),
    );

    if (selected != null) {
      setState(() {
        _lineControllers[lineIndex]['product']!.text = selected.name;
        _lineControllers[lineIndex]['price']!.text = _formatPrice(selected.listPrice);
      });
    }
  }

  Future<void> _selectDistrict() async {
    final selected = await showDialog<District>(
      context: context,
      builder: (_) => DistrictSearchModal(
        allDistricts: _allDistricts,
        cityNames: _cityMap,
      ),
    );

    if (selected != null) {
      // Get city name from map or by looking it up
      String cityName = _cityMap[selected.cityId] ?? '';
      
      setState(() {
        _districtController.text = selected.name;
        _cityController.text = cityName;
      });
    }
  }

  @override
  void dispose() {
    _customerNameController.dispose();
    _addressController.dispose();
    _districtController.dispose();
    _cityController.dispose();
    _warehouseIdController.dispose();
    _kurirIdController.dispose();
    _awbController.dispose();
    for (final controllers in _lineControllers) {
      for (final controller in controllers.values) {
        controller.dispose();
      }
    }
    super.dispose();
  }

  void _syncLineItem(int index) {
    final controllers = _lineControllers[index];
    final line = _orderLines[index];

    // Update qty
    final newQty = double.tryParse(controllers['qty']!.text.replaceAll('.', '')) ??
        line.productUomQty;

    // Update price - remove separator first
    final priceText = controllers['price']!.text.replaceAll('Rp ', '').replaceAll('.', '');
    final newPrice = double.tryParse(priceText) ?? line.priceUnit;

    _orderLines[index] = OrderLine(
      productId: line.productId,
      productUomQty: newQty,
      analyticDistribution: line.analyticDistribution,
      priceUnit: newPrice,
      priceSubtotal: newQty * newPrice,
    );
  }

  String _formatPrice(double value) {
    final formatted = value.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => '.',
    );
    return formatted;
  }

  void _saveChanges() {
    // Sync all line items before saving
    for (int i = 0; i < _orderLines.length; i++) {
      _syncLineItem(i);
    }

    // Return updated order
    Navigator.of(context).pop(_orderLines);
  }

  void _addLineItem() {
    setState(() {
      _orderLines.add(OrderLine(
        productId: 0,
        productUomQty: 1.0,
        analyticDistribution: null,
        priceUnit: 0.0,
      ));
      _lineControllers.add({
        'product': TextEditingController(text: ''),
        'analyticAccount': TextEditingController(text: ''),
        'qty': TextEditingController(text: '1'),
        'price': TextEditingController(text: '0'),
      });
    });
  }

  void _removeLineItem(int index) {
    setState(() {
      for (var controller in _lineControllers[index].values) {
        controller.dispose();
      }
      _orderLines.removeAt(index);
      _lineControllers.removeAt(index);
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
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            readOnly: readOnly,
            maxLines: maxLines,
            inputFormatters: isPrice
                ? [
                    FilteringTextInputFormatter.digitsOnly,
                    _ThousandsSeparatorInputFormatter(),
                  ]
                : null,
            style: const TextStyle(fontSize: 13, color: Colors.black87),
            decoration: InputDecoration(
              prefixText: prefixText,
              filled: true,
              fillColor: readOnly ? Colors.grey[100] : Colors.white,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
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
    final line = _orderLines[index];
    final controllers = _lineControllers[index];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
            // Product field dengan search button
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Product',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: controllers['product']!,
                          readOnly: true,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.black87,
                          ),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: Colors.grey[300]!,
                                width: 1,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: Colors.grey[300]!,
                                width: 1,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        height: 42,
                        child: ElevatedButton.icon(
                          onPressed: _allProducts.isEmpty
                              ? null
                              : () => _selectProduct(index),
                          icon: const Icon(Icons.search, size: 16),
                          label: const Text('Search'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            disabledBackgroundColor: Colors.grey[400],
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            _buildEditField(
              'Analytic Account',
              controllers['analyticAccount']!,
            ),
            Row(
              children: [
                Expanded(
                  flex: 1,
                  child: _buildEditField(
                    'Qty',
                    controllers['qty']!,
                    keyboardType: TextInputType.number,
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
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Subtotal:',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    _currencyFormat.format(
                      line.productUomQty * line.priceUnit,
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Edit Sales Order',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
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
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sales Order: ${order.name}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Date: ${order.dateOrderFormatted}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Details Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
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
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildEditField('Customer', _customerNameController,
                      readOnly: true),
                  _buildEditField('Address', _addressController, maxLines: 2),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'District',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _districtController,
                                readOnly: true,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.black87,
                                ),
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: Colors.white,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      color: Colors.grey[300]!,
                                      width: 1,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      color: Colors.grey[300]!,
                                      width: 1,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              height: 42,
                              child: ElevatedButton.icon(
                                onPressed: _allDistricts.isEmpty
                                    ? null
                                    : _selectDistrict,
                                icon: _allDistricts.isEmpty
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
                                        ),
                                      )
                                    : const Icon(Icons.search, size: 16),
                                label: Text(_allDistricts.isEmpty
                                    ? 'Loading...'
                                    : 'Search'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryColor,
                                  disabledBackgroundColor: Colors.grey[400],
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  _buildEditField('City', _cityController, readOnly: true),
                  _buildEditField('Warehouse ID', _warehouseIdController),
                  _buildEditField('Kurir ID', _kurirIdController),
                  _buildEditField('AWB', _awbController),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Line Items Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
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
                      color: Colors.grey[700],
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
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
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
                  Divider(color: Colors.grey[300]),
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
                          _orderLines.fold(
                            0.0,
                            (sum, line) =>
                                sum + (line.productUomQty * line.priceUnit),
                          ),
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
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
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
                    onPressed: _saveChanges,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Save Changes',
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
