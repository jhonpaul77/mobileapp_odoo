# 📍 Location Services - IMPORTANT!

## ⚠️ Ada 2 Location Services yang Berbeda!

### 1. **LocationService** (Legacy - ✅ CREATED)
**File**: `lib/services/location_service.dart`

**Purpose**: Menangani CRUD operations untuk location entities (lokasi usaha/gudang)

**Status**: ✅ Service file has been created to support legacy location detail pages

**Operations**:
- Get location list (pagination)
- Get location detail by ID
- Create new location
- Update location
- Delete location

**Data Model**: `Location` (id, nama, kode, catatan, createdAt, updatedAt)

**Used By**:
- `lib/pages/settings/location/location_list_page.dart`
- `lib/pages/settings/location/location_detail_page.dart`
- `lib/pages/settings/location/location_form_page.dart`

**Example**:
```dart
final service = LocationService();

// Get list
final response = await service.fetchList(length: 10, start: 0);

// Get detail
final detail = await service.getLocationDetail('123');

// Create
final created = await service.createLocation(
  nama: 'Gudang Surabaya',
  kode: 'GD-SBY',
  catatan: 'Lokasi utama',
);
```

---

### 2. **OdooLocationService** (NEW!)
**File**: `lib/services/odoo_location_service.dart`

**Purpose**: Menangani Odoo API untuk wilayah Indonesia (State/City/District)

**Operations**:
- Get all states/provinces (Provinsi)
- Get all cities (Kota/Kabupaten)
- Get all districts (Kecamatan)
- Filter cities by state
- Filter districts by city

**Data**: Direct from Odoo (state_id, city_id, district_id)

**Used By**:
- Customer forms (untuk alamat)
- Sales forms (untuk pengiriman)
- Any form that needs Indonesia location data

**Example**:
```dart
final service = OdooLocationService();

// Get all states
final states = await service.getStates();
// Returns: [{ id: 623, name: "Jawa Timur", code: "JI" }, ...]

// Get cities by state
final cities = await service.getCitiesByState(623);
// Returns: [{ id: 810, name: "Surabaya", state_id: 623 }, ...]

// Get districts by city
final districts = await service.getDistrictsByCity(810);
// Returns: [{ id: 9413, name: "Rungkut", city_id: 810 }, ...]
```

---

## 🎯 When to Use Which?

### Use **LocationService** when:
- ✅ Managing company locations/warehouses
- ✅ CRUD operations on location entities
- ✅ Working with location settings page
- ✅ Need location list, detail, create, update, delete

### Use **OdooLocationService** when:
- ✅ Building address forms (customer, delivery)
- ✅ Need Province/City/District dropdowns
- ✅ Getting Indonesia location data
- ✅ Working with Odoo location IDs

---

## 🚨 Common Mistakes

### ❌ WRONG:
```dart
// DON'T use OdooLocationService for location management
final service = OdooLocationService();
await service.getLocationDetail('123'); // ❌ Method doesn't exist!
```

### ✅ CORRECT:
```dart
// Use LocationService for location management
final service = LocationService();
await service.getLocationDetail('123'); // ✅ Correct!

// Use OdooLocationService for Indonesia locations
final odooService = OdooLocationService();
await odooService.getStates(); // ✅ Correct!
```

---

## 📋 Integration Example

### Customer Form with Address:
```dart
class CustomerFormPage extends StatefulWidget {
  // ...
}

class _CustomerFormPageState extends State<CustomerFormPage> {
  final _locationService = LocationService(); // For warehouse location
  final _odooLocationService = OdooLocationService(); // For address
  
  List<dynamic> _states = [];
  List<dynamic> _cities = [];
  List<dynamic> _districts = [];
  
  int? _selectedStateId;
  int? _selectedCityId;
  int? _selectedDistrictId;
  
  @override
  void initState() {
    super.initState();
    _loadStates();
  }
  
  Future<void> _loadStates() async {
    final result = await _odooLocationService.getStates();
    if (result['Success'] == true) {
      setState(() {
        _states = result['Data'] as List;
      });
    }
  }
  
  Future<void> _onStateChanged(int? stateId) async {
    setState(() {
      _selectedStateId = stateId;
      _selectedCityId = null;
      _selectedDistrictId = null;
      _cities = [];
      _districts = [];
    });
    
    if (stateId != null) {
      final result = await _odooLocationService.getCitiesByState(stateId);
      if (result['Success'] == true) {
        setState(() {
          _cities = result['Data'] as List;
        });
      }
    }
  }
  
  Future<void> _onCityChanged(int? cityId) async {
    setState(() {
      _selectedCityId = cityId;
      _selectedDistrictId = null;
      _districts = [];
    });
    
    if (cityId != null) {
      final result = await _odooLocationService.getDistrictsByCity(cityId);
      if (result['Success'] == true) {
        setState(() {
          _districts = result['Data'] as List;
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Form(
        child: Column(
          children: [
            // State dropdown
            DropdownButtonFormField(
              value: _selectedStateId,
              items: _states.map((state) {
                return DropdownMenuItem(
                  value: state['id'],
                  child: Text(state['name']),
                );
              }).toList(),
              onChanged: _onStateChanged,
              decoration: const InputDecoration(
                labelText: 'Provinsi',
              ),
            ),
            
            // City dropdown
            DropdownButtonFormField(
              value: _selectedCityId,
              items: _cities.map((city) {
                return DropdownMenuItem(
                  value: city['id'],
                  child: Text(city['name']),
                );
              }).toList(),
              onChanged: _onCityChanged,
              decoration: const InputDecoration(
                labelText: 'Kota/Kabupaten',
              ),
            ),
            
            // District dropdown
            DropdownButtonFormField(
              value: _selectedDistrictId,
              items: _districts.map((district) {
                return DropdownMenuItem(
                  value: district['id'],
                  child: Text(district['name']),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedDistrictId = value;
                });
              },
              decoration: const InputDecoration(
                labelText: 'Kecamatan',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## 📚 References

- **LocationService**: See `lib/services/location_service.dart`
- **OdooLocationService**: See `lib/services/odoo_location_service.dart`
- **Location Model**: See `lib/models/location/location.dart`
- **API Documentation**: See `.docs/api/NEW-ENDPOINTS-IMPLEMENTATION.md`

---

**Last Updated**: 29 Juli 2026  
**Maintained By**: Development Team

