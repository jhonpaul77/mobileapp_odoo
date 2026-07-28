/// OrderLine Entity - Domain Layer
///
/// Represents a single line item in a sales order
///
/// API Response Example:
/// {
///   "product_id": 1186,
///   "product_uom_qty": 1.0,
///   "analytic_distribution": {"27": 100.0},
///   "price_unit": 85000.0
/// }
class OrderLine {
  final dynamic productId; // Can be int or [id, name]
  final double productUomQty;
  final Map<String, dynamic>? analyticDistribution;
  final double priceUnit;
  final double? priceSubtotal;

  OrderLine({
    required this.productId,
    required this.productUomQty,
    this.analyticDistribution,
    required this.priceUnit,
    this.priceSubtotal,
  });

  factory OrderLine.fromJson(Map<String, dynamic> json) {
    return OrderLine(
      productId: json['product_id'],
      productUomQty: (json['product_uom_qty'] as num?)?.toDouble() ?? 0.0,
      analyticDistribution:
          json['analytic_distribution'] as Map<String, dynamic>?,
      priceUnit: (json['price_unit'] as num?)?.toDouble() ?? 0.0,
      priceSubtotal: (json['price_subtotal'] as num?)?.toDouble(),
    );
  }

  /// Get product name from productId
  String get productName {
    if (productId == null || productId == false) return 'Unknown Product';
    if (productId is List && productId.length > 1) {
      return productId[1] as String;
    }
    return 'Product #$productId';
  }

  /// Get product ID value
  int? get productIdValue {
    if (productId == null || productId == false) return null;
    if (productId is int) return productId;
    if (productId is List && productId.isNotEmpty) {
      return productId[0] as int;
    }
    return null;
  }

  /// Calculate subtotal (qty * price)
  double get calculatedSubtotal {
    return priceSubtotal ?? (productUomQty * priceUnit);
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'product_uom_qty': productUomQty,
      'analytic_distribution': analyticDistribution,
      'price_unit': priceUnit,
      if (priceSubtotal != null) 'price_subtotal': priceSubtotal,
    };
  }
}
