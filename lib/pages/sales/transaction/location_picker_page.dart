import 'package:flutter/material.dart';
import 'package:pintarx/config/theme.dart';
import 'package:pintarx/models/location_picker.dart';

class LocationPickerPage extends StatefulWidget {
  final String? initialProvince;
  final String? initialCity;
  final String? initialDistrict;

  const LocationPickerPage({
    super.key,
    this.initialProvince,
    this.initialCity,
    this.initialDistrict,
  });

  @override
  State<LocationPickerPage> createState() => _LocationPickerPageState();
}

class _LocationPickerPageState extends State<LocationPickerPage> {
  late TextEditingController _searchController;
  List<DistrictInfo> _searchResults = [];
  List<DistrictInfo> _filteredResults = [];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchResults = List.from(locationDatabase);
    _filteredResults = _searchResults;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _search(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredResults = _searchResults;
      });
      return;
    }

    final lowerQuery = query.toLowerCase();
    setState(() {
      _filteredResults = _searchResults.where((location) {
        return location.district.toLowerCase().contains(lowerQuery) ||
            location.city.toLowerCase().contains(lowerQuery) ||
            location.province.toLowerCase().contains(lowerQuery);
      }).toList();
    });
  }

  void _selectLocation(DistrictInfo location) {
    Navigator.of(context).pop(LocationData(
      province: location.province,
      city: location.city,
      district: location.district,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Pilih Lokasi',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          // Search Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: Colors.white,
            child: TextField(
              controller: _searchController,
              onChanged: _search,
              decoration: InputDecoration(
                prefixIcon:
                    Icon(Icons.search, color: Colors.grey[600], size: 18),
                suffixIcon: _searchController.text.isNotEmpty
                    ? SizedBox(
                        width: 32,
                        height: 32,
                        child: IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            _search('');
                          },
                        ),
                      )
                    : null,
                hintText: 'Cari kecamatan, kabupaten...',
                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 12),
                filled: true,
                fillColor: Colors.grey[50],
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                      color: AppTheme.primaryColor, width: 1.5),
                ),
              ),
            ),
          ),
          // Results
          Expanded(
            child: _filteredResults.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.location_off,
                            size: 48, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text(
                          _searchController.text.isEmpty
                              ? 'Search a location'
                              : 'No location found',
                          style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 15,
                              fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    itemCount: _filteredResults.length,
                    itemBuilder: (context, index) {
                      final location = _filteredResults[index];

                      return GestureDetector(
                        onTap: () => _selectLocation(location),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Colors.grey[200]!,
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              )
                            ],
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.location_on,
                                  size: 16,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${location.district}, ${location.city}, ${location.province}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                        color: Colors.black87,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_ios,
                                size: 14,
                                color: AppTheme.primaryColor
                                    .withValues(alpha: 0.5),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
