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
///   "partner_name": "0piandi (6283833303500)",
///   "date_order": "2026-07-22",
///   "amount_total": 85000.0,
///   "warehouse_id": 1,
///   "warehouse_name": "SURABAYA",
///   "kurir_id": 24,
///   "kurir_name": "IDX",
///   "awb": "JD009833",
///   "state": "draft",
///   "order_count": 1,
///   "order_lines": [...]
/// }
class SalesOrder {
  final int id;
  final String name;
  final dynamic partnerId; // Can be int or [id, name]
  final String? partnerName; // From API - customer name with phone
  final String dateOrder;
  final double amountTotal;
  final dynamic warehouseId; // Can be int or [id, name]
  final String? warehouseName; // From API
  final dynamic kurirId; // Can be false or int/array
  final String? kurirName; // From API
  final dynamic awb; // Can be false or string
  final String state;
  final int? orderCount; // From API - number of orders for this customer
  final List<OrderLine> orderLines;
  final String? address;
  final String? district;
  final String? city;

  SalesOrder({
    required this.id,
    required this.name,
    this.partnerId,
    this.partnerName,
    required this.dateOrder,
    required this.amountTotal,
    this.warehouseId,
    this.warehouseName,
    this.kurirId,
    this.kurirName,
    this.awb,
    required this.state,
    this.orderCount,
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

    // Parse partner_name - can be string or false
    String? partnerNameParsed;
    final partnerNameRaw = json['partner_name'];
    if (partnerNameRaw is String) {
      partnerNameParsed = partnerNameRaw;
    }

    // Parse warehouse_name - can be string or false
    String? warehouseNameParsed;
    final warehouseNameRaw = json['warehouse_name'];
    if (warehouseNameRaw is String) {
      warehouseNameParsed = warehouseNameRaw;
    }

    // Parse kurir_name - can be string or false
    String? kurirNameParsed;
    final kurirNameRaw = json['kurir_name'];
    if (kurirNameRaw is String) {
      kurirNameParsed = kurirNameRaw;
    }

    return SalesOrder(
      id: _parseInt(json['id']),
      name: json['name'] as String,
      partnerId: json['partner_id'], // Can be int or array
      partnerName: partnerNameParsed,
      dateOrder: json['date_order'] as String,
      amountTotal: (json['amount_total'] as num?)?.toDouble() ?? 0.0,
      warehouseId: json['warehouse_id'],
      warehouseName: warehouseNameParsed,
      kurirId: json['kurir_id'],
      kurirName: kurirNameParsed,
      awb: json['awb'],
      state: json['state'] as String? ?? 'draft',
      orderCount: json['order_count'] as int?,
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

  /// Get customer name - use API value if available, otherwise fallback
  String get customerName {
    if (partnerName != null && partnerName!.isNotEmpty) {
      return partnerName!;
    }
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

  /// Get warehouse name - use API value if available
  String? get warehouseNameDisplay {
    if (warehouseName != null && warehouseName!.isNotEmpty) {
      return warehouseName;
    }
    if (warehouseId == null || warehouseId == false) return null;
    if (warehouseId is List && warehouseId.length > 1) {
      return warehouseId[1] as String;
    }
    return null;
  }

  /// Get kurir name - use API value if available
  String? get kurirNameDisplay {
    if (kurirName != null && kurirName != false) {
      return kurirName;
    }
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
      'partner_name': partnerName,
      'date_order': dateOrder,
      'amount_total': amountTotal,
      'warehouse_id': warehouseId,
      'warehouse_name': warehouseName,
      'kurir_id': kurirId,
      'kurir_name': kurirName,
      'awb': awb,
      'state': state,
      'order_count': orderCount,
      'order_lines': orderLines.map((line) => line.toJson()).toList(),
      'address': address,
      'district': district,
      'city': city,
    };
  }
}
