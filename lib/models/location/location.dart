class Location {
  final String id;
  final String kode;
  final String nama;
  final String catatan;
  final String createdBy;
  final String updatedBy;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;

  Location({
    required this.id,
    required this.kode,
    required this.nama,
    required this.catatan,
    required this.createdBy,
    required this.updatedBy,
    required this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      id: json['id'] ?? '',
      kode: json['kode'] ?? '',
      nama: json['nama'] ?? '',
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
        'kode': kode,
        'nama': nama,
        'catatan': catatan,
        'created_by': createdBy,
        'updated_by': updatedBy,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
        'deleted_at': deletedAt?.toIso8601String(),
      };

  // Helper untuk form (create/update)
  Map<String, dynamic> toFormData() => {
        'kode': kode,
        'nama': nama,
        'catatan': catatan,
      };
}
