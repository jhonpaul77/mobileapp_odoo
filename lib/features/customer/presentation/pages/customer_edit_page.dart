import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../config/theme.dart';
import '../../../../services/config_service.dart';
import '../../../../services/local_database/customer_local_database.dart';
import '../../../../services/local_database/location_local_database.dart';
import '../../../../services/secure_storage_service.dart';
import '../../../location/data/datasources/location_remote_datasource.dart';
import '../../../location/domain/entities/district.dart';
import '../../../sales_order/presentation/pages/district_search_modal.dart';
import '../../data/models/customer_local_model.dart';
import '../../domain/entities/customer.dart';
import '../providers/customer_provider.dart';

/// Customer Edit Page
///
/// Form for editing an existing customer
/// Styling matches SalesOrderEditPage for visual consistency
class CustomerEditPage extends StatefulWidget {
  final Customer customer;

  const CustomerEditPage({
    super.key,
    required this.customer,
  });

  @override
  State<CustomerEditPage> createState() => _CustomerEditPageState();
}

class _CustomerEditPageState extends State<CustomerEditPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _streetController = TextEditingController();
  final _street2Controller = TextEditingController();
  // final _districtController = TextEditingController(); // Hidden - using combined location field
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _zipController = TextEditingController();
  
  // Hidden controllers for reference only (used in combined location display)
  late final TextEditingController _districtController;

  bool _isSubmitting = false;
  List<District> _allDistricts = [];
  bool _districtLoading = false;
  int? _selectedDistrictId;
  int? _selectedCityId;
  int? _selectedStateId;
  Map<int, String> _cityMap = {}; // cityId -> cityName
  Map<int, String> _stateMap = {}; // stateId -> stateName
  Map<int, int> _cityToStateMap = {}; // cityId -> stateId
  Map<int, String> _districtMap = {}; // districtId -> districtName

  @override
  void initState() {
    super.initState();
    _districtController = TextEditingController();
    _initializeForm();
    _loadDistricts();
  }

  /// Initialize form with customer data
  void _initializeForm() {
    final customer = widget.customer;

    _nameController.text = customer.name;
    _emailController.text = customer.email ?? '';

    // Parse phone: remove +62 prefix if exists
    String phoneDisplay = customer.phone ?? '';
    if (phoneDisplay.startsWith('+62')) {
      phoneDisplay = phoneDisplay.substring(3).trim();
    } else if (phoneDisplay.startsWith('62')) {
      phoneDisplay = phoneDisplay.substring(2).trim();
    } else if (phoneDisplay.startsWith('0')) {
      phoneDisplay = phoneDisplay.substring(1).trim();
    }
    _phoneController.text = phoneDisplay;

    _streetController.text = customer.street ?? '';
    _street2Controller.text = customer.street2 ?? '';
    _zipController.text = customer.zip ?? '';

    // Set selected IDs from customer
    _selectedDistrictId = customer.districtId;
    _selectedCityId = customer.cityId;
    _selectedStateId = customer.stateId;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _streetController.dispose();
    _street2Controller.dispose();
    _districtController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipController.dispose();
    super.dispose();
  }

  Future<void> _loadDistricts() async {
    try {
      setState(() => _districtLoading = true);

      // ⭐ PRIORITAS 1: Ambil dari lokal database (CEPAT!)
      final locationDb = LocationLocalDatabase();

      print('📡 [EDIT CUSTOMER] Loading locations from LOCAL database...');

      // Load all from local database
      final districts = await locationDb.getAllDistricts();
      final cities = await locationDb.getAllCities();
      final states = await locationDb.getAllStates();

      // Build maps
      final districtMap = <int, String>{};
      for (final district in districts) {
        districtMap[district.id] = district.name;
      }

      final cityMap = <int, String>{};
      final cityToStateMap = <int, int>{};
      for (final city in cities) {
        cityMap[city.id] = city.name;
        if (city.stateId != null) {
          cityToStateMap[city.id] = city.stateId!;
        }
      }

      final stateMap = <int, String>{};
      for (final state in states) {
        stateMap[state.id] = state.name;
      }

      // Convert to District entities for compatibility with modal
      final districtEntities = districts
          .map((d) => District(
                id: d.id,
                name: d.name,
                code: '', // Not available in local model
                cityId: d.cityId ?? 0,
              ))
          .toList();

      if (mounted) {
        setState(() {
          _allDistricts = districtEntities;
          _districtMap = districtMap;
          _cityMap = cityMap;
          _stateMap = stateMap;
          _cityToStateMap = cityToStateMap;
        });

        print(
            '✅ [EDIT CUSTOMER] Loaded ${_allDistricts.length} districts from LOCAL');

        // Set initial district display if customer has district
        _updateDistrictDisplay();
      }
    } catch (e) {
      print('⚠️ [EDIT CUSTOMER] Error loading from local DB: $e');
      print('   Fallback to API...');

      // ⭐ PRIORITAS 2: Jika lokal gagal, ambil dari API
      try {
        final configService = ConfigService();
        final storage = SecureStorageService();

        final config = await configService.load();
        final db = config['database'] as String?;
        final apiKey = await storage.getAccessToken();

        if (db == null || apiKey == null) {
          print('❌ [EDIT CUSTOMER] No config/apiKey');
          return;
        }

        final locationDatasource = LocationRemoteDataSource();

        // Load all from API
        final districts = await locationDatasource.getAllDistricts(
          db: db,
          apiKey: apiKey,
        );

        final cities = await locationDatasource.getCities(
          db: db,
          apiKey: apiKey,
        );

        final states = await locationDatasource.getStates(
          db: db,
          apiKey: apiKey,
        );

        // Build maps
        final districtMap = <int, String>{};
        for (final district in districts) {
          districtMap[district.id] = district.name;
        }

        final cityMap = <int, String>{};
        final cityToStateMap = <int, int>{};
        for (final city in cities) {
          cityMap[city.id] = city.name;
          cityToStateMap[city.id] = city.stateId;
        }

        final stateMap = <int, String>{};
        for (final state in states) {
          stateMap[state.id] = state.name;
        }

        if (mounted) {
          setState(() {
            _allDistricts = districts;
            _districtMap = districtMap;
            _cityMap = cityMap;
            _stateMap = stateMap;
            _cityToStateMap = cityToStateMap;
          });

          print(
              '✅ [EDIT CUSTOMER] Loaded ${_allDistricts.length} districts from API');

          // Set initial district display if customer has district
          _updateDistrictDisplay();
        }
      } catch (apiError) {
        print('❌ [EDIT CUSTOMER] Error loading from API: $apiError');
      }
    } finally {
      if (mounted) setState(() => _districtLoading = false);
    }
  }

  /// Update district display text based on selected IDs
  void _updateDistrictDisplay() {
    if (_selectedDistrictId != null) {
      final districtName = _districtMap[_selectedDistrictId] ?? '';
      _districtController.text = districtName;

      if (_selectedCityId != null) {
        final cityName = _cityMap[_selectedCityId] ?? '';
        final stateName =
            _selectedStateId != null ? _stateMap[_selectedStateId] ?? '' : '';

        // Update city and state controllers
        _cityController.text = cityName;
        _stateController.text = stateName;
      }
    }
  }

  Future<void> _selectDistrict() async {
    final selected = await showDialog<District>(
      context: context,
      builder: (_) => DistrictSearchModal(
        allDistricts: _allDistricts,
        cityNames: _cityMap,
        stateNames: _stateMap,
        cityToStateMap: _cityToStateMap,
      ),
    );

    if (selected != null) {
      // Get city and state names
      final cityName = _cityMap[selected.cityId] ?? '';
      final stateId = _cityToStateMap[selected.cityId];
      final stateName = stateId != null ? _stateMap[stateId] ?? '' : '';

      setState(() {
        _selectedDistrictId = selected.id;
        _selectedCityId = selected.cityId;
        _selectedStateId = stateId;
        _districtController.text = selected.name;

        // Update city and state fields separately
        if (cityName.isNotEmpty) {
          _cityController.text = cityName;
        }
        if (stateName.isNotEmpty) {
          _stateController.text = stateName;
        }
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      // Format phone number properly
      String phoneNumber = _phoneController.text.trim();
      String formattedPhone = '';

      if (phoneNumber.isNotEmpty) {
        // Remove all non-digit characters
        phoneNumber = phoneNumber.replaceAll(RegExp(r'\D'), '');

        // Add +62 prefix if not already present
        if (phoneNumber.startsWith('62')) {
          formattedPhone = '+$phoneNumber';
        } else if (phoneNumber.startsWith('0')) {
          formattedPhone = '+62${phoneNumber.substring(1)}';
        } else {
          formattedPhone = '+62$phoneNumber';
        }
      }

      final data = <String, dynamic>{
        'id': widget.customer.id, // Required for edit
        'name': _nameController.text.trim(),
        if (_emailController.text.trim().isNotEmpty)
          'email': _emailController.text.trim(),
        if (formattedPhone.isNotEmpty) 'phone': formattedPhone,
        if (_streetController.text.trim().isNotEmpty)
          'street': _streetController.text.trim(),
        if (_street2Controller.text.trim().isNotEmpty)
          'street2': _street2Controller.text.trim(),
        if (_selectedDistrictId != null) 'district_id': _selectedDistrictId,
        if (_selectedCityId != null) 'city_id': _selectedCityId,
        if (_selectedStateId != null) 'state_id': _selectedStateId,
        if (_zipController.text.trim().isNotEmpty)
          'zip': _zipController.text.trim(),
        'country_id': 100, // Indonesia
      };

      print('📝 [EDIT CUSTOMER] Request data: $data');

      // Try to update - will throw error jika gagal POST
      final updatedCustomer =
          await context.read<CustomerProvider>().updateCustomer(data);

      if (mounted) {
        // Berhasil! Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text('Customer berhasil diupdate & tersinkronisasi'),
                ),
              ],
            ),
            backgroundColor: AppTheme.successColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 3),
          ),
        );

        // Wait a moment before navigating back to ensure data is saved
        await Future.delayed(const Duration(milliseconds: 500));

        if (mounted) {
          print(
              '📤 [EDIT CUSTOMER] Returning to detail page with: $updatedCustomer');
          Navigator.pop(context, updatedCustomer);
        }
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        // API POST gagal, tanyakan apakah user mau simpan lokal saja
        String errorMsg = e.toString();
        if (errorMsg.startsWith('Exception: ')) {
          errorMsg = errorMsg.substring(11);
        }

        print('❌ [EDIT CUSTOMER] Error: $errorMsg');

        // Capture data untuk dialog
        final phoneNumber = _phoneController.text.trim();
        String formattedPhone = '';
        if (phoneNumber.isNotEmpty) {
          final cleanPhone = phoneNumber.replaceAll(RegExp(r'\D'), '');
          if (cleanPhone.startsWith('62')) {
            formattedPhone = '+$cleanPhone';
          } else if (cleanPhone.startsWith('0')) {
            formattedPhone = '+62${cleanPhone.substring(1)}';
          } else {
            formattedPhone = '+62$cleanPhone';
          }
        }

        final dialogData = <String, dynamic>{
          'id': widget.customer.id,
          'name': _nameController.text.trim(),
          if (_emailController.text.trim().isNotEmpty)
            'email': _emailController.text.trim(),
          if (formattedPhone.isNotEmpty) 'phone': formattedPhone,
          if (_streetController.text.trim().isNotEmpty)
            'street': _streetController.text.trim(),
          if (_street2Controller.text.trim().isNotEmpty)
            'street2': _street2Controller.text.trim(),
          if (_selectedDistrictId != null) 'district_id': _selectedDistrictId,
          if (_selectedCityId != null) 'city_id': _selectedCityId,
          if (_selectedStateId != null) 'state_id': _selectedStateId,
          if (_zipController.text.trim().isNotEmpty)
            'zip': _zipController.text.trim(),
          'country_id': 100,
        };

        // Show error dialog dengan pilihan
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red),
                SizedBox(width: 8),
                Text('Update Gagal'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Error: $errorMsg',
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Apakah Anda ingin simpan perubahan secara lokal? Data akan di-sync otomatis ketika internet tersedia.',
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Batal'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  // Re-submit tanpa POST (langsung lokal)
                  _submitOfflineOnly(dialogData);
                },
                child: const Text(
                  'Simpan Lokal',
                  style: TextStyle(color: Colors.orange),
                ),
              ),
            ],
          ),
        );
      }
    }
  }

  /// Submit offline - simpan langsung ke lokal dengan status UPDATED
  Future<void> _submitOfflineOnly(Map<String, dynamic> data) async {
    try {
      setState(() => _isSubmitting = true);

      // Convert strings to ints
      final updatedCustomer = Customer(
        id: data['id'] as int,
        name: data['name'] ?? '',
        email: data['email'],
        phone: data['phone'],
        userId: data['user_id'] != null
            ? int.tryParse(data['user_id'].toString())
            : null,
        street: data['street'],
        street2: data['street2'],
        districtId: data['district_id'] != null
            ? int.tryParse(data['district_id'].toString())
            : null,
        cityId: data['city_id'] != null
            ? int.tryParse(data['city_id'].toString())
            : null,
        stateId: data['state_id'] != null
            ? int.tryParse(data['state_id'].toString())
            : null,
        zip: data['zip'],
        countryId: data['country_id'] != null
            ? int.tryParse(data['country_id'].toString())
            : null,
      );

      // Save ke lokal dengan status UPDATED
      final localDb = CustomerLocalDatabase();
      final localModel = CustomerLocalModel.fromEntity(
        updatedCustomer,
        syncStatus: SyncStatus.UPDATED,
      );
      await localDb.insertOrReplace(localModel);
      print('✅ [EDIT CUSTOMER] Tersimpan lokal (UPDATED) - akan di-sync nanti');

      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.cloud_off_rounded, color: Colors.white),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text('Customer disimpan lokal (pending sinkronisasi)'),
                ),
              ],
            ),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 3),
          ),
        );

        // Wait a moment before navigating back
        await Future.delayed(const Duration(milliseconds: 500));

        if (mounted) {
          print(
              '📤 [EDIT CUSTOMER OFFLINE] Returning to detail page with: $updatedCustomer');
          Navigator.pop(context, updatedCustomer);
        }
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error menyimpan lokal: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  /// Build a styled input field (TextField style with label)
  Widget _buildEditField(
    String label,
    TextEditingController controller, {
    TextInputType keyboardType = TextInputType.text,
    bool readOnly = false,
    int maxLines = 1,
    double fontSize = 13,
  }) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: theme.textTheme.bodySmall?.color,
            ),
          ),
          const SizedBox(height: 4),
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            readOnly: readOnly,
            maxLines: maxLines,
            style: TextStyle(
              fontSize: fontSize,
              color: theme.textTheme.bodyLarge?.color,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: readOnly
                  ? (theme.brightness == Brightness.dark
                      ? Colors.grey[800]
                      : Colors.grey[100])
                  : (theme.brightness == Brightness.dark
                      ? Colors.grey[800]
                      : Colors.white),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(
                  color: theme.brightness == Brightness.dark
                      ? Colors.grey[700]!
                      : Colors.grey[300]!,
                  width: 1,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(
                  color: theme.brightness == Brightness.dark
                      ? Colors.grey[700]!
                      : Colors.grey[300]!,
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide:
                    const BorderSide(color: AppTheme.primaryColor, width: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Edit Customer',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info Banner
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.brandBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.brandBlue.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: AppTheme.brandBlue, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Field bertanda * wajib diisi',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.brandBlue,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Customer Details Container
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.cardTheme.color,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.brightness == Brightness.dark
                        ? Colors.grey[700]!
                        : Colors.grey[200]!,
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                          alpha: theme.brightness == Brightness.dark ? 0.3 : 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Customer Details',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: theme.textTheme.bodyMedium?.color,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Divider(
                      color: theme.brightness == Brightness.dark
                          ? Colors.grey[700]
                          : Colors.grey[200],
                      height: 1,
                    ),
                    const SizedBox(height: 10),

                    // Name Field (Required)
                    TextFormField(
                      controller: _nameController,
                      style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                      decoration: InputDecoration(
                        labelText: 'Nama Customer *',
                        labelStyle: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: theme.textTheme.bodySmall?.color,
                        ),
                        hintText: 'Contoh: PT Maju Jaya',
                        filled: true,
                        fillColor: theme.brightness == Brightness.dark
                            ? Colors.grey[800]
                            : Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 9,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: BorderSide(
                            color: theme.brightness == Brightness.dark
                                ? Colors.grey[700]!
                                : Colors.grey[300]!,
                            width: 1,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: BorderSide(
                            color: theme.brightness == Brightness.dark
                                ? Colors.grey[700]!
                                : Colors.grey[300]!,
                            width: 1,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: const BorderSide(
                            color: AppTheme.primaryColor,
                            width: 1.5,
                          ),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: const BorderSide(
                            color: Colors.red,
                            width: 1,
                          ),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: const BorderSide(
                            color: Colors.red,
                            width: 1.5,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Nama customer wajib diisi';
                        }
                        if (value.trim().length < 3) {
                          return 'Nama customer minimal 3 karakter';
                        }
                        return null;
                      },
                      textInputAction: TextInputAction.next,
                    ),

                    const SizedBox(height: 9),

                    // Email Field
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                      decoration: InputDecoration(
                        labelText: 'Email',
                        labelStyle: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: theme.textTheme.bodySmall?.color,
                        ),
                        hintText: 'Contoh: customer@example.com',
                        filled: true,
                        fillColor: theme.brightness == Brightness.dark
                            ? Colors.grey[800]
                            : Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 9,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: BorderSide(
                            color: theme.brightness == Brightness.dark
                                ? Colors.grey[700]!
                                : Colors.grey[300]!,
                            width: 1,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: BorderSide(
                            color: theme.brightness == Brightness.dark
                                ? Colors.grey[700]!
                                : Colors.grey[300]!,
                            width: 1,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: const BorderSide(
                            color: AppTheme.primaryColor,
                            width: 1.5,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value != null && value.trim().isNotEmpty) {
                          final emailRegex =
                              RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                          if (!emailRegex.hasMatch(value.trim())) {
                            return 'Format email tidak valid';
                          }
                        }
                        return null;
                      },
                      textInputAction: TextInputAction.next,
                    ),

                    const SizedBox(height: 9),

                    // Phone Field
                    TextFormField(
                      controller: _phoneController,
                      style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'Nomor Telepon',
                        labelStyle: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: theme.textTheme.bodySmall?.color,
                        ),
                        hintText: 'Contoh: 8123456789',
                        prefixText: '+62 ',
                        prefixStyle: TextStyle(
                          color: theme.textTheme.bodyLarge?.color,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        filled: true,
                        fillColor: theme.brightness == Brightness.dark
                            ? Colors.grey[800]
                            : Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 9,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: BorderSide(
                            color: theme.brightness == Brightness.dark
                                ? Colors.grey[700]!
                                : Colors.grey[300]!,
                            width: 1,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: BorderSide(
                            color: theme.brightness == Brightness.dark
                                ? Colors.grey[700]!
                                : Colors.grey[300]!,
                            width: 1,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: const BorderSide(
                            color: AppTheme.primaryColor,
                            width: 1.5,
                          ),
                        ),
                      ),
                      textInputAction: TextInputAction.next,
                    ),

                    const SizedBox(height: 9),

                    // Street Field
                    TextFormField(
                      controller: _streetController,
                      maxLines: 2,
                      style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                      decoration: InputDecoration(
                        labelText: 'Alamat',
                        labelStyle: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: theme.textTheme.bodySmall?.color,
                        ),
                        hintText: 'Contoh: Jl. Merdeka No. 123',
                        filled: true,
                        fillColor: theme.brightness == Brightness.dark
                            ? Colors.grey[800]
                            : Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 9,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: BorderSide(
                            color: theme.brightness == Brightness.dark
                                ? Colors.grey[700]!
                                : Colors.grey[300]!,
                            width: 1,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: BorderSide(
                            color: theme.brightness == Brightness.dark
                                ? Colors.grey[700]!
                                : Colors.grey[300]!,
                            width: 1,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: const BorderSide(
                            color: AppTheme.primaryColor,
                            width: 1.5,
                          ),
                        ),
                      ),
                      textInputAction: TextInputAction.next,
                    ),

                    const SizedBox(height: 9),

                    const SizedBox(height: 9),

                    // Location Field - Combined Display (District, City, Province)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Lokasi',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: theme.textTheme.bodySmall?.color,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: _districtLoading || _allDistricts.isEmpty
                                    ? null
                                    : _selectDistrict,
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 9,
                                  ),
                                  decoration: BoxDecoration(
                                    color: theme.brightness == Brightness.dark
                                        ? Colors.grey[800]
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: theme.brightness == Brightness.dark
                                          ? Colors.grey[700]!
                                          : Colors.grey[300]!,
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          _stateController.text.isEmpty
                                              ? 'Pilih Lokasi'
                                              : '${_districtController.text}, ${_cityController.text}, ${_stateController.text}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: _stateController.text.isEmpty
                                                ? Colors.grey[400]
                                                : theme.textTheme.bodyLarge
                                                    ?.color,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Icon(
                                        Icons.arrow_forward_ios,
                                        size: 14,
                                        color:
                                            theme.textTheme.bodySmall?.color,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              height: 40,
                              width: 40,
                              child: ElevatedButton(
                                onPressed: _districtLoading ||
                                        _allDistricts.isEmpty
                                    ? null
                                    : _selectDistrict,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryColor,
                                  disabledBackgroundColor: Colors.grey[400],
                                  padding: EdgeInsets.zero,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                                child: _districtLoading
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  Colors.white),
                                        ),
                                      )
                                    : const Icon(Icons.search, size: 18),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 9),

                    // ZIP Field
                    _buildEditField(
                      'Kode Pos',
                      _zipController,
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed:
                          _isSubmitting ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey[700],
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        side: BorderSide(color: Colors.grey[300]!, width: 1),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        disabledBackgroundColor: Colors.grey[400],
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Update Customer',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
