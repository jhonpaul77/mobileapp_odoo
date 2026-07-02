class LocationData {
  final String province;
  final String city;
  final String district;

  LocationData({
    required this.province,
    required this.city,
    required this.district,
  });

  @override
  String toString() => '$province,$city,$district';
}

class DistrictInfo {
  final String district;
  final String city;
  final String province;

  DistrictInfo({
    required this.district,
    required this.city,
    required this.province,
  });
}

// Sample data - dalam production, ini akan dari API
final locationDatabase = [
  DistrictInfo(
    district: 'Benowo',
    city: 'Surabaya',
    province: 'Jawa Timur',
  ),
  DistrictInfo(
    district: 'Wonokromo',
    city: 'Surabaya',
    province: 'Jawa Timur',
  ),
  DistrictInfo(
    district: 'Gebang',
    city: 'Surabaya',
    province: 'Jawa Timur',
  ),
  DistrictInfo(
    district: 'Kenjeran',
    city: 'Surabaya',
    province: 'Jawa Timur',
  ),
  DistrictInfo(
    district: 'Semampir',
    city: 'Surabaya',
    province: 'Jawa Timur',
  ),
  DistrictInfo(
    district: 'Bubutan',
    city: 'Surabaya',
    province: 'Jawa Timur',
  ),
  DistrictInfo(
    district: 'Pakal',
    city: 'Surabaya',
    province: 'Jawa Timur',
  ),
  DistrictInfo(
    district: 'Rungkut',
    city: 'Surabaya',
    province: 'Jawa Timur',
  ),
  DistrictInfo(
    district: 'Gunung Anyar',
    city: 'Surabaya',
    province: 'Jawa Timur',
  ),
  DistrictInfo(
    district: 'Sukolilo',
    city: 'Surabaya',
    province: 'Jawa Timur',
  ),
  DistrictInfo(
    district: 'Asemrowo',
    city: 'Surabaya',
    province: 'Jawa Timur',
  ),
  DistrictInfo(
    district: 'Tandes',
    city: 'Surabaya',
    province: 'Jawa Timur',
  ),
  DistrictInfo(
    district: 'Genteng',
    city: 'Surabaya',
    province: 'Jawa Timur',
  ),
  DistrictInfo(
    district: 'Tambaksari',
    city: 'Surabaya',
    province: 'Jawa Timur',
  ),
  DistrictInfo(
    district: 'Mulyorejo',
    city: 'Surabaya',
    province: 'Jawa Timur',
  ),
  DistrictInfo(
    district: 'Tegalsari',
    city: 'Surabaya',
    province: 'Jawa Timur',
  ),
  DistrictInfo(
    district: 'Krembangan',
    city: 'Surabaya',
    province: 'Jawa Timur',
  ),
  DistrictInfo(
    district: 'Simokerto',
    city: 'Surabaya',
    province: 'Jawa Timur',
  ),
  DistrictInfo(
    district: 'Wiyung',
    city: 'Surabaya',
    province: 'Jawa Timur',
  ),
  DistrictInfo(
    district: 'Dukuhpakis',
    city: 'Surabaya',
    province: 'Jawa Timur',
  ),
  // Jakarta
  DistrictInfo(
    district: 'Kemayoran',
    city: 'Jakarta Pusat',
    province: 'DKI Jakarta',
  ),
  DistrictInfo(
    district: 'Menteng',
    city: 'Jakarta Pusat',
    province: 'DKI Jakarta',
  ),
  DistrictInfo(
    district: 'Cempaka Putih',
    city: 'Jakarta Pusat',
    province: 'DKI Jakarta',
  ),
  DistrictInfo(
    district: 'Johar Baru',
    city: 'Jakarta Pusat',
    province: 'DKI Jakarta',
  ),
  DistrictInfo(
    district: 'Senen',
    city: 'Jakarta Pusat',
    province: 'DKI Jakarta',
  ),
  DistrictInfo(
    district: 'Sawah Besar',
    city: 'Jakarta Pusat',
    province: 'DKI Jakarta',
  ),
  // Bandung
  DistrictInfo(
    district: 'Andir',
    city: 'Bandung',
    province: 'Jawa Barat',
  ),
  DistrictInfo(
    district: 'Astana Anyar',
    city: 'Bandung',
    province: 'Jawa Barat',
  ),
  DistrictInfo(
    district: 'Babakan Ciparay',
    city: 'Bandung',
    province: 'Jawa Barat',
  ),
  DistrictInfo(
    district: 'Bandung Kulon',
    city: 'Bandung',
    province: 'Jawa Barat',
  ),
  DistrictInfo(
    district: 'Bandung Wetan',
    city: 'Bandung',
    province: 'Jawa Barat',
  ),
];
