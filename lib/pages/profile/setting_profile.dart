import 'package:flutter/material.dart';
import 'package:pintarx/config/theme.dart';
import 'package:pintarx/pages/auth/login_page.dart';
import 'package:pintarx/pages/profile/profile_page.dart';
import 'package:pintarx/providers/theme_provider.dart';
import 'package:pintarx/services/auth_service.dart';
import 'package:pintarx/services/config_service.dart';
import 'package:provider/provider.dart';

class SettingProfile extends StatefulWidget {
  const SettingProfile({super.key});

  @override
  State<SettingProfile> createState() => _SettingProfileState();
}

class _SettingProfileState extends State<SettingProfile> {
  final _authService = AuthService();
  final _configService = ConfigService();
  String _database = '';
  String _url = '';

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    final config = await _configService.load();
    setState(() {
      _database = config['database'] ?? '-';
      _url = config['url'] ?? '-';
    });
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: AppTheme.dangerColor),
            SizedBox(width: 12),
            Text('Logout'),
          ],
        ),
        content: const Text('Anda yakin ingin keluar dari aplikasi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.dangerColor,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _authService.signOut();
      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    }
  }

  void _showInfoDataModal() {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.cardTheme.color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.kotakblue, AppTheme.kotakblue2],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.storage_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Info Data',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: theme.textTheme.bodyLarge?.color,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Database
            _buildModalInfoRow(
              icon: Icons.dns_rounded,
              label: 'Database',
              value: _database,
            ),
            const SizedBox(height: 16),
            Divider(
              height: 1,
              color: theme.brightness == Brightness.dark
                  ? Colors.grey[700]
                  : Colors.grey[300],
            ),
            const SizedBox(height: 16),
            // Server URL
            _buildModalInfoRow(
              icon: Icons.link_rounded,
              label: 'Server URL',
              value: _url,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  Widget _buildModalInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: AppTheme.primaryColor,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: theme.textTheme.bodySmall?.color,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  color: theme.textTheme.bodyLarge?.color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
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
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Kelola preferensi aplikasi Anda",
              style: TextStyle(
                fontSize: 14,
                color: theme.textTheme.bodySmall?.color,
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
                activeThumbColor: AppTheme.primaryColor,
              ),
            ),
            Consumer<ThemeProvider>(
              builder: (context, themeProvider, child) {
                return _buildSettingItem(
                  icon: Icons.dark_mode_rounded,
                  title: "Mode Gelap",
                  subtitle: themeProvider.isDarkMode
                      ? "Mode gelap aktif"
                      : "Mode terang aktif",
                  trailing: Switch(
                    value: themeProvider.isDarkMode,
                    onChanged: (value) async {
                      await themeProvider.toggleTheme();
                    },
                    activeThumbColor: AppTheme.primaryColor,
                  ),
                );
              },
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
              icon: Icons.storage_rounded,
              title: "Info Data",
              subtitle: "Data Aplikasi",
              onTap: _showInfoDataModal,
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

            const SizedBox(height: 24),

            // Logout Button
            _buildLogoutButton(),

            const SizedBox(height: 16),
          ],
        ),
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: theme.cardTheme.color,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
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
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: theme.textTheme.bodySmall?.color,
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
                color: theme.textTheme.bodySmall?.color,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    final theme = Theme.of(context);

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _handleLogout,
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.brightness == Brightness.dark
              ? Colors.grey[800]
              : Colors.grey[200],
          foregroundColor: theme.textTheme.bodyLarge?.color,
          padding: const EdgeInsets.symmetric(vertical: 16),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        icon: const Icon(Icons.logout_rounded),
        label: const Text(
          'Logout',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
