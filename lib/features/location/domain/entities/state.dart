/// State Entity
class State {
  final int id;
  final String name;
  final String code;
  final int countryId;

  State({
    required this.id,
    required this.name,
    required this.code,
    required this.countryId,
  });

  factory State.fromJson(Map<String, dynamic> json) {
    return State(
      id: _parseInt(json['id']),
      name: json['name'] as String,
      code: json['code'] as String,
      countryId: _parseInt(json['country_id']),
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
      'country_id': countryId,
    };
  }
}
