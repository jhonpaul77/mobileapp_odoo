import 'package:flutter/material.dart';

import '../../../../config/theme.dart';
import '../../../../services/customer_service.dart';
import '../../../../services/config_service.dart';
import '../../../../services/secure_storage_service.dart';
import '../../../location/data/datasources/location_remote_datasource.dart';
import '../../../location/domain/entities/district.dart';
import '../../../sales_order/presentation/pages/district_search_modal.dart';
import '../../domain/entities/customer.dart';

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
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _streetController;
  late TextEditingController _street2Controller;
  late TextEditingController _zipController;
  late TextEditingController _districtController;
  late TextEditingController _cityIdController;

  int? _selectedDistrictId;
  int? _selectedCityId;
  int? _selectedStateId;
  List<District> _allDistricts = [];
  bool _districtLoading = false;
  Map<int, String> _cityMap = {};
  Map<int, String> _stateMap = {};
  Map<int, int> _cityToStateMap = {};
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.customer.name);
    _emailController = TextEditingController(text: widget.customer.email ?? '');
    
    // Extract phone number without +62 prefix
    String phoneText = widget.customer.phone ?? '';
    if (phoneText.startsWith('+62')) {
      phoneText = phoneText.substring(3);
    } else if (phoneText.startsWith('62')) {
      phoneText = phoneText.substring(2);
    } else if (phoneText.startsWith('0')) {
      phoneText = phoneText.substring(1);
    }
    _phoneController = TextEditingController(text: phoneText);
    
    _streetController = TextEditingController(text: widget.customer.street ?? '');
    _street2Controller = TextEditingController(text: widget.customer.street2 ?? '');
    _zipController = TextEditingController(text: widget.customer.zip ?? '');
    _districtController = TextEditingController();
    _cityIdController = TextEditingController();

    _selectedDistrictId = widget.customer.districtId;
    _selectedCityId = widget.customer.cityId;
    _selectedStateId = widget.customer.stateId;

    _loadDistrictsAndLocations();
  }

  Future<void> _loadDistrictsAndLocations() async {
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

      // Now load the current location names for the customer
      if (_selectedDistrictId != null) {
        final districtName = await locationDatasource.getDistrictName(
          districtId: _selectedDistrictId!,
          db: db,
          apiKey: apiKey,
        );
        if (mounted) {
          _districtController.text = districtName ?? '';
        }
      }

      // Build display text for location (District, City, State)
      if (_selectedCityId != null) {
        if (_selectedStateId != null) {
          final districtName = _districtController.text;
          final cityName = cityMap[_selectedCityId!] ?? '';
          final stateName = stateMap[_selectedStateId!] ?? '';
          
          final displayParts = <String>[];
          if (districtName.isNotEmpty) displayParts.add(districtName);
          if (cityName.isNotEmpty) displayParts.add(cityName);
          if (stateName.isNotEmpty) displayParts.add(stateName);
          
          if (mounted) {
            _cityIdController.text = displayParts.join(', ');
          }
        }
      }

      if (mounted) {
        setState(() {
          _allDistricts = districts;
          _cityMap = cityMap;
          _stateMap = stateMap;
          _cityToStateMap = cityToStateMap;
        });
      }
    } catch (e) {
      print('❌ Error loading districts: $e');
    } finally {
      if (mounted) setState(() => _districtLoading = false);
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

      // Build display text: District, City, State
      final displayParts = [selected.name];
      if (cityName.isNotEmpty) displayParts.add(cityName);
      if (stateName.isNotEmpty) displayParts.add(stateName);
      final displayText = displayParts.join(', ');

      setState(() {
        _selectedDistrictId = selected.id;
        _selectedCityId = selected.cityId;
        _selectedStateId = stateId;
        _districtController.text = selected.name;
        _cityIdController.text = displayText;
      });
    }
  }

  Future<void> _saveChanges() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama customer tidak boleh kosong')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final customerService = CustomerService();
      
      // Format phone number with +62 prefix
      final phoneNumber = _phoneController.text.trim();
      final formattedPhone = phoneNumber.isNotEmpty ? '+62$phoneNumber' : '';

      final result = await customerService.editCustomerOdoo(
        id: widget.customer.id,
        name: _nameController.text.trim(),
        email: _emailController.text.isEmpty ? null : _emailController.text.trim(),
        phone: formattedPhone.isEmpty ? null : formattedPhone,
        street: _streetController.text.isEmpty ? null : _streetController.text.trim(),
        street2: _street2Controller.text.isEmpty ? null : _street2Controller.text.trim(),
        zip: _zipController.text.isEmpty ? null : _zipController.text.trim(),
        districtId: _selectedDistrictId,
        cityId: _selectedCityId,
        stateId: _selectedStateId,
      );

      if (mounted) {
        if (result['Success'] == true) {
          // Langsung close dan return true tanpa show snackbar
          // Detail page akan handle refresh dan show snackbar sendiri
          Navigator.pop(context, true);
        } else {
          setState(() => _isSubmitting = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(child: Text('Error: ${result['Message']}')),
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
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _streetController.dispose();
    _street2Controller.dispose();
    _zipController.dispose();
    _districtController.dispose();
    _cityIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
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

            const SizedBox(height: 20),

            // Name Field (Required)
            _buildSectionLabel('Nama Customer *'),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: 'Contoh: PT Maju Jaya',
                prefixIcon: Icon(Icons.person_outline,
                    color: AppTheme.brandBlue, size: 20),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
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

            const SizedBox(height: 20),

            // Email Field
            _buildSectionLabel('Email'),
            const SizedBox(height: 8),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                hintText: 'Contoh: info@example.com',
                prefixIcon:
                    Icon(Icons.email_outlined, color: Colors.blue, size: 20),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
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

            const SizedBox(height: 20),

            // Phone Field
            _buildSectionLabel('Nomor Telepon'),
            const SizedBox(height: 8),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                hintText: 'Contoh: 8123456789',
                prefixText: '+62 ',
                prefixIcon:
                    Icon(Icons.phone_outlined, color: Colors.green, size: 20),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
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

            const SizedBox(height: 20),

            // Street Field
            _buildSectionLabel('Alamat'),
            const SizedBox(height: 8),
            TextField(
              controller: _streetController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Contoh: Jl. Merdeka No. 123',
                prefixIcon:
                    Icon(Icons.home_outlined, color: Colors.orange, size: 20),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
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

            const SizedBox(height: 20),

            // Street2 Field
            _buildSectionLabel('Alamat Lanjutan'),
            const SizedBox(height: 8),
            TextField(
              controller: _street2Controller,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Contoh: RT/RW 01/02',
                prefixIcon:
                    Icon(Icons.home_work_outlined, color: Colors.purple, size: 20),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
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

            const SizedBox(height: 20),

            // ZIP Field
            _buildSectionLabel('Kode Pos'),
            const SizedBox(height: 8),
            TextField(
              controller: _zipController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'Contoh: 60233',
                prefixIcon: Icon(Icons.markunread_mailbox_outlined,
                    color: Colors.teal, size: 20),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
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

            const SizedBox(height: 20),

            // District Field with Search Button
            _buildSectionLabel('Kecamatan'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _districtController,
                    readOnly: true,
                    decoration: InputDecoration(
                      hintText: 'Pilih Kecamatan',
                      prefixIcon: Icon(Icons.location_on_outlined,
                          color: Colors.red, size: 20),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
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
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _districtLoading || _allDistricts.isEmpty
                        ? null
                        : _selectDistrict,
                    icon: _districtLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.search, size: 16),
                    label: Text(_districtLoading ? 'Loading...' : 'Search'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      disabledBackgroundColor: Colors.grey[400],
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // City ID Field (auto-filled from district)
            _buildSectionLabel('Lokasi (Auto-filled)'),
            const SizedBox(height: 8),
            TextField(
              controller: _cityIdController,
              readOnly: true,
              decoration: InputDecoration(
                hintText: 'Kecamatan, Kota, Provinsi akan muncul otomatis',
                prefixIcon: Icon(Icons.location_city_outlined,
                    color: Colors.purple, size: 20),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
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
                onPressed: _isSubmitting ? null : _saveChanges,
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
                        'Simpan Perubahan',
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
    return Text(
      label,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppTheme.textPrimary,
      ),
    );
  }
}
