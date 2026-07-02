// File: lib/models/product_category/product_category_response.dart
import 'package:pintarx/models/product/product_category/product_category.dart';

class ProductCategoryResponse {
  final bool success;
  final String message;
  final List<ProductCategory>? data;
  final ProductCategory? singleData;

  ProductCategoryResponse({
    required this.success,
    required this.message,
    this.data,
    this.singleData,
  });

  factory ProductCategoryResponse.fromJsonList(Map<String, dynamic> json) {
    final data = json['Data'] ?? json['data'];
    return ProductCategoryResponse(
      success: json['Success'] ?? json['success'] ?? false,
      message: json['Message'] ?? json['message'] ?? '',
      data: data != null
          ? (data as List).map((e) => ProductCategory.fromJson(e)).toList()
          : null,
    );
  }

  factory ProductCategoryResponse.fromJsonSingle(Map<String, dynamic> json) {
    final data = json['Data'] ?? json['data'];
    return ProductCategoryResponse(
      success: json['Success'] ?? json['success'] ?? false,
      message: json['Message'] ?? json['message'] ?? '',
      singleData: data != null ? ProductCategory.fromJson(data) : null,
    );
  }

  factory ProductCategoryResponse.fromJsonNoData(Map<String, dynamic> json) {
    return ProductCategoryResponse(
      success: json['Success'] ?? json['success'] ?? false,
      message: json['Message'] ?? json['message'] ?? '',
    );
  }
}