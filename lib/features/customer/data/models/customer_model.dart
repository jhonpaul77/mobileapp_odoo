import '../../domain/entities/customer.dart';

/// Customer Model (DTO) - Data Transfer Object for API communication
///
/// Matches the Odoo API response structure.
/// Converts between API JSON and domain Entity.
class CustomerModel {
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

  const CustomerModel({
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

  /// Creates CustomerModel from JSON response
  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    return CustomerModel(
      id: json['id'] as int,
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

  /// Helper: Parse string or false (Odoo returns false for empty fields)
  static String? _parseStringOrFalse(dynamic value) {
    if (value == null || value == false) return null;
    return value.toString();
  }

  /// Helper: Parse int or null (handles false values)
  static int? _parseIntOrNull(dynamic value) {
    if (value == null || value == false) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  /// Converts CustomerModel to JSON for API requests
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

  /// Converts CustomerModel (DTO) to Customer (Entity)
  Customer toEntity() {
    return Customer(
      id: id,
      name: name,
      email: email,
      phone: phone,
      userId: userId,
      street: street,
      street2: street2,
      districtId: districtId,
      cityId: cityId,
      stateId: stateId,
      zip: zip,
      countryId: countryId,
    );
  }

  /// Creates CustomerModel from Customer (Entity)
  factory CustomerModel.fromEntity(Customer customer) {
    return CustomerModel(
      id: customer.id,
      name: customer.name,
      email: customer.email,
      phone: customer.phone,
      userId: customer.userId,
      street: customer.street,
      street2: customer.street2,
      districtId: customer.districtId,
      cityId: customer.cityId,
      stateId: customer.stateId,
      zip: customer.zip,
      countryId: customer.countryId,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CustomerModel &&
        other.id == id &&
        other.name == name &&
        other.email == email &&
        other.phone == phone &&
        other.userId == userId &&
        other.street == street &&
        other.street2 == street2 &&
        other.districtId == districtId &&
        other.cityId == cityId &&
        other.stateId == stateId &&
        other.zip == zip &&
        other.countryId == countryId;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      name,
      email,
      phone,
      userId,
      street,
      street2,
      districtId,
      cityId,
      stateId,
      zip,
      countryId,
    );
  }

  @override
  String toString() {
    return 'CustomerModel(id: $id, name: $name, street: $street, zip: $zip, phone: $phone, email: $email)';
  }
}
