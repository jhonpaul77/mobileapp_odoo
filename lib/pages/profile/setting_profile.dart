import 'package:flutter/material.dart';
import 'package:pintarx/config/theme.dart';
import 'package:pintarx/pages/profile/profile_page.dart';

class SettingProfile extends StatelessWidget {
  const SettingProfile({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          const Text(
            "Profil",
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Kelola preferensi aplikasi Anda",
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          
          // Account Section
          _buildSectionTitle("Akun"),
          _buildSettingItem(
            icon: Icons.person_rounded,
            title: "Informasi Profil",
            subtitle: "Edit informasi profil Anda",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfilePage()),
              );
            },
          ),
          _buildSettingItem(
            icon: Icons.lock_rounded,
            title: "Keamanan",
            subtitle: "PIN dan pengaturan biometrik",
            onTap: () {},
          ),
          
          const SizedBox(height: 24),
          
          // App Settings
          _buildSectionTitle("Aplikasi"),
          _buildSettingItem(
            icon: Icons.notifications_rounded,
            title: "Notifikasi",
            subtitle: "Kelola notifikasi aplikasi",
            trailing: Switch(
              value: true,
              onChanged: (value) {},
              activeColor: AppTheme.primaryColor,
            ),
          ),
          _buildSettingItem(
            icon: Icons.dark_mode_rounded,
            title: "Mode Gelap",
            subtitle: "Aktifkan tema gelap",
            trailing: Switch(
              value: false,
              onChanged: (value) {},
              activeColor: AppTheme.primaryColor,
            ),
          ),
          _buildSettingItem(
            icon: Icons.language_rounded,
            title: "Bahasa",
            subtitle: "Indonesia",
            onTap: () {},
          ),
          
          const SizedBox(height: 24),
          
          // Data Section
          _buildSectionTitle("Data"),
          _buildSettingItem(
            icon: Icons.backup_rounded,
            title: "Backup Data",
            subtitle: "Cadangkan data aplikasi",
            onTap: () {},
          ),
          _buildSettingItem(
            icon: Icons.sync_rounded,
            title: "Sinkronisasi",
            subtitle: "Sinkronkan data dengan server",
            onTap: () {},
          ),
          
          const SizedBox(height: 24),
          
          // About Section
          _buildSectionTitle("Tentang"),
          _buildSettingItem(
            icon: Icons.info_rounded,
            title: "Tentang Aplikasi",
            subtitle: "Versi 1.0.0",
            onTap: () {},
          ),
          _buildSettingItem(
            icon: Icons.help_rounded,
            title: "Bantuan & Dukungan",
            subtitle: "Hubungi tim support",
            onTap: () {},
          ),
          _buildSettingItem(
            icon: Icons.description_rounded,
            title: "Syarat & Ketentuan",
            subtitle: "Kebijakan privasi",
            onTap: () {},
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
    Widget? trailing,
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
              color: Colors.black.withOpacity(0.04),
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
            // Trailing widget
            if (trailing != null)
              trailing
            else
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