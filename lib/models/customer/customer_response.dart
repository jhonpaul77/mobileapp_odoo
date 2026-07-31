import 'package:nextpsa/models/customer/customer.dart';

class CustomerResponse {
  final bool success;
  final String message;
  final List<Customer>? data;
  final Customer? singleData;

  CustomerResponse({
    required this.success,
    required this.message,
    this.data,
    this.singleData,
  });

  // ✅ For list response
  factory CustomerResponse.fromJsonList(Map<String, dynamic> json) {
    final data = json['Data'] ?? json['data'];
    return CustomerResponse(
      success: json['Success'] ?? json['success'] ?? false,
      message: json['Message'] ?? json['message'] ?? '',
      data: data != null
          ? (data as List).map((e) => Customer.fromJson(e)).toList()
          : null,
    );
  }

  // ✅ For single item response
  factory CustomerResponse.fromJsonSingle(Map<String, dynamic> json) {
    final data = json['Data'] ?? json['data'];
    return CustomerResponse(
      success: json['Success'] ?? json['success'] ?? false,
      message: json['Message'] ?? json['message'] ?? '',
      singleData: data != null ? Customer.fromJson(data) : null,
    );
  }

  // ✅ For delete response
  factory CustomerResponse.fromJsonNoData(Map<String, dynamic> json) {
    return CustomerResponse(
      success: json['Success'] ?? json['success'] ?? false,
      message: json['Message'] ?? json['message'] ?? '',
    );
  }
}

