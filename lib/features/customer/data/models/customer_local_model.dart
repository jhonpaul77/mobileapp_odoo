import '../../domain/entities/customer.dart';

/// Sync status enum
enum SyncStatus {
  SYNCED,    // Synced with backend
  NEW,       // New record not yet synced
  UPDATED,   // Updated locally or from backend
  DELETED,   // Marked for deletion
}

/// CustomerLocalModel - Extended customer model with local database fields
///
/// Extends the basic Customer with sync tracking fields
/// Used for local database storage and sync management
/// Tracks which fields have changed for efficient sync
class CustomerLocalModel extends Customer {
  final SyncStatus syncStatus;
  final DateTime? remoteUpdatedAt;      // Last update timestamp from backend
  final DateTime? localCreatedAt;       // When record was created locally
  final DateTime? localUpdatedAt;       // When record was last modified locally
  final DateTime? syncedAt;             // When record was last synced
  final List<String> changedFields;     // Fields that have changed (for partial sync)

  CustomerLocalModel({
    required int id,
    required String name,
    String? email,
    String? phone,
    int? userId,
    String? street,
    String? street2,
    int? districtId,
    int? cityId,
    int? stateId,
    String? zip,
    int? countryId,
    this.syncStatus = SyncStatus.SYNCED,
    this.remoteUpdatedAt,
    this.localCreatedAt,
    this.localUpdatedAt,
    this.syncedAt,
    this.changedFields = const [],
  }) : super(
    id: id,
    name: name,
    email: email,
    phone: phone,
    userId: userId,
    street: street,
    street2: street2,
    districtId: districtId,
    cityId: cityId,
    stateId: stateId,
    zip: zip,
    countryId: countryId,
  );

  /// Create from regular Customer entity (for new local records)
  factory CustomerLocalModel.fromEntity(Customer customer, {
    SyncStatus syncStatus = SyncStatus.SYNCED,
    DateTime? remoteUpdatedAt,
    List<String> changedFields = const [],
  }) {
    return CustomerLocalModel(
      id: customer.id,
      name: customer.name,
      email: customer.email,
      phone: customer.phone,
      userId: customer.userId,
      street: customer.street,
      street2: customer.street2,
      districtId: customer.districtId,
      cityId: customer.cityId,
      stateId: customer.stateId,
      zip: customer.zip,
      countryId: customer.countryId,
      syncStatus: syncStatus,
      remoteUpdatedAt: remoteUpdatedAt,
      localCreatedAt: DateTime.now(),
      localUpdatedAt: DateTime.now(),
      syncedAt: syncStatus == SyncStatus.SYNCED ? DateTime.now() : null,
      changedFields: changedFields,
    );
  }

  /// Convert to JSON for local database storage
  Map<String, dynamic> toLocalJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'street': street,
      'street2': street2,
      'district_id': districtId,
      'city_id': cityId,
      'state_id': stateId,
      'zip': zip,
      'country_id': countryId,
      'sync_status': syncStatus.toString().split('.').last,
      'remote_updated_at': remoteUpdatedAt?.toIso8601String(),
      'local_created_at': localCreatedAt?.toIso8601String(),
      'local_updated_at': localUpdatedAt?.toIso8601String(),
      'synced_at': syncedAt?.toIso8601String(),
      'changed_fields': changedFields.join(','), // Store as comma-separated string
    };
  }

  /// Create from database row
  factory CustomerLocalModel.fromLocalJson(Map<String, dynamic> json) {
    final changedFieldsStr = json['changed_fields'] as String? ?? '';
    final changedFields = changedFieldsStr.isNotEmpty
        ? changedFieldsStr.split(',')
        : <String>[];

    return CustomerLocalModel(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      street: json['street'] as String?,
      street2: json['street2'] as String?,
      districtId: json['district_id'] as int?,
      cityId: json['city_id'] as int?,
      stateId: json['state_id'] as int?,
      zip: json['zip'] as String?,
      countryId: json['country_id'] as int?,
      syncStatus: _parseSyncStatus(json['sync_status'] as String?),
      remoteUpdatedAt: json['remote_updated_at'] != null
          ? DateTime.parse(json['remote_updated_at'] as String)
          : null,
      localCreatedAt: json['local_created_at'] != null
          ? DateTime.parse(json['local_created_at'] as String)
          : null,
      localUpdatedAt: json['local_updated_at'] != null
          ? DateTime.parse(json['local_updated_at'] as String)
          : null,
      syncedAt: json['synced_at'] != null
          ? DateTime.parse(json['synced_at'] as String)
          : null,
      changedFields: changedFields,
    );
  }

  /// Parse sync status from string
  static SyncStatus _parseSyncStatus(String? status) {
    switch (status) {
      case 'NEW':
        return SyncStatus.NEW;
      case 'UPDATED':
        return SyncStatus.UPDATED;
      case 'DELETED':
        return SyncStatus.DELETED;
      default:
        return SyncStatus.SYNCED;
    }
  }

  /// Convert to regular Customer entity (for business logic)
  Customer toEntity() {
    return Customer(
      id: id,
      name: name,
      email: email,
      phone: phone,
      userId: userId,
      street: street,
      street2: street2,
      districtId: districtId,
      cityId: cityId,
      stateId: stateId,
      zip: zip,
      countryId: countryId,
    );
  }

  /// Check if needs sync (has changes)
  bool get needsSync => syncStatus != SyncStatus.SYNCED;

  /// Get sync status display text
  String get syncStatusText {
    switch (syncStatus) {
      case SyncStatus.NEW:
        return '🆕 Baru';
      case SyncStatus.UPDATED:
        return '✏️ Diperbarui';
      case SyncStatus.DELETED:
        return '🗑️ Dihapus';
      case SyncStatus.SYNCED:
        return '✅ Tersinkronisasi';
    }
  }

  /// Copy with method for immutability
  @override
  CustomerLocalModel copyWith({
    int? id,
    String? name,
    String? email,
    String? phone,
    int? userId,
    String? street,
    String? street2,
    int? districtId,
    int? cityId,
    int? stateId,
    String? zip,
    int? countryId,
    SyncStatus? syncStatus,
    DateTime? remoteUpdatedAt,
    DateTime? localCreatedAt,
    DateTime? localUpdatedAt,
    DateTime? syncedAt,
    List<String>? changedFields,
  }) {
    return CustomerLocalModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      userId: userId ?? this.userId,
      street: street ?? this.street,
      street2: street2 ?? this.street2,
      districtId: districtId ?? this.districtId,
      cityId: cityId ?? this.cityId,
      stateId: stateId ?? this.stateId,
      zip: zip ?? this.zip,
      countryId: countryId ?? this.countryId,
      syncStatus: syncStatus ?? this.syncStatus,
      remoteUpdatedAt: remoteUpdatedAt ?? this.remoteUpdatedAt,
      localCreatedAt: localCreatedAt ?? this.localCreatedAt,
      localUpdatedAt: localUpdatedAt ?? this.localUpdatedAt,
      syncedAt: syncedAt ?? this.syncedAt,
      changedFields: changedFields ?? this.changedFields,
    );
  }
}
