/// City Entity
class City {
  final int id;
  final String name;
  final String code;
  final int stateId;

  City({
    required this.id,
    required this.name,
    required this.code,
    required this.stateId,
  });

  factory City.fromJson(Map<String, dynamic> json) {
    return City(
      id: _parseInt(json['id']),
      name: json['name'] as String,
      code: json['code'] as String,
      stateId: _parseInt(json['state_id']),
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
      'state_id': stateId,
    };
  }
}
