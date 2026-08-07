/// Product Entity - Business object for Product
///
/// Represents a product in the domain layer.
/// This is a pure business object with no external dependencies.
class Product {
  final int id;
  final String type;           // "service", "consu", "product", etc
  final bool isStorable;       // true = ada stok, false = jasa/layanan
  final String name;
  final double listPrice;
  final String? defaultCode;   // SKU

  const Product({
    required this.id,
    required this.type,
    required this.isStorable,
    required this.name,
    required this.listPrice,
    this.defaultCode,
  });

  /// Create Product from JSON/Map (from local database or API)
  factory Product.fromJson(Map<String, dynamic> json) {
    // Parse is_storable - handle both bool and int types
    bool isStorableValue = false;
    final isStorableField = json['is_storable'];
    if (isStorableField is bool) {
      isStorableValue = isStorableField;
    } else if (isStorableField is int) {
      isStorableValue = isStorableField == 1;
    }
    
    return Product(
      id: json['id'] as int,
      type: json['type'] as String? ?? 'product',
      isStorable: isStorableValue,
      name: json['name'] as String,
      listPrice: (json['list_price'] as num?)?.toDouble() ?? 0.0,
      defaultCode: json['default_code'] as String?,
    );
  }

  /// Convert Product to JSON/Map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'is_storable': isStorable ? 1 : 0,
      'name': name,
      'list_price': listPrice,
      'default_code': defaultCode,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Product &&
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
    return 'Product(id: $id, type: $type, isStorable: $isStorable, name: $name, listPrice: $listPrice, defaultCode: $defaultCode)';
  }
}
