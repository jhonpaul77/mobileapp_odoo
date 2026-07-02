import 'product_group.dart';

class ProductGroupResponse {
  final bool success;
  final String message;
  final List<ProductGroup>? data;
  final ProductGroup? singleData;

  ProductGroupResponse({
    required this.success,
    required this.message,
    this.data,
    this.singleData,
  });

  // ✅ For list response
  factory ProductGroupResponse.fromJsonList(Map<String, dynamic> json) {
    final data = json['Data'] ?? json['data'];
    return ProductGroupResponse(
      success: json['Success'] ?? json['success'] ?? false,
      message: json['Message'] ?? json['message'] ?? '',
      data: data != null
          ? (data as List).map((e) => ProductGroup.fromJson(e)).toList()
          : null,
    );
  }

  // ✅ For single item response (detail, create, update)
  factory ProductGroupResponse.fromJsonSingle(Map<String, dynamic> json) {
    final data = json['Data'] ?? json['data'];
    return ProductGroupResponse(
      success: json['Success'] ?? json['success'] ?? false,
      message: json['Message'] ?? json['message'] ?? '',
      singleData: data != null ? ProductGroup.fromJson(data) : null,
    );
  }

  // ✅ For delete response (no data)
  factory ProductGroupResponse.fromJsonNoData(Map<String, dynamic> json) {
    return ProductGroupResponse(
      success: json['Success'] ?? json['success'] ?? false,
      message: json['Message'] ?? json['message'] ?? '',
    );
  }
}