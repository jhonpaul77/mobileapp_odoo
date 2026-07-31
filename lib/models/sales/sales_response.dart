import 'package:nextpsa/models/sales/sales.dart';

class SalesResponse {
  final bool success;
  final String message;
  final List<Sales>? data;
  final Sales? singleData;

  SalesResponse({
    required this.success,
    required this.message,
    this.data,
    this.singleData,
  });

  // ✅ Universal handler untuk berbagai bentuk response
  factory SalesResponse.fromJson(Map<String, dynamic> json) {
    final rawData = json['Data'] ?? json['data'];
    if (rawData is List) {
      // kalau API kirim list
      return SalesResponse.fromJsonList(json);
    } else if (rawData is Map<String, dynamic>) {
      // kalau API kirim single object
      return SalesResponse.fromJsonSingle(json);
    } else {
      // kalau API tidak punya data
      return SalesResponse.fromJsonNoData(json);
    }
  }

  factory SalesResponse.fromJsonList(Map<String, dynamic> json) {
    final data = json['Data'] ?? json['data'];
    return SalesResponse(
      success: json['Success'] ?? json['success'] ?? false,
      message: json['Message'] ?? json['message'] ?? '',
      data: data != null
          ? List<Sales>.from((data as List).map((e) => Sales.fromJson(e)))
          : null,
    );
  }

  factory SalesResponse.fromJsonSingle(Map<String, dynamic> json) {
    final data = json['Data'] ?? json['data'];
    return SalesResponse(
      success: json['Success'] ?? json['success'] ?? false,
      message: json['Message'] ?? json['message'] ?? '',
      singleData: (data != null && data is Map<String, dynamic>)
          ? Sales.fromJson(data)
          : null,
    );
  }

  factory SalesResponse.fromJsonNoData(Map<String, dynamic> json) {
    return SalesResponse(
      success: json['Success'] ?? json['success'] ?? false,
      message: json['Message'] ?? json['message'] ?? '',
    );
  }
}

