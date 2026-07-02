class ProductCategory {
  final String id;
  final String nama;
  final String keterangan;
  final String catatan;
  final String createdBy;
  final String updatedBy;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;

  ProductCategory({
    required this.id,
    required this.nama,
    required this.keterangan,
    required this.catatan,
    required this.createdBy,
    required this.updatedBy,
    required this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  factory ProductCategory.fromJson(Map<String, dynamic> json) {
    return ProductCategory(
      id: json['id'] ?? '',
      nama: json['nama'] ?? '',
      keterangan: json['keterangan'] ?? '',
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
    'keterangan': keterangan,
    'catatan': catatan,
    'created_by': createdBy,
    'updated_by': updatedBy,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt?.toIso8601String(),
    'deleted_at': deletedAt?.toIso8601String(),
  };

  Map<String, dynamic> toFormData() => {
    'nama': nama,
    'keterangan': keterangan,
    'catatan': catatan,
  };
}