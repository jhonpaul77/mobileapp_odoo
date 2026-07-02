import 'package:flutter/material.dart';
import 'package:pintarx/config/theme.dart';

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
    item['qty'] = int.tryParse(controllers['qty']!.text.replaceAll('.', '')) ?? item['qty'];
    item['price'] = double.tryParse(controllers['price']!.text.replaceAll('.', '')) ?? item['price'];
  }

  double _calculateTotalItems() {
    return _items.fold<double>(0.0, (sum, item) {
      final qty = item['qty'] is int ? item['qty'] as int : int.tryParse('${item['qty']}') ?? 0;
      final price = item['price'] is double ? item['price'] as double : double.tryParse('${item['price']}') ?? 0.0;
      return sum + (qty * price);
    });
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
        'qty': 1,
        'price': 0.0,
      });
      _itemControllers.add({
        'product': TextEditingController(text: ''),
        'qty': TextEditingController(text: '1'),
        'price': TextEditingController(text: '0'),
      });
    });
  }

  Widget _buildField(
    String label,
    TextEditingController controller, {
    TextInputType keyboardType = TextInputType.text,
    ValueChanged<String>? onChanged,
    bool readOnly = false,
    String? prefixText,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        onChanged: onChanged,
        readOnly: readOnly,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          prefixText: prefixText,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildItemLine(int index) {
    final controllers = _itemControllers[index];
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey[200]!, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Item ${index + 1}',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          _buildField(
            'Product',
            controllers['product']!,
            onChanged: (_) => _syncItem(index),
          ),
          _buildField(
            'Qty',
            controllers['qty']!,
            keyboardType: TextInputType.number,
            onChanged: (_) => _syncItem(index),
          ),
          _buildField(
            'Price',
            controllers['price']!,
            keyboardType: TextInputType.number,
            onChanged: (_) => _syncItem(index),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Edit Transaksi'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildField('Customer', _customerController),
            _buildField('Phone', _phoneController, keyboardType: TextInputType.phone, prefixText: '+62 '),
            _buildField('Payment Terms', _paymentTermsController),
            const SizedBox(height: 24),
            const Text(
              'Delivery Address',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            _buildField('Province', _provinceController),
            Row(
              children: [
                Expanded(
                  child: _buildField('City', _cityController),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildField('District', _districtController, onChanged: (_) => setState(() {})),
                ),
              ],
            ),
            if (_districtController.text.trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3), width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Estimasi Biaya',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total Barang'),
                          Text(
                            _formatCurrency(_calculateTotalItems()),
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Ongkir'),
                          Text(
                            _formatCurrency(_estimateShipping().toDouble()),
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Divider(height: 1),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total',
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                          ),
                          Text(
                            _formatCurrency(_calculateTotalItems() + _estimateShipping().toDouble()),
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            _buildField(
              'Full Address',
              _fullAddressController,
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            const Text(
              'Item Lines',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            ...List.generate(_items.length, (index) => _buildItemLine(index)),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _addItemLine,
                icon: const Icon(Icons.add),
                label: const Text('Tambah Item'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveChanges,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text(
                  'Confirm',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
