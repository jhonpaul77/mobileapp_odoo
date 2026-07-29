import '../../domain/entities/customer.dart';

/// Customer Model (DTO) - Data Transfer Object for API communication
///
/// Matches the Odoo API response structure.
/// Converts between API JSON and domain Entity.
class CustomerModel {
  final int id;
  final String name;
  final String? street;
  final String? city;
  final List<dynamic>? stateId; // [id, name]
  final String? zip;
  final List<dynamic>? countryId; // [id, name]
  final String? phone;
  final String? email;

  const CustomerModel({
    required this.id,
    required this.name,
    this.street,
    this.city,
    this.stateId,
    this.zip,
    this.countryId,
    this.phone,
    this.email,
  });

  /// Creates CustomerModel from JSON response
  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    return CustomerModel(
      id: json['id'] as int,
      name: json['name'] as String,
      street: _parseStringOrFalse(json['street']),
      city: _parseStringOrFalse(json['city']),
      stateId: _parseArrayOrFalse(json['state_id']),
      zip: _parseStringOrFalse(json['zip']),
      countryId: _parseArrayOrFalse(json['country_id']),
      phone: _parseStringOrFalse(json['phone']),
      email: _parseStringOrFalse(json['email']),
    );
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

  /// Converts CustomerModel to JSON for API requests
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'street': street,
      'city': city,
      'state_id': stateId,
      'zip': zip,
      'country_id': countryId,
      'phone': phone,
      'email': email,
    };
  }

  /// Converts CustomerModel (DTO) to Customer (Entity)
  Customer toEntity() {
    return Customer(
      id: id,
      name: name,
      street: street,
      city: city,
      stateId: stateId,
      zip: zip,
      countryId: countryId,
      phone: phone,
      email: email,
    );
  }

  /// Creates CustomerModel from Customer (Entity)
  factory CustomerModel.fromEntity(Customer customer) {
    return CustomerModel(
      id: customer.id,
      name: customer.name,
      street: customer.street,
      city: customer.city,
      stateId: customer.stateId,
      zip: customer.zip,
      countryId: customer.countryId,
      phone: customer.phone,
      email: customer.email,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CustomerModel &&
        other.id == id &&
        other.name == name &&
        other.street == street &&
        other.city == city &&
        other.stateId == stateId &&
        other.zip == zip &&
        other.countryId == countryId &&
        other.phone == phone &&
        other.email == email;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      name,
      street,
      city,
      stateId,
      zip,
      countryId,
      phone,
      email,
    );
  }

  @override
  String toString() {
    return 'CustomerModel(id: $id, name: $name, city: $city, phone: $phone, email: $email)';
  }
}
