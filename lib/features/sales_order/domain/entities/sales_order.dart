import 'order_line.dart';

/// SalesOrder Entity - Domain Layer
///
/// Represents Odoo sales order data structure
/// Based on API: GET /get_sale_order
///
/// API Response Example:
/// {
///   "id": 4223,
///   "name": "S00031",
///   "partner_id": 32763,
///   "date_order": "2026-07-22",
///   "amount_total": 85000.0,
///   "warehouse_id": 1,
///   "kurir_id": false,
///   "awb": false,
///   "state": "draft",
///   "order_lines": [...]
/// }
class SalesOrder {
  final int id;
  final String name;
  final dynamic partnerId; // Can be int or [id, name]
  final String dateOrder;
  final double amountTotal;
  final dynamic warehouseId; // Can be int or [id, name]
  final dynamic kurirId; // Can be false or int/array
  final dynamic awb; // Can be false or string
  final String state;
  final List<OrderLine> orderLines;
  final String? address;
  final String? district;
  final String? city;

  SalesOrder({
    required this.id,
    required this.name,
    this.partnerId,
    required this.dateOrder,
    required this.amountTotal,
    this.warehouseId,
    this.kurirId,
    this.awb,
    required this.state,
    required this.orderLines,
    this.address,
    this.district,
    this.city,
  });

  factory SalesOrder.fromJson(Map<String, dynamic> json) {
    // Parse order lines from 'order_lines' field
    final orderLinesJson = json['order_lines'] as List<dynamic>? ??
        json['order_line'] as List<dynamic>? ??
        [];
    final orderLines = orderLinesJson
        .map((line) => OrderLine.fromJson(line as Map<String, dynamic>))
        .toList();

    return SalesOrder(
      id: _parseInt(json['id']),
      name: json['name'] as String,
      partnerId: json['partner_id'], // Can be int or array
      dateOrder: json['date_order'] as String,
      amountTotal: (json['amount_total'] as num?)?.toDouble() ?? 0.0,
      warehouseId: json['warehouse_id'],
      kurirId: json['kurir_id'],
      awb: json['awb'],
      state: json['state'] as String? ?? 'draft',
      orderLines: orderLines,
      address: json['address'] as String?,
      district: json['district'] as String?,
      city: json['city'] as String?,
    );
  }

  /// Helper: Parse int from dynamic value
  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.parse(value);
    throw Exception('Cannot parse id: $value');
  }

  /// Get customer name from partnerId
  String get customerName {
    if (partnerId == null || partnerId == false) return 'Unknown Customer';
    if (partnerId is List && partnerId.length > 1) {
      return partnerId[1] as String;
    }
    return 'Customer #$partnerId';
  }

  /// Get customer ID
  int? get customerId {
    if (partnerId == null || partnerId == false) return null;
    if (partnerId is int) return partnerId;
    if (partnerId is List && partnerId.isNotEmpty) {
      return partnerId[0] as int;
    }
    return null;
  }

  /// Get warehouse name
  String? get warehouseName {
    if (warehouseId == null || warehouseId == false) return null;
    if (warehouseId is List && warehouseId.length > 1) {
      return warehouseId[1] as String;
    }
    return null;
  }

  /// Get kurir name
  String? get kurirName {
    if (kurirId == null || kurirId == false) return null;
    if (kurirId is List && kurirId.length > 1) {
      return kurirId[1] as String;
    }
    return null;
  }

  /// Get AWB number
  String? get awbNumber {
    if (awb == null || awb == false) return null;
    return awb.toString();
  }

  /// Get status label in Indonesian
  String get stateLabel {
    switch (state.toLowerCase()) {
      case 'draft':
        return 'Open';
      case 'sale':
        return 'Sale';
      case 'confirm':
        return 'Confirm';
      case 'cancel':
        return 'Cancel';
      default:
        return state;
    }
  }

  /// Get status color
  int get stateColor {
    switch (state.toLowerCase()) {
      case 'draft':
        return 0xFFFFA726; // Orange
      case 'sale':
        return 0xFF42A5F5; // Blue
      case 'confirm':
        return 0xFF66BB6A; // Green
      case 'cancel':
        return 0xFFEF5350; // Red
      default:
        return 0xFF757575; // Grey
    }
  }

  /// Get total quantity of items
  int get totalQty => orderLines.fold(
        0,
        (sum, line) => sum + line.productUomQty.toInt(),
      );

  /// Parse date order to DateTime
  DateTime? get dateOrderParsed {
    try {
      return DateTime.parse(dateOrder);
    } catch (e) {
      return null;
    }
  }

  /// Format date for display
  String get dateOrderFormatted {
    final date = dateOrderParsed;
    if (date == null) return dateOrder;

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year;
    return '$day/$month/$year';
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'partner_id': partnerId,
      'date_order': dateOrder,
      'amount_total': amountTotal,
      'warehouse_id': warehouseId,
      'kurir_id': kurirId,
      'awb': awb,
      'state': state,
      'order_lines': orderLines.map((line) => line.toJson()).toList(),
      'address': address,
      'district': district,
      'city': city,
    };
  }
}
