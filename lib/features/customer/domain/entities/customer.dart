/// Customer Entity - Domain Layer
///
/// Represents Odoo customer data structure
/// Based on API: GET /get_customer
class Customer {
  final int id;
  final String name;
  final String? email;
  final String? phone;
  final int? userId;
  final String? street;
  final String? street2;
  final int? districtId;
  final int? cityId;
  final int? stateId;
  final String? zip;
  final int? countryId;

  Customer({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    this.userId,
    this.street,
    this.street2,
    this.districtId,
    this.cityId,
    this.stateId,
    this.zip,
    this.countryId,
  });

  /// Factory constructor from JSON (Odoo API response)
  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: _parseInt(json['id']),
      name: json['name'] as String,
      email: _parseStringOrFalse(json['email']),
      phone: _parseStringOrFalse(json['phone']),
      userId: _parseIntOrNull(json['user_id']),
      street: _parseStringOrFalse(json['street']),
      street2: _parseStringOrFalse(json['street2']),
      districtId: _parseIntOrNull(json['district_id']),
      cityId: _parseIntOrNull(json['city_id']),
      stateId: _parseIntOrNull(json['state_id']),
      zip: _parseStringOrFalse(json['zip']),
      countryId: _parseIntOrNull(json['country_id']),
    );
  }

  /// Helper: Parse int from dynamic value
  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.parse(value);
    throw Exception('Cannot parse id: $value');
  }

  /// Helper: Parse int or null (handles false values)
  static int? _parseIntOrNull(dynamic value) {
    if (value == null || value == false) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  /// Helper: Parse string or false (Odoo returns false for empty fields)
  static String? _parseStringOrFalse(dynamic value) {
    if (value == null || value == false) return null;
    return value.toString();
  }

  /// Convert to JSON for API requests
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'user_id': userId,
      'street': street,
      'street2': street2,
      'district_id': districtId,
      'city_id': cityId,
      'state_id': stateId,
      'zip': zip,
      'country_id': countryId,
    };
  }

  /// Get full address as single string
  String get fullAddress {
    final parts = <String>[];
    if (street != null && street!.isNotEmpty) parts.add(street!);
    if (street2 != null && street2!.isNotEmpty) parts.add(street2!);
    if (zip != null && zip!.isNotEmpty) parts.add(zip!);
    return parts.join(', ');
  }

  /// Copy with method for immutability
  Customer copyWith({
    int? id,
    String? name,
    String? email,
    String? phone,
    int? userId,
    String? street,
    String? street2,
    int? districtId,
    int? cityId,
    int? stateId,
    String? zip,
    int? countryId,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      userId: userId ?? this.userId,
      street: street ?? this.street,
      street2: street2 ?? this.street2,
      districtId: districtId ?? this.districtId,
      cityId: cityId ?? this.cityId,
      stateId: stateId ?? this.stateId,
      zip: zip ?? this.zip,
      countryId: countryId ?? this.countryId,
    );
  }
}
