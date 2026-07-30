class Organization {
  final String id;
  final String nama;
  final String noTelp;
  final String alamat;
  final String kecamatan;
  final String kota;
  final String provinsi;
  final String kodePos;
  final bool isActive;
  final String catatan;
  final String createdBy;
  final String updatedBy;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;

  Organization({
    required this.id,
    required this.nama,
    required this.noTelp,
    required this.alamat,
    required this.kecamatan,
    required this.kota,
    required this.provinsi,
    required this.kodePos,
    required this.isActive,
    required this.catatan,
    required this.createdBy,
    required this.updatedBy,
    required this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  factory Organization.fromJson(Map<String, dynamic> json) {
    return Organization(
      id: json['id'] ?? '',
      nama: json['nama'] ?? '',
      noTelp: json['no_telp'] ?? '',
      alamat: json['alamat'] ?? '',
      kecamatan: json['kecamatan'] ?? '',
      kota: json['kota'] ?? '',
      provinsi: json['provinsi'] ?? '',
      kodePos: json['kode_pos'] ?? '',
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
        'no_telp': noTelp,
        'alamat': alamat,
        'kecamatan': kecamatan,
        'kota': kota,
        'provinsi': provinsi,
        'kode_pos': kodePos,
        'is_active': isActive,
        'catatan': catatan,
        'created_by': createdBy,
        'updated_by': updatedBy,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
        'deleted_at': deletedAt?.toIso8601String(),
      };

  // Helper untuk form (create/update)
  Map<String, dynamic> toFormData() => {
        'nama': nama,
        'no_telp': noTelp,
        'alamat': alamat,
        'kecamatan': kecamatan,
        'kota': kota,
        'provinsi': provinsi,
        'kode_pos': kodePos,
        'is_active': isActive,
        'catatan': catatan,
      };
}
