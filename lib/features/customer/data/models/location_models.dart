/// Location Models - State, City, District
///
/// Models untuk menyimpan data lokasi (negara, provinsi, kota, distrik)
/// ke database lokal

enum SyncStatus {
  SYNCED,
  UPDATED,
  NEW,
  DELETED,
}

/// Model untuk State/Province
class StateLocalModel {
  final int id;
  final String name;
  final String? code;
  final SyncStatus syncStatus;
  final DateTime? syncedAt;

  StateLocalModel({
    required this.id,
    required this.name,
    this.code,
    this.syncStatus = SyncStatus.SYNCED,
    this.syncedAt,
  });

  /// Convert ke JSON untuk simpan di database
  Map<String, dynamic> toLocalJson() => {
    'id': id,
    'name': name,
    'code': code,
    'sync_status': syncStatus.toString().split('.').last,
    'synced_at': syncedAt?.toIso8601String(),
  };

  /// Convert dari JSON database ke model
  factory StateLocalModel.fromLocalJson(Map<String, dynamic> json) {
    return StateLocalModel(
      id: json['id'] as int,
      name: json['name'] as String,
      code: json['code'] as String?,
      syncStatus: _parseSyncStatus(json['sync_status'] as String?),
      syncedAt: json['synced_at'] != null
          ? DateTime.parse(json['synced_at'] as String)
          : null,
    );
  }

  /// Create dari API response
  factory StateLocalModel.fromApi(Map<String, dynamic> json) {
    return StateLocalModel(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      code: json['code'] as String?,
      syncStatus: SyncStatus.SYNCED,
      syncedAt: DateTime.now(),
    );
  }
}

/// Model untuk City
class CityLocalModel {
  final int id;
  final String name;
  final int? stateId;
  final SyncStatus syncStatus;
  final DateTime? syncedAt;

  CityLocalModel({
    required this.id,
    required this.name,
    this.stateId,
    this.syncStatus = SyncStatus.SYNCED,
    this.syncedAt,
  });

  /// Convert ke JSON untuk simpan di database
  Map<String, dynamic> toLocalJson() => {
    'id': id,
    'name': name,
    'state_id': stateId,
    'sync_status': syncStatus.toString().split('.').last,
    'synced_at': syncedAt?.toIso8601String(),
  };

  /// Convert dari JSON database ke model
  factory CityLocalModel.fromLocalJson(Map<String, dynamic> json) {
    return CityLocalModel(
      id: json['id'] as int,
      name: json['name'] as String,
      stateId: json['state_id'] as int?,
      syncStatus: _parseSyncStatus(json['sync_status'] as String?),
      syncedAt: json['synced_at'] != null
          ? DateTime.parse(json['synced_at'] as String)
          : null,
    );
  }

  /// Create dari API response
  factory CityLocalModel.fromApi(Map<String, dynamic> json) {
    return CityLocalModel(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      stateId: json['state_id'] as int?,
      syncStatus: SyncStatus.SYNCED,
      syncedAt: DateTime.now(),
    );
  }
}

/// Model untuk District
class DistrictLocalModel {
  final int id;
  final String name;
  final int? cityId;
  final SyncStatus syncStatus;
  final DateTime? syncedAt;

  DistrictLocalModel({
    required this.id,
    required this.name,
    this.cityId,
    this.syncStatus = SyncStatus.SYNCED,
    this.syncedAt,
  });

  /// Convert ke JSON untuk simpan di database
  Map<String, dynamic> toLocalJson() => {
    'id': id,
    'name': name,
    'city_id': cityId,
    'sync_status': syncStatus.toString().split('.').last,
    'synced_at': syncedAt?.toIso8601String(),
  };

  /// Convert dari JSON database ke model
  factory DistrictLocalModel.fromLocalJson(Map<String, dynamic> json) {
    return DistrictLocalModel(
      id: json['id'] as int,
      name: json['name'] as String,
      cityId: json['city_id'] as int?,
      syncStatus: _parseSyncStatus(json['sync_status'] as String?),
      syncedAt: json['synced_at'] != null
          ? DateTime.parse(json['synced_at'] as String)
          : null,
    );
  }

  /// Create dari API response
  factory DistrictLocalModel.fromApi(Map<String, dynamic> json) {
    return DistrictLocalModel(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      cityId: json['city_id'] as int?,
      syncStatus: SyncStatus.SYNCED,
      syncedAt: DateTime.now(),
    );
  }
}

/// Helper function untuk parse sync status
SyncStatus _parseSyncStatus(String? status) {
  if (status == null) return SyncStatus.SYNCED;
  switch (status) {
    case 'UPDATED':
      return SyncStatus.UPDATED;
    case 'NEW':
      return SyncStatus.NEW;
    case 'DELETED':
      return SyncStatus.DELETED;
    default:
      return SyncStatus.SYNCED;
  }
}
