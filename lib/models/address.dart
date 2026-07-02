class Address {
  final String? id;
  final String name;
  final String phone;
  final String province;
  final String city;
  final String district;
  final String fullAddress;

  Address({
    this.id,
    required this.name,
    required this.phone,
    required this.province,
    required this.city,
    required this.district,
    required this.fullAddress,
  });

  Map<String, dynamic> toJson() {
    return {
      "name": name,
      "phone": phone,
      "province": province,
      "city": city,
      "district": district,
      "full_address": fullAddress,
    };
  }

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      id: json["id"],
      name: json["name"] ?? '',
      phone: json["phone"] ?? '',
      province: json["province"] ?? '',
      city: json["city"] ?? '',
      district: json["district"] ?? '',
      fullAddress: json["full_address"] ?? json["fullAddress"] ?? '',
    );
  }

  Address copyWith({
    String? id,
    String? name,
    String? phone,
    String? province,
    String? city,
    String? district,
    String? fullAddress,
  }) {
    return Address(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      province: province ?? this.province,
      city: city ?? this.city,
      district: district ?? this.district,
      fullAddress: fullAddress ?? this.fullAddress,
    );
  }
}
