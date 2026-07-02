// pages/sales/sales_page.dart
import 'package:flutter/material.dart';
import 'package:pintarx/models/sales/sales.dart';
import 'package:pintarx/services/sales_service.dart';
import 'package:pintarx/widgets/common/app_header.dart';

class SalesPage extends StatefulWidget {
  const SalesPage({super.key});

  @override
  State<SalesPage> createState() => _SalesPageState();
}

class _SalesPageState extends State<SalesPage> {
  final _formKey = GlobalKey<FormState>();
  final _catatanCtrl = TextEditingController();

  bool _isLoading = false;
  String? _selectedCustomer;
  String _noTransaksi = "S0001";
  DateTime _tanggal = DateTime.now();

  List<SalesDetail> _details = [];

  // Dummy data
  final List<Map<String, String>> _customers = [
    {'id': '1', 'name': 'Budi Santoso'},
    {'id': '2', 'name': 'Sari Indah'},
  ];

  final List<Map<String, dynamic>> _products = [
    {'id': 'p1', 'name': 'Produk A', 'harga': 100000.0},
    {'id': 'p2', 'name': 'Produk B', 'harga': 150000.0},
    {'id': 'p3', 'name': 'Produk C', 'harga': 250000.0},
  ];

  void _addItem() {
    setState(() {
      _details.add(SalesDetail(productId: '', jumlah: 1, harga: 0));
    });
  }

  void _removeItem(int index) {
    setState(() {
      _details.removeAt(index);
    });
  }

  double get subtotal =>
      _details.fold(0, (sum, d) => sum + (d.jumlah * d.harga));

  double get total => subtotal; // nanti bisa ditambah diskon/pajak

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_details.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tambahkan minimal 1 item produk')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final sales = Sales(
      noTransaksi: _noTransaksi,
      tanggal: _tanggal,
      idCustomer: _selectedCustomer!,
      catatan: _catatanCtrl.text,
      salesType: 'penjualan',
      salesStatus: 'konfirmasi',
      paymentStatus: 'lunas',
      total: total,
      diskon: 0,
      pajak: 0,
      reference: '',
      tags: '',
      details: _details,
    );

    final result = await SalesService().createSales(sales);
    setState(() => _isLoading = false);

    if (result.success == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Transaksi berhasil disimpan')),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Gagal: ${result.message}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Transaksi Penjualan")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppHeader(
                  title: "Transaksi Penjualan",
                  subtitle: "Input transaksi baru",
                ),
                const SizedBox(height: 16),

                // --- Header Transaksi ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("No Transaksi: $_noTransaksi",
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14)),
                    Text(
                      "Tanggal: ${_tanggal.day}-${_tanggal.month}-${_tanggal.year}",
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // --- Customer Dropdown ---
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: "Customer",
                    border: OutlineInputBorder(),
                  ),
                  value: _selectedCustomer,
                  items: _customers
                      .map((c) => DropdownMenuItem<String>(
                            value: c['id']!,
                            child: Text(c['name']!),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedCustomer = v),
                  validator: (v) => v == null ? "Pilih customer" : null,
                ),
                const SizedBox(height: 20),

                // --- Tabel Produk ---
                const Text(
                  "Daftar Produk",
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black87),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding:
                            const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        color: Colors.grey[100],
                        child: Row(
                          children: const [
                            Expanded(flex: 4, child: Text("Nama Produk")),
                            Expanded(flex: 2, child: Text("Jumlah")),
                            Expanded(flex: 2, child: Text("Harga")),
                            Expanded(flex: 2, child: Text("Total")),
                            SizedBox(width: 32),
                          ],
                        ),
                      ),
                      ..._details.asMap().entries.map((entry) {
                        final i = entry.key;
                        final d = entry.value;

                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 6, horizontal: 8),
                          child: Row(
                            children: [
                              // Produk
                              Expanded(
                                flex: 4,
                                child: DropdownButtonFormField<String>(
                                  value: d.productId.isEmpty ? null : d.productId,
                                  decoration:
                                      const InputDecoration(border: InputBorder.none),
                                  items: _products
                                      .map((p) => DropdownMenuItem<String>(
                                            value: p['id'],
                                            child: Text(p['name']),
                                          ))
                                      .toList(),
                                  onChanged: (v) {
                                    final prod = _products
                                        .firstWhere((p) => p['id'] == v);
                                    setState(() {
                                      _details[i] = SalesDetail(
                                        productId: v!,
                                        jumlah: d.jumlah,
                                        harga: (prod['harga'] as num).toDouble(),
                                      );
                                    });
                                  },
                                ),
                              ),

                              // Jumlah
                              Expanded(
                                flex: 2,
                                child: TextFormField(
                                  initialValue: d.jumlah.toString(),
                                  textAlign: TextAlign.center,
                                  decoration: const InputDecoration(
                                    isDense: true,
                                    border: OutlineInputBorder(),
                                  ),
                                  keyboardType: TextInputType.number,
                                  onChanged: (v) {
                                    setState(() {
                                      _details[i] = SalesDetail(
                                        productId: d.productId,
                                        jumlah: int.tryParse(v) ?? 1,
                                        harga: d.harga,
                                      );
                                    });
                                  },
                                ),
                              ),

                              // Harga
                              Expanded(
                                flex: 2,
                                child: Text(
                                  d.harga == 0
                                      ? "-"
                                      : "Rp ${(d.harga).toStringAsFixed(0)}",
                                  textAlign: TextAlign.center,
                                ),
                              ),

                              // Total
                              Expanded(
                                flex: 2,
                                child: Text(
                                  d.harga == 0
                                      ? "-"
                                      : "Rp ${(d.harga * d.jumlah).toStringAsFixed(0)}",
                                  textAlign: TextAlign.center,
                                ),
                              ),

                              // Delete
                              IconButton(
                                icon: const Icon(Icons.delete_outline,
                                    color: Colors.redAccent),
                                onPressed: () => _removeItem(i),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: _addItem,
                        icon: const Icon(Icons.add),
                        label: const Text("Tambah Item"),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // --- Ringkasan Total ---
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _buildSummaryRow("Subtotal", subtotal),
                    _buildSummaryRow("Diskon", 0),
                    _buildSummaryRow("Pajak", 0),
                    const Divider(),
                    _buildSummaryRow("Total", total,
                        bold: true, color: Colors.green[700]),
                  ],
                ),

                const SizedBox(height: 24),

                // --- Tombol Simpan ---
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: _isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save_rounded),
                    label: const Text("Simpan Transaksi"),
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, double value,
      {bool bold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            "Rp ${value.toStringAsFixed(0)}",
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              color: color ?? Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
