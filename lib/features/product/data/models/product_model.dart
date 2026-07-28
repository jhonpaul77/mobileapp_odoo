import '../../domain/entities/product.dart';

/// Product Model (DTO) - Data Transfer Object for API communication
///
/// Matches the Odoo API response structure.
/// Converts between API JSON and domain Entity.
class ProductModel {
  final int id;
  final String type;
  final bool isStorable;
  final String name;
  final double listPrice;
  final dynamic defaultCode; // Can be String or false from API

  const ProductModel({
    required this.id,
    required this.type,
    required this.isStorable,
    required this.name,
    required this.listPrice,
    required this.defaultCode,
  });

  /// Creates ProductModel from JSON response
  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] as int,
      type: json['type'] as String,
      isStorable: json['is_storable'] as bool,
      name: json['name'] as String,
      listPrice: (json['list_price'] as num).toDouble(),
      defaultCode: json['default_code'],
    );
  }

  /// Converts ProductModel to JSON for API requests
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'is_storable': isStorable,
      'name': name,
      'list_price': listPrice,
      'default_code': defaultCode,
    };
  }

  /// Converts ProductModel (DTO) to Product (Entity)
  Product toEntity() {
    return Product(
      id: id,
      type: type,
      isStorable: isStorable,
      name: name,
      listPrice: listPrice,
      defaultCode: defaultCode is String ? defaultCode as String : null,
    );
  }

  /// Creates ProductModel from Product (Entity)
  factory ProductModel.fromEntity(Product product) {
    return ProductModel(
      id: product.id,
      type: product.type,
      isStorable: product.isStorable,
      name: product.name,
      listPrice: product.listPrice,
      defaultCode: product.defaultCode ?? false,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProductModel &&
        other.id == id &&
        other.type == type &&
        other.isStorable == isStorable &&
        other.name == name &&
        other.listPrice == listPrice &&
        other.defaultCode == defaultCode;
  }

  @override
  int get hashCode {
    return Object.hash(id, type, isStorable, name, listPrice, defaultCode);
  }

  @override
  String toString() {
    return 'ProductModel(id: $id, type: $type, isStorable: $isStorable, name: $name, listPrice: $listPrice, defaultCode: $defaultCode)';
  }
}
