/// OrderLine Entity - Domain Layer
///
/// Represents a single line item in a sales order
///
/// API Response Example:
/// {
///   "product_id": 1432,
///   "product_name": "Antishock B1+ 500 Ml (TT)",
///   "product_uom_qty": 1.0,
///   "analytic_distribution": "Bestree Store",
///   "price_unit": 55000.0
/// }
class OrderLine {
  final dynamic productId; // Can be int or [id, name]
  final String? productName; // From API - product name
  final double productUomQty;
  final dynamic analyticDistribution; // Can be String or Map<String, dynamic>
  final double priceUnit;
  final double? priceSubtotal;

  OrderLine({
    required this.productId,
    this.productName,
    required this.productUomQty,
    this.analyticDistribution,
    required this.priceUnit,
    this.priceSubtotal,
  });

  factory OrderLine.fromJson(Map<String, dynamic> json) {
    // Parse analytic_distribution - can be String, Map, or false
    dynamic analyticDist;
    final analyticRaw = json['analytic_distribution'];
    if (analyticRaw is String && analyticRaw.isNotEmpty) {
      analyticDist = analyticRaw;
    } else if (analyticRaw is Map<String, dynamic>) {
      analyticDist = analyticRaw;
    } else {
      // If false, null, or any other type, treat as null
      analyticDist = null;
    }

    // Parse product_name - can be string or false
    String? productNameParsed;
    final productNameRaw = json['product_name'];
    if (productNameRaw is String && productNameRaw.isNotEmpty) {
      productNameParsed = productNameRaw;
    }

    return OrderLine(
      productId: json['product_id'],
      productName: productNameParsed,
      productUomQty: (json['product_uom_qty'] as num?)?.toDouble() ?? 0.0,
      analyticDistribution: analyticDist,
      priceUnit: (json['price_unit'] as num?)?.toDouble() ?? 0.0,
      priceSubtotal: (json['price_subtotal'] as num?)?.toDouble(),
    );
  }

  /// Get analytic distribution name
  String get analyticDistributionName {
    if (analyticDistribution == null || analyticDistribution == false) {
      return '-';
    }
    if (analyticDistribution is String) {
      return analyticDistribution as String;
    }
    if (analyticDistribution is Map<String, dynamic>) {
      // If it's a Map, join the keys as a display string
      final map = analyticDistribution as Map<String, dynamic>;
      return map.keys.join(', ');
    }
    return '-';
  }

  /// Get product name - use API value if available, otherwise fallback
  String get productNameDisplay {
    if (productName != null && productName!.isNotEmpty) {
      return productName!;
    }
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
      'product_name': productName,
      'product_uom_qty': productUomQty,
      'analytic_distribution': analyticDistribution,
      'price_unit': priceUnit,
      if (priceSubtotal != null) 'price_subtotal': priceSubtotal,
    };
  }
}
