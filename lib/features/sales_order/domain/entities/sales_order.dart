import 'order_line.dart';

/// SalesOrder Entity - Domain Layer
///
/// Represents Odoo sales order data structure
/// Based on API: GET /get_sale_order
class SalesOrder {
  final int id;
  final String name;
  final List<dynamic>? partnerId; // [id, customer_name]
  final String dateOrder;
  final double amountTotal;
  final String state;
  final List<OrderLine> orderLines;

  SalesOrder({
    required this.id,
    required this.name,
    this.partnerId,
    required this.dateOrder,
    required this.amountTotal,
    required this.state,
    required this.orderLines,
  });

  factory SalesOrder.fromJson(Map<String, dynamic> json) {
    // Parse order lines
    final orderLinesJson = json['order_line'] as List<dynamic>? ?? [];
    final orderLines = orderLinesJson
        .map((line) => OrderLine.fromJson(line as Map<String, dynamic>))
        .toList();

    return SalesOrder(
      id: json['id'] as int,
      name: json['name'] as String,
      partnerId: json['partner_id'] as List<dynamic>?,
      dateOrder: json['date_order'] as String,
      amountTotal: (json['amount_total'] as num?)?.toDouble() ?? 0.0,
      state: json['state'] as String? ?? 'draft',
      orderLines: orderLines,
    );
  }

  /// Get customer name from partnerId array
  String get customerName => partnerId != null && partnerId!.length > 1
      ? partnerId![1] as String
      : 'Unknown Customer';

  /// Get customer ID
  int? get customerId =>
      partnerId != null && partnerId!.isNotEmpty ? partnerId![0] as int : null;

  /// Get status label in Indonesian
  String get stateLabel {
    switch (state) {
      case 'draft':
        return 'Draft';
      case 'sent':
        return 'Terkirim';
      case 'sale':
        return 'Sales Order';
      case 'done':
        return 'Selesai';
      case 'cancel':
        return 'Dibatalkan';
      default:
        return state;
    }
  }

  /// Get status color
  int get stateColor {
    switch (state) {
      case 'draft':
        return 0xFFFFA726; // Orange
      case 'sent':
        return 0xFF42A5F5; // Blue
      case 'sale':
        return 0xFF66BB6A; // Green
      case 'done':
        return 0xFF9E9E9E; // Grey
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
}
