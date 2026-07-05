import 'package:flutter/material.dart';
import 'package:pintarx/config/theme.dart';
import 'package:pintarx/models/location_picker.dart';
import 'location_picker_page.dart';

class TransactionEditPage extends StatefulWidget {
  final Map<String, dynamic> transaction;

  const TransactionEditPage({super.key, required this.transaction});

  @override
  State<TransactionEditPage> createState() => _TransactionEditPageState();
}

class _TransactionEditPageState extends State<TransactionEditPage> {
  late final TextEditingController _customerController;
  late final TextEditingController _phoneController;
  late final TextEditingController _paymentTermsController;
  late final TextEditingController _provinceController;
  late final TextEditingController _cityController;
  late final TextEditingController _districtController;
  late final TextEditingController _fullAddressController;
  late final List<Map<String, dynamic>> _items;
  late final List<Map<String, TextEditingController>> _itemControllers;

  @override
  void initState() {
    super.initState();
    final transaction = widget.transaction;
    _customerController = TextEditingController(text: transaction['customer'] as String? ?? '');
    _phoneController = TextEditingController(text: (transaction['phone'] as String?)?.trim() ?? '');
    _paymentTermsController = TextEditingController(text: transaction['paymentTerms'] as String? ?? '');
    _provinceController = TextEditingController(text: transaction['deliveryProvince'] as String? ?? '');
    _cityController = TextEditingController(text: transaction['deliveryCity'] as String? ?? '');
    _districtController = TextEditingController(text: transaction['deliveryDistrict'] as String? ?? '');
    _fullAddressController = TextEditingController(text: transaction['deliveryAddress'] as String? ?? '');

    _items = (transaction['items'] as List<dynamic>?)
            ?.map((item) => Map<String, dynamic>.from(item as Map<String, dynamic>))
            .toList() ??
        [];

    _itemControllers = _items.map((item) {
      return {
        'product': TextEditingController(text: item['product'] as String? ?? ''),
        'analyticAccount': TextEditingController(text: item['analyticAccount'] as String? ?? ''),
        'qty': TextEditingController(text: (item['qty']?.toString() ?? '')),
        'price': TextEditingController(text: (item['price'] as double?)?.toStringAsFixed(0) ?? ''),
      };
    }).toList();
  }



  @override
  void dispose() {
    _customerController.dispose();
    _phoneController.dispose();
    _paymentTermsController.dispose();
    _provinceController.dispose();
    _cityController.dispose();
    _districtController.dispose();
    _fullAddressController.dispose();
    for (final controllers in _itemControllers) {
      controllers.values.forEach((controller) => controller.dispose());
    }
    super.dispose();
  }

  void _syncItem(int index) {
    final controllers = _itemControllers[index];
    final item = _items[index];
    item['product'] = controllers['product']!.text.trim();
    item['analyticAccount'] = controllers['analyticAccount']!.text.trim();
    item['qty'] = int.tryParse(controllers['qty']!.text.replaceAll('.', '')) ?? item['qty'];
    item['price'] = double.tryParse(controllers['price']!.text.replaceAll('.', '')) ?? item['price'];
  }

  int _estimateShipping() {
    if (_districtController.text.trim().isEmpty) {
      return 0;
    }

    const baseFee = 10000;
    const provinceFee = 5000;
    const cityFee = 3000;
    const districtFee = 2000;
    return baseFee + provinceFee + cityFee + districtFee;
  }

  String _formatCurrency(double value) {
    final formatted = value.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => '.',
    );
    return 'Rp $formatted';
  }

  void _saveChanges() {
    for (var i = 0; i < _items.length; i++) {
      _syncItem(i);
    }

    final updated = Map<String, dynamic>.from(widget.transaction);
    updated['customer'] = _customerController.text.trim();
    final rawPhone = _phoneController.text.trim();
    updated['phone'] = rawPhone.isEmpty
        ? ''
        : rawPhone.startsWith('+62')
            ? rawPhone
            : rawPhone.startsWith('0')
                ? '+62${rawPhone.substring(1)}'
                : '+62$rawPhone';
    updated['paymentTerms'] = _paymentTermsController.text.trim();
    updated['deliveryProvince'] = _provinceController.text.trim();
    updated['deliveryCity'] = _cityController.text.trim();
    updated['deliveryDistrict'] = _districtController.text.trim();
    updated['deliveryAddress'] = _fullAddressController.text.trim();
    updated['items'] = _items
        .map((item) => {
              'product': item['product'] as String? ?? '',
              'analyticAccount': item['analyticAccount'] as String? ?? '',
              'qty': item['qty'] as int? ?? 0,
              'price': item['price'] as double? ?? 0.0,
            })
        .toList();

    Navigator.of(context).pop(updated);
  }

  void _addItemLine() {
    setState(() {
      _items.add({
        'product': '',
        'analyticAccount': '',
        'qty': 1,
        'price': 0.0,
      });
      _itemControllers.add({
        'product': TextEditingController(text: ''),
        'analyticAccount': TextEditingController(text: ''),
        'qty': TextEditingController(text: '1'),
        'price': TextEditingController(text: '0'),
      });
    });
  }

  void _openLocationPicker() async {
    final result = await Navigator.of(context).push<LocationData>(
      MaterialPageRoute(
        builder: (context) => LocationPickerPage(
          initialProvince: _provinceController.text,
          initialCity: _cityController.text,
          initialDistrict: _districtController.text,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _provinceController.text = result.province;
        _cityController.text = result.city;
        _districtController.text = result.district;
      });
    }
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildEditField(
    String label,
    TextEditingController controller, {
    TextInputType keyboardType = TextInputType.text,
    ValueChanged<String>? onChanged,
    bool readOnly = false,
    String? prefixText,
    int maxLines = 1,
    IconData? icon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 3),
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            onChanged: onChanged,
            readOnly: readOnly,
            maxLines: maxLines,
            style: const TextStyle(fontSize: 12, color: Colors.black87),
            decoration: InputDecoration(
              prefixText: prefixText,
              prefixIcon: icon != null ? Icon(icon, size: 16, color: AppTheme.primaryColor) : null,
              filled: true,
              fillColor: Colors.grey[50],
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: AppTheme.primaryColor, width: 1.5),
              ),
              hintStyle: TextStyle(color: Colors.grey[400], fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemLine(int index) {
    final controllers = _itemControllers[index];
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  'Item ${index + 1}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                    color: Colors.white,
                  ),
                ),
              ),
              const Spacer(),
              SizedBox(
                width: 24,
                height: 24,
                child: IconButton(
                  icon: const Icon(Icons.close, size: 16),
                  onPressed: () {
                    setState(() {
                      _items.removeAt(index);
                      for (var controller in _itemControllers[index].values) {
                        controller.dispose();
                      }
                      _itemControllers.removeAt(index);
                    });
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildEditField(
            'Produk',
            controllers['product']!,
            onChanged: (_) => _syncItem(index),
          ),
          _buildEditField(
            'Analytic Account',
            controllers['analyticAccount']!,
            onChanged: (_) => _syncItem(index),
          ),
          Row(
            children: [
              Expanded(
                flex: 1,
                child: _buildEditField(
                  'Qty',
                  controllers['qty']!,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => _syncItem(index),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: _buildEditField(
                  'Harga',
                  controllers['price']!,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => _syncItem(index),
                  prefixText: 'Rp ',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          // Optionally handle unsaved changes
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
          title: const Text('Edit Transaksi', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18)),
          backgroundColor: AppTheme.primaryColor,
          elevation: 0,
          centerTitle: false,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Customer Info Card
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
                    _buildSectionTitle('Informasi Pelanggan'),
                    const SizedBox(height: 12),
                    _buildEditField('Nama Pelanggan', _customerController),
                    Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: _buildEditField('Telepon', _phoneController, keyboardType: TextInputType.phone),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 1,
                          child: _buildEditField('Syarat Bayar', _paymentTermsController),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Delivery Address Card
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
                    _buildSectionTitle('Alamat Pengiriman'),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: _openLocationPicker,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.grey[300]!, width: 1),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 2,
                              offset: const Offset(0, 1),
                            )
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Icon(Icons.location_on, size: 14, color: AppTheme.primaryColor),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _provinceController.text.isEmpty
                                  ? Text(
                                      'Pilih Lokasi',
                                      style: TextStyle(color: Colors.grey[400], fontSize: 12),
                                    )
                                  : Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _districtController.text,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 12,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        const SizedBox(height: 1),
                                        Text(
                                          '${_cityController.text}, ${_provinceController.text}',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.grey[600],
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios,
                              size: 12,
                              color: AppTheme.primaryColor.withValues(alpha: 0.5),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_districtController.text.trim().isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.primaryColor.withValues(alpha: 0.1),
                              AppTheme.primaryColor.withValues(alpha: 0.05),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.2), width: 1),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.local_shipping, size: 14, color: AppTheme.primaryColor),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Ongkir: ${_formatCurrency(_estimateShipping().toDouble())}',
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppTheme.primaryColor),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    _buildEditField('Alamat Lengkap', _fullAddressController, maxLines: 2),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Items Card
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
                    _buildSectionTitle('Detail Item'),
                    const SizedBox(height: 12),
                    ...List.generate(_items.length, (index) => _buildItemLine(index)),
                    const SizedBox(height: 4),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _addItemLine,
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Tambah Item', style: TextStyle(fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          side: BorderSide(color: AppTheme.primaryColor.withValues(alpha: 0.3), width: 1.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Action Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveChanges,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 2,
                  ),
                  child: const Text(
                    'Confirm',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
