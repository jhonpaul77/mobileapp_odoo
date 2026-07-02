class Customer {
  final String id;
  final String nama;
  final String email;
  final String noTelp;
  final bool isActive;
  final String catatan;
  final String createdBy;
  final String updatedBy;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;

  Customer({
    required this.id,
    required this.nama,
    required this.email,
    required this.noTelp,
    required this.isActive,
    required this.catatan,
    required this.createdBy,
    required this.updatedBy,
    required this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'] ?? '',
      nama: json['nama'] ?? '',
      email: json['email'] ?? '',
      noTelp: json['no_telp'] ?? '',
      isActive: json['is_active'] ?? true,
      catatan: json['catatan'] ?? '',
      createdBy: json['created_by'] ?? '',
      updatedBy: json['updated_by'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : null,
      deletedAt: json['deleted_at'] != null 
          ? DateTime.parse(json['deleted_at']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'nama': nama,
    'email': email,
    'no_telp': noTelp,
    'is_active': isActive,
    'catatan': catatan,
    'created_by': createdBy,
    'updated_by': updatedBy,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt?.toIso8601String(),
    'deleted_at': deletedAt?.toIso8601String(),
  };

  Map<String, dynamic> toFormData() => {
    'nama': nama,
    'email': email,
    'no_telp': noTelp,
    'is_active': isActive,
    'catatan': catatan,
  };
}