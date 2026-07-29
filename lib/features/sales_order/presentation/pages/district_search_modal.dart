import 'package:flutter/material.dart';
import '../../../location/domain/entities/district.dart';
import '../../../../config/theme.dart';

/// District Search Modal
///
/// Allows searching and selecting districts with city and state info
class DistrictSearchModal extends StatefulWidget {
  final List<District> allDistricts;
  final Map<int, String>? cityNames; // Map of cityId -> cityName
  final Map<int, String>? stateNames; // Map of stateId -> stateName
  final Map<int, int>? cityToStateMap; // Map of cityId -> stateId

  const DistrictSearchModal({
    super.key,
    required this.allDistricts,
    this.cityNames,
    this.stateNames,
    this.cityToStateMap,
  });

  @override
  State<DistrictSearchModal> createState() => _DistrictSearchModalState();
}

class _DistrictSearchModalState extends State<DistrictSearchModal> {
  late TextEditingController _searchController;
  late List<District> _filteredDistricts;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _filteredDistricts = widget.allDistricts;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredDistricts = widget.allDistricts;
      } else {
        final lowerQuery = query.toLowerCase();
        _filteredDistricts = widget.allDistricts
            .where((district) {
              final districtMatch = district.name.toLowerCase().contains(lowerQuery);
              final cityName = widget.cityNames?[district.cityId] ?? '';
              final cityMatch = cityName.toLowerCase().contains(lowerQuery);
              return districtMatch || cityMatch;
            })
            .toList();
      }
    });
  }

  String _getCityName(int cityId) {
    return widget.cityNames?[cityId] ?? '';
  }

  String _getStateName(int cityId) {
    final stateId = widget.cityToStateMap?[cityId];
    if (stateId == null) return '';
    return widget.stateNames?[stateId] ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    'Search District',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          ),

          // Search Field
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search district or city...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
            ),
          ),

          // Results List
          Expanded(
            child: _filteredDistricts.isEmpty
                ? Center(
                    child: Text(
                      _searchController.text.isEmpty
                          ? 'No districts available'
                          : 'No matching districts',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: _filteredDistricts.length,
                    itemBuilder: (context, index) {
                      final district = _filteredDistricts[index];
                      final cityName = _getCityName(district.cityId);
                      final stateName = _getStateName(district.cityId);
                      
                      // Build display text: District, City, State
                      final displayParts = [district.name];
                      if (cityName.isNotEmpty) displayParts.add(cityName);
                      if (stateName.isNotEmpty) displayParts.add(stateName);
                      final displayText = displayParts.join(', ');
                      
                      return InkWell(
                        onTap: () => Navigator.pop(context, district),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: Colors.grey[200]!,
                              ),
                            ),
                          ),
                          child: Text(
                            displayText,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
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
