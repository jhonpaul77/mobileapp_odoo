import 'package:flutter/material.dart';
import 'package:pintarx/config/theme.dart';
// import semua page yang diperlukan
import 'package:pintarx/pages/settings/location/location_list_page.dart';
// import 'package:pintarx/pages/master/product_measurement_page.dart';
import 'package:pintarx/pages/settings/organization/organization_list_page.dart';
import 'package:pintarx/pages/settings/product_category/product_category_list_page.dart';
import 'package:pintarx/pages/settings/product_group/product_group_list_page.dart';
// import 'package:pintarx/pages/master/role_page.dart';
// import 'package:pintarx/pages/master/user_page.dart';

class SettingPage extends StatelessWidget {
  const SettingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          const Text(
            "Pengaturan",
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Kelola data master aplikasi Anda",
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 24),

          // Section: Master Data
          _buildSectionTitle("Master Data"),
          _buildSettingItem(
            icon: Icons.location_on_rounded,
            title: "Lokasi",
            subtitle: "Kelola daftar lokasi",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LocationListPage()),
              );
            },
          ),
          _buildSettingItem(
            icon: Icons.category_rounded,
            title: "Kategori Produk",
            subtitle: "Atur kategori produk",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const ProductCategoryListPage()),
              );
            },
          ),
          _buildSettingItem(
            icon: Icons.group_work_rounded,
            title: "Grup Produk",
            subtitle: "Kelompokkan produk berdasarkan grup",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProductGroupListPage()),
              );
            },
          ),
          _buildSettingItem(
            icon: Icons.straighten_rounded,
            title: "Satuan Produk",
            subtitle: "Kelola unit atau satuan produk",
            onTap: () {
              // Navigator.push(
              //   context,
              //   MaterialPageRoute(builder: (_) => const ProductMeasurementPage()),
              // );
            },
          ),

          const SizedBox(height: 24),

          // Section: Organization
          _buildSectionTitle("Organisasi & Akses"),
          _buildSettingItem(
            icon: Icons.business_rounded,
            title: "Organisasi",
            subtitle: "Kelola data organisasi",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const OrganizationListPage()),
              );
            },
          ),
          _buildSettingItem(
            icon: Icons.admin_panel_settings_rounded,
            title: "Role / Jabatan",
            subtitle: "Atur hak akses pengguna",
            onTap: () {
              // Navigator.push(
              //   context,
              //   MaterialPageRoute(builder: (_) => const RolePage()),
              // );
            },
          ),
          _buildSettingItem(
            icon: Icons.people_alt_rounded,
            title: "Pengguna",
            subtitle: "Kelola akun pengguna aplikasi",
            onTap: () {
              // Navigator.push(
              //   context,
              //   MaterialPageRoute(builder: (_) => const UserPage()),
              // );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: AppTheme.textPrimary,
        ),
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!, width: 1),
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
            // Icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  //colors: [ Color(0xFF89f7fe),Color(0xFF66a6ff)],
                  //colors: [Color(0xFF84fab0), Color(0xFF8fd3f4)],
                  colors: [AppTheme.kotakblue, AppTheme.kotakblue2],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Trailing icon
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }
}
