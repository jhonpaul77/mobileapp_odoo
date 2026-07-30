/// Analytic Distribution Entity
class Analytic {
  final int id;
  final String name;
  final dynamic code; // Usually false from API

  Analytic({
    required this.id,
    required this.name,
    this.code,
  });

  factory Analytic.fromJson(Map<String, dynamic> json) {
    return Analytic(
      id: json['id'] as int,
      name: json['name'] as String,
      code: json['code'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
    };
  }

  @override
  String toString() => name;
}
