import 'package:pintarx/models/organization/organization.dart';

class OrganizationResponse {
  final bool success;
  final String message;
  final List<Organization>? data;
  final Organization? singleData;

  OrganizationResponse({
    required this.success,
    required this.message,
    this.data,
    this.singleData,
  });

  // ✅ For list response
  factory OrganizationResponse.fromJsonList(Map<String, dynamic> json) {
    final data = json['Data'] ?? json['data'];
    return OrganizationResponse(
      success: json['Success'] ?? json['success'] ?? false,
      message: json['Message'] ?? json['message'] ?? '',
      data: data != null
          ? (data as List).map((e) => Organization.fromJson(e)).toList()
          : null,
    );
  }

  // ✅ For single item response
  factory OrganizationResponse.fromJsonSingle(Map<String, dynamic> json) {
    final data = json['Data'] ?? json['data'];
    return OrganizationResponse(
      success: json['Success'] ?? json['success'] ?? false,
      message: json['Message'] ?? json['message'] ?? '',
      singleData: data != null ? Organization.fromJson(data) : null,
    );
  }

  // ✅ For delete response
  factory OrganizationResponse.fromJsonNoData(Map<String, dynamic> json) {
    return OrganizationResponse(
      success: json['Success'] ?? json['success'] ?? false,
      message: json['Message'] ?? json['message'] ?? '',
    );
  }
}
