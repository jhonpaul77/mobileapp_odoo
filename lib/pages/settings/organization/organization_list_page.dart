import 'package:flutter/material.dart';
import 'package:pintarx/models/organization/organization.dart';
import 'package:pintarx/services/organization_service.dart';
import 'package:pintarx/config/theme.dart';
import 'package:pintarx/services/status_bar_service.dart';
import 'organization_detail_page.dart';
import 'organization_form_page.dart';

class OrganizationListPage extends StatefulWidget {
  const OrganizationListPage({Key? key}) : super(key: key);

  @override
  State<OrganizationListPage> createState() => _OrganizationListPageState();
}

class _OrganizationListPageState extends State<OrganizationListPage> {
  final _organizationService = OrganizationService();
  final _searchController = TextEditingController();

  List<Organization> _organizations = [];
  List<Organization> _filteredOrganizations = [];
  bool _isLoading = true;
  String? _errorMessage;
  bool _showInactive = false;

  @override
  void initState() {
    super.initState();
    StatusBarService.setLightStatusBar();
    _loadOrganizations();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadOrganizations() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final response = await _organizationService.fetchOrganizations(length: 50);

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (response.success && response.data != null) {
          _organizations = response.data!;
          _filterOrganizations('');
        } else {
          _errorMessage = response.message;
        }
      });
    }
  }

  void _filterOrganizations(String query) {
    setState(() {
      List<Organization> filtered = _organizations;

      // Filter by status - _showInactive = true berarti tampilkan semua, false = aktif saja
      if (_showInactive == false) {
        filtered = filtered.where((org) => org.isActive).toList();
      }

      // Filter by search query
      if (query.isNotEmpty) {
        filtered = filtered.where((org) {
          return org.nama.toLowerCase().contains(query.toLowerCase()) ||
              org.noTelp.toLowerCase().contains(query.toLowerCase()) ||
              org.kota.toLowerCase().contains(query.toLowerCase()) ||
              org.alamat.toLowerCase().contains(query.toLowerCase());
        }).toList();
      }

      _filteredOrganizations = filtered;
    });
  }

  Future<void> _onRefresh() async {
    await _loadOrganizations();
  }

  void _navigateToDetail(Organization organization) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            OrganizationDetailPage(organizationId: organization.id),
      ),
    ).then((_) => _loadOrganizations());
  }

  void _navigateToAdd() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const OrganizationFormPage(),
      ),
    ).then((result) {
      if (result == true) _loadOrganizations();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildSearchAndFilter(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _onRefresh,
                color: AppTheme.primaryColor,
                child: _buildBody(),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _isLoading
          ? null
          : FloatingActionButton(
              onPressed: _navigateToAdd,
              backgroundColor: AppTheme.brandBlue,
              child:
                  const Icon(Icons.add_rounded, color: Colors.white, size: 28),
            ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(8, 16, 16, 12),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              Icons.arrow_back_rounded,
              color: AppTheme.primaryColor,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          const Text(
            "Daftar Organisasi",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        children: [
          // Search Bar
          Container(
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.backgroundColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!, width: 1),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: _filterOrganizations,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Cari organisasi...',
                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          _filterOrganizations('');
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Filter Status
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _showInactive
                          ? AppTheme.primaryColor
                          : Colors.grey[300]!,
                      width: _showInactive ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        size: 18,
                        color: _showInactive
                            ? Colors.grey[600]
                            : AppTheme.primaryColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Aktif Saja',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _showInactive
                              ? Colors.grey[600]
                              : AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _showInactive = !_showInactive;
                    _filterOrganizations(_searchController.text);
                  });
                },
                child: Container(
                  height: 40,
                  width: 40,
                  decoration: BoxDecoration(
                    color: _showInactive ? AppTheme.primaryColor : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppTheme.primaryColor,
                      width: 1.5,
                    ),
                  ),
                  child: Icon(
                    _showInactive ? Icons.check_rounded : Icons.add_rounded,
                    size: 20,
                    color: _showInactive ? Colors.white : AppTheme.primaryColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    if (_filteredOrganizations.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: _filteredOrganizations.length,
      itemBuilder: (context, index) {
        return _buildOrganizationCard(_filteredOrganizations[index]);
      },
    );
  }

  Widget _buildOrganizationCard(Organization organization) {
    return InkWell(
      onTap: () => _navigateToDetail(organization),
      borderRadius: BorderRadius.circular(12),
      splashColor: AppTheme.primaryColor.withValues(alpha: 0.1),
      highlightColor: AppTheme.primaryColor.withValues(alpha: 0.05),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                organization.isActive ? Colors.grey[200]! : Colors.grey[300]!,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: organization.isActive
                      ? [AppTheme.kotakblue, AppTheme.kotakblue2]
                      : [Colors.grey[400]!, Colors.grey[500]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  organization.nama.isNotEmpty
                      ? organization.nama[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nama
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          organization.nama,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: organization.isActive
                                ? Colors.black87
                                : Colors.grey[500],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (!organization.isActive) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Nonaktif',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Kota & Kecamatan
                  Text(
                    '${organization.kecamatan}, ${organization.kota}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),

                  // No Telp
                  Row(
                    children: [
                      Icon(
                        Icons.phone_rounded,
                        size: 12,
                        color: Colors.grey[500],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        organization.noTelp,
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Chevron
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.grey[400],
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppTheme.primaryColor),
          const SizedBox(height: 16),
          Text(
            'Memuat data organisasi...',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.domain_disabled_rounded,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 20),
          const Text(
            'Tidak ada organisasi',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchController.text.isNotEmpty
                ? 'Coba kata kunci lain'
                : 'Tambahkan organisasi baru',
            style: TextStyle(color: Colors.grey[500], fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 80,
            color: AppTheme.errorColor,
          ),
          const SizedBox(height: AppTheme.paddingMedium),
          Text(
            'Terjadi Kesalahan',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppTheme.paddingSmall),
          Text(
            _errorMessage ?? 'Gagal memuat data',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.paddingLarge),
          ElevatedButton.icon(
            onPressed: _loadOrganizations,
            icon: const Icon(Icons.refresh),
            label: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }
}
