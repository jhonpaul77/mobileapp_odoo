import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../config/theme.dart';
import '../../../../services/config_service.dart';
import '../../../../services/secure_storage_service.dart';
import '../../../location/data/datasources/location_remote_datasource.dart';
import '../../../location/domain/entities/district.dart';
import '../../../sales_order/presentation/pages/district_search_modal.dart';
import '../../domain/entities/customer.dart';
import '../providers/customer_provider.dart';

/// Customer Edit Page
///
/// Form for editing an existing customer
/// UI/UX matches CustomerCreatePage for consistency
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
  final _districtController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _zipController = TextEditingController();

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

      final configService = ConfigService();
      final storage = SecureStorageService();

      final config = await configService.load();
      final db = config['database'] as String?;
      final apiKey = await storage.getAccessToken();

      if (db == null || apiKey == null) return;

      final locationDatasource = LocationRemoteDataSource();

      // Load all districts
      final districts = await locationDatasource.getAllDistricts(
        db: db,
        apiKey: apiKey,
      );

      // Build district name map
      final districtMap = <int, String>{};
      for (final district in districts) {
        districtMap[district.id] = district.name;
      }

      // Load all cities
      final cities = await locationDatasource.getCities(
        db: db,
        apiKey: apiKey,
      );

      // Build city name map
      final cityMap = <int, String>{};
      final cityToStateMap = <int, int>{};
      for (final city in cities) {
        cityMap[city.id] = city.name;
        cityToStateMap[city.id] = city.stateId;
      }

      // Load all states
      final states = await locationDatasource.getStates(
        db: db,
        apiKey: apiKey,
      );

      // Build state name map
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

        // Set initial district display if customer has district
        _updateDistrictDisplay();
      }
    } catch (e) {
      print('❌ Error loading districts: $e');
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

      final data = {
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

      await context.read<CustomerProvider>().updateCustomer(data);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Customer berhasil diupdate'),
              ],
            ),
            backgroundColor: AppTheme.successColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
        Navigator.pop(context, true); // Return true = success
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Error: $e')),
              ],
            ),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Edit Customer',
          style: theme.appBarTheme.titleTextStyle,
        ),
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon:
              Icon(Icons.arrow_back, color: theme.appBarTheme.iconTheme?.color),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
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

            const SizedBox(height: 15),

            // Name Field (Required)
            _buildSectionLabel('Nama Customer *'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nameController,
              style: TextStyle(color: theme.textTheme.bodyLarge?.color),
              decoration: InputDecoration(
                hintText: 'Contoh: PT Maju Jaya',
                prefixIcon: Icon(Icons.person_outline,
                    color: AppTheme.brandBlue, size: 20),
                filled: true,
                fillColor: theme.cardTheme.color,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: theme.brightness == Brightness.dark
                        ? Colors.grey[700]!
                        : Colors.grey.shade300,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: theme.brightness == Brightness.dark
                        ? Colors.grey[700]!
                        : Colors.grey.shade300,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.brandBlue),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
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

            const SizedBox(height: 15),

            // Email Field
            _buildSectionLabel('Email'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                hintText: 'Contoh: customer@example.com',
                prefixIcon:
                    Icon(Icons.email_outlined, color: Colors.blue, size: 20),
                filled: true,
                fillColor: theme.cardTheme.color,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                      color: theme.brightness == Brightness.dark
                          ? Colors.grey[700]!
                          : Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                      color: theme.brightness == Brightness.dark
                          ? Colors.grey[700]!
                          : Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.brandBlue),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
              validator: (value) {
                if (value != null && value.trim().isNotEmpty) {
                  // Basic email validation
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

            const SizedBox(height: 15),

            // Phone Field
            _buildSectionLabel('Nomor Telepon'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _phoneController,
              style: TextStyle(color: theme.textTheme.bodyLarge?.color),
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                hintText: 'Contoh: 8123456789',
                prefixText: '+62 ',
                prefixStyle: TextStyle(
                  color: theme.textTheme.bodyLarge?.color,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                prefixIcon:
                    Icon(Icons.phone_outlined, color: Colors.green, size: 20),
                filled: true,
                fillColor: theme.cardTheme.color,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                      color: theme.brightness == Brightness.dark
                          ? Colors.grey[700]!
                          : Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                      color: theme.brightness == Brightness.dark
                          ? Colors.grey[700]!
                          : Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.brandBlue),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
              textInputAction: TextInputAction.next,
            ),

            const SizedBox(height: 15),

            // Street Field
            _buildSectionLabel('Alamat'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _streetController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Contoh: Jl. Merdeka No. 123',
                prefixIcon:
                    Icon(Icons.home_outlined, color: Colors.orange, size: 20),
                filled: true,
                fillColor: theme.cardTheme.color,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                      color: theme.brightness == Brightness.dark
                          ? Colors.grey[700]!
                          : Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                      color: theme.brightness == Brightness.dark
                          ? Colors.grey[700]!
                          : Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.brandBlue),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
              textInputAction: TextInputAction.next,
            ),

            const SizedBox(height: 15),

            // Street2 Field
            _buildSectionLabel('Alamat Lanjutan'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _street2Controller,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Contoh: RT/RW, Kompleks, dll',
                prefixIcon: Icon(Icons.home_work_outlined,
                    color: Colors.deepOrange, size: 20),
                filled: true,
                fillColor: theme.cardTheme.color,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                      color: theme.brightness == Brightness.dark
                          ? Colors.grey[700]!
                          : Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                      color: theme.brightness == Brightness.dark
                          ? Colors.grey[700]!
                          : Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.brandBlue),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
              textInputAction: TextInputAction.next,
            ),

            const SizedBox(height: 15),

            // District Field with Search Button
            _buildSectionLabel('District'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _districtController,
                    readOnly: true,
                    style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                    decoration: InputDecoration(
                      hintText: 'Pilih District',
                      prefixIcon: Icon(Icons.location_on_outlined,
                          color: Colors.red, size: 20),
                      filled: true,
                      fillColor: theme.cardTheme.color,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                            color: theme.brightness == Brightness.dark
                                ? Colors.grey[700]!
                                : Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                            color: theme.brightness == Brightness.dark
                                ? Colors.grey[700]!
                                : Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppTheme.brandBlue),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 48,
                  width: 48,
                  child: ElevatedButton(
                    onPressed: _districtLoading || _allDistricts.isEmpty
                        ? null
                        : _selectDistrict,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      disabledBackgroundColor: Colors.grey[400],
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _districtLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.search, size: 20),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 15),

            // City Field (auto-filled from district)
            _buildSectionLabel('Kota/Kabupaten (Auto-filled)'),
            const SizedBox(height: 8),
            TextField(
              controller: _cityController,
              readOnly: true,
              style: TextStyle(color: theme.textTheme.bodyLarge?.color),
              decoration: InputDecoration(
                hintText: 'Kota akan muncul otomatis setelah memilih distrik',
                prefixIcon: Icon(Icons.location_city_outlined,
                    color: Colors.purple, size: 20),
                filled: true,
                fillColor: theme.brightness == Brightness.dark
                    ? theme.cardTheme.color?.withValues(alpha: 0.5)
                    : Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                      color: theme.brightness == Brightness.dark
                          ? Colors.grey[700]!
                          : Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                      color: theme.brightness == Brightness.dark
                          ? Colors.grey[700]!
                          : Colors.grey.shade300),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),

            const SizedBox(height: 15),

            // State Field (auto-filled from district)
            _buildSectionLabel('Provinsi (Auto-filled)'),
            const SizedBox(height: 8),
            TextField(
              controller: _stateController,
              readOnly: true,
              style: TextStyle(color: theme.textTheme.bodyLarge?.color),
              decoration: InputDecoration(
                hintText:
                    'Provinsi akan muncul otomatis setelah memilih distrik',
                prefixIcon:
                    Icon(Icons.map_outlined, color: Colors.indigo, size: 20),
                filled: true,
                fillColor: theme.brightness == Brightness.dark
                    ? theme.cardTheme.color?.withValues(alpha: 0.5)
                    : Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                      color: theme.brightness == Brightness.dark
                          ? Colors.grey[700]!
                          : Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                      color: theme.brightness == Brightness.dark
                          ? Colors.grey[700]!
                          : Colors.grey.shade300),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),

            const SizedBox(height: 15),

            // ZIP Field
            _buildSectionLabel('Kode Pos'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _zipController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'Contoh: 60233',
                prefixIcon: Icon(Icons.markunread_mailbox_outlined,
                    color: Colors.teal, size: 20),
                filled: true,
                fillColor: theme.cardTheme.color,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                      color: theme.brightness == Brightness.dark
                          ? Colors.grey[700]!
                          : Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                      color: theme.brightness == Brightness.dark
                          ? Colors.grey[700]!
                          : Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.brandBlue),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
              textInputAction: TextInputAction.done,
            ),

            const SizedBox(height: 32),

            // Submit Button
            Container(
              width: double.infinity,
              height: 50,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.brandBlue, AppTheme.primaryLight],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.brandBlue.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Update Customer',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    final theme = Theme.of(context);
    return Text(
      label,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: theme.textTheme.titleMedium?.color,
      ),
    );
  }
}
