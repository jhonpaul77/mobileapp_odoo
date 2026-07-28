/// Customer Entity - Domain Layer
///
/// Represents Odoo customer data structure
/// Based on API: GET /get_customer
class Customer {
  final int id;
  final String name;
  final String? phone;
  final String? street;
  final String? city;
  final List<dynamic>? stateId; // [id, name]
  final String? zip;
  final List<dynamic>? countryId; // [id, name]
  final String? email;

  Customer({
    required this.id,
    required this.name,
    this.phone,
    this.street,
    this.city,
    this.stateId,
    this.zip,
    this.countryId,
    this.email,
  });

  /// Factory constructor from JSON (Odoo API response)
  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: _parseInt(json['id']),
      name: json['name'] as String,
      phone: _parseStringOrFalse(json['phone']),
      street: _parseStringOrFalse(json['street']),
      city: _parseStringOrFalse(json['city']),
      stateId: _parseArrayOrFalse(json['state_id']),
      zip: _parseStringOrFalse(json['zip']),
      countryId: _parseArrayOrFalse(json['country_id']),
      email: _parseStringOrFalse(json['email']),
    );
  }

  /// Helper: Parse int from dynamic value
  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.parse(value);
    throw Exception('Cannot parse id: $value');
  }

  /// Helper: Parse string or false (Odoo returns false for empty fields)
  static String? _parseStringOrFalse(dynamic value) {
    if (value == null || value == false) return null;
    return value.toString();
  }

  /// Helper: Parse array or false (Odoo returns false for empty relational fields)
  static List<dynamic>? _parseArrayOrFalse(dynamic value) {
    if (value == null || value == false) return null;
    if (value is List) return value;
    return null;
  }

  /// Convert to JSON for API requests
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'street': street,
      'city': city,
      'state_id': stateId != null && stateId!.isNotEmpty ? stateId![0] : null,
      'zip': zip,
      'email': email,
    };
  }

  /// Get state name from state_id array
  String? get stateName =>
      stateId != null && stateId!.length > 1 ? stateId![1] as String : null;

  /// Get country name from country_id array
  String? get countryName => countryId != null && countryId!.length > 1
      ? countryId![1] as String
      : null;

  /// Get full address as single string
  String get fullAddress {
    final parts = <String>[];
    if (street != null && street!.isNotEmpty) parts.add(street!);
    if (city != null && city!.isNotEmpty) parts.add(city!);
    if (stateName != null) parts.add(stateName!);
    if (zip != null && zip!.isNotEmpty) parts.add(zip!);
    return parts.join(', ');
  }

  /// Copy with method for immutability
  Customer copyWith({
    int? id,
    String? name,
    String? phone,
    String? street,
    String? city,
    List<dynamic>? stateId,
    String? zip,
    List<dynamic>? countryId,
    String? email,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      street: street ?? this.street,
      city: city ?? this.city,
      stateId: stateId ?? this.stateId,
      zip: zip ?? this.zip,
      countryId: countryId ?? this.countryId,
      email: email ?? this.email,
    );
  }
}
