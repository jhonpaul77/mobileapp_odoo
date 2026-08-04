import 'order_line.dart';

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
  final int fuCount; // Follow-up count from API - u_count field
  final List<OrderLine> orderLines;
  final String? partnerPhone; // Partner phone number
  final String? partnerStreet; // Partner street address
  final String? partnerStreet2; // Partner street2 address
  final String? partnerDistrict; // Partner district
  final String? partnerCity; // Partner city
  final String? partnerState; // Partner state/province
  final String? notes; // Order notes
  final int? paymentTermId; // Payment term ID
  final String? paymentTermName; // Payment term name

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
    required this.fuCount,
    required this.orderLines,
    this.partnerPhone,
    this.partnerStreet,
    this.partnerStreet2,
    this.partnerDistrict,
    this.partnerCity,
    this.partnerState,
    this.notes,
    this.paymentTermId,
    this.paymentTermName,
  });

  factory SalesOrder.fromJson(Map<String, dynamic> json) {
    // DEBUG: Print all available fields
    print('📋 [SALES_ORDER] JSON keys: ${json.keys.toList()}');
    print('📋 [SALES_ORDER] Full JSON: $json');

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
    if (partnerNameRaw is String && partnerNameRaw.isNotEmpty) {
      partnerNameParsed = partnerNameRaw;
    }

    // Safely parse phone - can be string or false
    String? partnerPhoneParsed;
    final partnerPhoneRaw = json['partner_phone'];
    if (partnerPhoneRaw is String && partnerPhoneRaw.isNotEmpty) {
      partnerPhoneParsed = partnerPhoneRaw;
    }

    // Parse warehouse_name - can be string or false
    String? warehouseNameParsed;
    final warehouseNameRaw = json['warehouse_name'];
    if (warehouseNameRaw is String && warehouseNameRaw.isNotEmpty) {
      warehouseNameParsed = warehouseNameRaw;
    }

    // Parse kurir_name - can be string or false
    String? kurirNameParsed;
    final kurirNameRaw = json['kurir_name'];
    if (kurirNameRaw is String && kurirNameRaw.isNotEmpty) {
      kurirNameParsed = kurirNameRaw;
    }

    // Safely parse AWB - can be string or false
    dynamic awbParsed;
    final awbRaw = json['awb'];
    if (awbRaw is String && awbRaw.isNotEmpty) {
      awbParsed = awbRaw;
    } else if (awbRaw is bool || awbRaw == null) {
      awbParsed = null;
    } else {
      awbParsed = awbRaw;
    }

    // Safely parse address - ensure it's string
    String? partnerStreetParsed;
    final partnerStreetRaw = json['partner_street'];
    if (partnerStreetRaw is String && partnerStreetRaw.isNotEmpty) {
      partnerStreetParsed = partnerStreetRaw;
    }

    // Safely parse street2 - ensure it's string
    String? partnerStreet2Parsed;
    final partnerStreet2Raw = json['partner_street2'];
    if (partnerStreet2Raw is String && partnerStreet2Raw.isNotEmpty) {
      partnerStreet2Parsed = partnerStreet2Raw;
    }

    // Safely parse district - ensure it's string
    String? partnerDistrictParsed;
    final partnerDistrictRaw = json['partner_district'];
    if (partnerDistrictRaw is String && partnerDistrictRaw.isNotEmpty) {
      partnerDistrictParsed = partnerDistrictRaw;
    }

    // Safely parse city - ensure it's string
    String? partnerCityParsed;
    final partnerCityRaw = json['partner_city'];
    if (partnerCityRaw is String && partnerCityRaw.isNotEmpty) {
      partnerCityParsed = partnerCityRaw;
    }

    // Safely parse state - ensure it's string
    String? partnerStateParsed;
    final partnerStateRaw = json['partner_state'];
    if (partnerStateRaw is String && partnerStateRaw.isNotEmpty) {
      partnerStateParsed = partnerStateRaw;
    }

    // Safely parse notes - ensure it's string
    String? notesParsed;
    final notesRaw = json['notes'];
    if (notesRaw is String && notesRaw.isNotEmpty) {
      notesParsed = notesRaw;
    }

    // Parse payment term - can be int or [id, name] array
    int? paymentTermIdParsed;
    String? paymentTermNameParsed;
    final paymentTermRaw = json['payment_term_id'];
    if (paymentTermRaw is int) {
      paymentTermIdParsed = paymentTermRaw;
    } else if (paymentTermRaw is List && paymentTermRaw.length > 0) {
      paymentTermIdParsed = paymentTermRaw[0] as int?;
      if (paymentTermRaw.length > 1) {
        paymentTermNameParsed = paymentTermRaw[1] as String?;
      }
    }

    // Also check for direct payment_term_name field
    final paymentTermNameRaw = json['payment_term_name'];
    if (paymentTermNameRaw is String && paymentTermNameRaw.isNotEmpty) {
      paymentTermNameParsed = paymentTermNameRaw;
    }

    // Safely parse fu_count - can be int, double, string, or other types
    int fuCountParsed = _parseFuCount(json['fu_count']);

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
      awb: awbParsed,
      state: json['state'] as String? ?? 'draft',
      orderCount: json['order_count'] as int?,
      fuCount: fuCountParsed,
      orderLines: orderLines,
      partnerPhone: partnerPhoneParsed,
      partnerStreet: partnerStreetParsed,
      partnerStreet2: partnerStreet2Parsed,
      partnerDistrict: partnerDistrictParsed,
      partnerCity: partnerCityParsed,
      partnerState: partnerStateParsed,
      notes: notesParsed,
      paymentTermId: paymentTermIdParsed,
      paymentTermName: paymentTermNameParsed,
    );
  }

  /// Helper: Parse int from dynamic value
  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.parse(value);
    throw Exception('Cannot parse id: $value');
  }

  /// Helper: Safely parse fu_count from various types
  static int _parseFuCount(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      try {
        return int.parse(value);
      } catch (e) {
        print('⚠️ [SALES_ORDER] Could not parse fu_count string: $value');
        return 0;
      }
    }
    print('⚠️ [SALES_ORDER] Unknown fu_count type: ${value.runtimeType} = $value');
    return 0;
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
    if (kurirName != null && kurirName!.isNotEmpty) {
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

  /// Format date for display (with time)
  String get dateOrderFormatted {
    final date = dateOrderParsed;
    if (date == null) return dateOrder;

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year;
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'partner_id': partnerId,
      'partner_name': partnerName,
      'partner_phone': partnerPhone,
      'date_order': dateOrder,
      'amount_total': amountTotal,
      'warehouse_id': warehouseId,
      'warehouse_name': warehouseName,
      'kurir_id': kurirId,
      'kurir_name': kurirName,
      'awb': awb,
      'state': state,
      'order_count': orderCount,
      'fu_count': fuCount,
      'order_lines': orderLines.map((line) => line.toJson()).toList(),
      'partner_street': partnerStreet,
      'partner_street2': partnerStreet2,
      'partner_district': partnerDistrict,
      'partner_city': partnerCity,
      'partner_state': partnerState,
      'notes': notes,
      'payment_term_id': paymentTermId,
      'payment_term_name': paymentTermName,
    };
  }
}
