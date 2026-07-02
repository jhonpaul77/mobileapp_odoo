// models/sales/sales.dart
class Sales {
  final String? id;
  final String noTransaksi;
  final DateTime tanggal;
  final String idCustomer;
  final String catatan;
  final String salesType;
  final String salesStatus;
  final String paymentStatus;
  final double total;
  final double diskon;
  final double pajak;
  final String reference;
  final String tags;
  final List<SalesDetail> details;

  Sales({
    this.id,
    required this.noTransaksi,
    required this.tanggal,
    required this.idCustomer,
    required this.catatan,
    required this.salesType,
    required this.salesStatus,
    required this.paymentStatus,
    required this.total,
    required this.diskon,
    required this.pajak,
    required this.reference,
    required this.tags,
    required this.details,
  });

  // ✅ body untuk POST request
  Map<String, dynamic> toJson() {
    return {
      "no_transaksi": noTransaksi,
      "tanggal": tanggal.toUtc().toIso8601String(),
      "id_customer": idCustomer,
      "catatan": catatan,
      "sales_type": salesType,
      "sales_status": salesStatus,
      "payment_status": paymentStatus,
      "total": total,
      "diskon": diskon,
      "pajak": pajak,
      "reference": reference,
      "tags": tags,
      "details": details.map((d) => d.toJson()).toList(),
    };
  }

  // ✅ parsing dari response
  factory Sales.fromJson(Map<String, dynamic> json) {
    return Sales(
      id: json["id"],
      noTransaksi: json["no_transaksi"] ?? '',
      tanggal: DateTime.parse(json["tanggal"]),
      idCustomer: json["customer_id"] ?? json["id_customer"] ?? '',
      catatan: json["catatan"] ?? '',
      salesType: json["sales_type"] ?? '',
      salesStatus: json["sales_status"] ?? '',
      paymentStatus: json["payment_status"] ?? '',
      total: (json["total"] ?? 0).toDouble(),
      diskon: (json["diskon"] ?? 0).toDouble(),
      pajak: (json["pajak"] ?? 0).toDouble(),
      reference: json["reference"] ?? '',
      tags: json["tags"] ?? '',
      details: (json["details"] as List<dynamic>?)
              ?.map((e) => SalesDetail.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class SalesDetail {
  final String productId;
  final int jumlah;
  final double harga;
  final double diskonNominal;
  final double diskonPersen;
  final double pajak;
  final String catatan;

  SalesDetail({
    required this.productId,
    required this.jumlah,
    required this.harga,
    this.diskonNominal = 0,
    this.diskonPersen = 0,
    this.pajak = 0,
    this.catatan = '',
  });

  Map<String, dynamic> toJson() {
    return {
      "product_id": productId,
      "jumlah": jumlah,
      "harga": harga,
      "diskon_nominal": diskonNominal,
      "diskon_persen": diskonPersen,
      "pajak": pajak,
      "catatan": catatan,
    };
  }

  factory SalesDetail.fromJson(Map<String, dynamic> json) {
    return SalesDetail(
      productId: json["product_id"] ?? '',
      jumlah: json["jumlah"] ?? 0,
      harga: (json["harga"] ?? 0).toDouble(),
      diskonNominal: (json["diskon_nominal"] ?? 0).toDouble(),
      diskonPersen: (json["diskon_persen"] ?? 0).toDouble(),
      pajak: (json["pajak"] ?? 0).toDouble(),
      catatan: json["catatan"] ?? '',
    );
  }
}
