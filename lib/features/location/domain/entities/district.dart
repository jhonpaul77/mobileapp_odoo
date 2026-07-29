import 'city.dart';
import 'state.dart';

/// District Entity
class District {
  final int id;
  final String name;
  final String code;
  final int cityId;
  final City? city; // Optional city with full data
  final State? state; // Optional state with full data

  District({
    required this.id,
    required this.name,
    required this.code,
    required this.cityId,
    this.city,
    this.state,
  });

  factory District.fromJson(Map<String, dynamic> json) {
    return District(
      id: _parseInt(json['id']),
      name: json['name'] as String,
      code: json['code'] as String,
      cityId: _parseInt(json['city_id']),
      city: json['city'] != null ? City.fromJson(json['city']) : null,
      state: json['state'] != null ? State.fromJson(json['state']) : null,
    );
  }

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'city_id': cityId,
      if (city != null) 'city': city!.toJson(),
      if (state != null) 'state': state!.toJson(),
    };
  }

  /// Display format: District, City, State
  String get displayName => '$name, ${city?.name ?? ''}, ${state?.name ?? ''}';
}
