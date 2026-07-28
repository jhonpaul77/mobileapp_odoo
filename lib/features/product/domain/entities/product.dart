/// Product Entity - Business object for Product
///
/// Represents a product in the domain layer.
/// This is a pure business object with no external dependencies.
class Product {
  final int id;
  final String type;
  final bool isStorable;
  final String name;
  final double listPrice;
  final String? defaultCode;

  const Product({
    required this.id,
    required this.type,
    required this.isStorable,
    required this.name,
    required this.listPrice,
    this.defaultCode,
  });

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
