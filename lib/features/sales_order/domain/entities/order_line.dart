/// OrderLine Entity - Domain Layer
///
/// Represents a single line item in a sales order
class OrderLine {
  final int id;
  final List<dynamic>? productId; // [id, name]
  final double productUomQty;
  final double priceUnit;
  final double priceSubtotal;

  OrderLine({
    required this.id,
    this.productId,
    required this.productUomQty,
    required this.priceUnit,
    required this.priceSubtotal,
  });

  factory OrderLine.fromJson(Map<String, dynamic> json) {
    return OrderLine(
      id: json['id'] as int,
      productId: json['product_id'] as List<dynamic>?,
      productUomQty: (json['product_uom_qty'] as num?)?.toDouble() ?? 0.0,
      priceUnit: (json['price_unit'] as num?)?.toDouble() ?? 0.0,
      priceSubtotal: (json['price_subtotal'] as num?)?.toDouble() ?? 0.0,
    );
  }

  /// Get product name from productId array
  String get productName => productId != null && productId!.length > 1
      ? productId![1] as String
      : 'Unknown Product';

  /// Get product ID
  int? get productIdValue =>
      productId != null && productId!.isNotEmpty ? productId![0] as int : null;
}
