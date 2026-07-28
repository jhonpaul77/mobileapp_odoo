import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../config/theme.dart';
import '../../domain/entities/customer.dart';

/// CustomerDetailPage - Display detailed customer information
///
/// Shows all customer data from Odoo API in a beautiful layout
class CustomerDetailPage extends StatelessWidget {
  final Customer customer;

  const CustomerDetailPage({
    super.key,
    required this.customer,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: CustomScrollView(
        slivers: [
          // Sticky Header with Avatar
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: AppTheme.primaryColor,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.white),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Fitur edit customer akan segera hadir'),
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                onPressed: () {
                  _showMoreOptions(context);
                },
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryColor,
                      AppTheme.primaryColor.withValues(alpha: 0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      // Avatar
                      Hero(
                        tag: 'customer-${customer.id}',
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(40),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              customer.name.isNotEmpty
                                  ? customer.name[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Customer Name
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          customer.name,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Customer ID
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'ID: ${customer.id}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Quick Actions
                  _buildQuickActions(context),
                  const SizedBox(height: 20),

                  // Contact Information Section
                  _buildSectionHeader(
                      'Informasi Kontak', Icons.contacts_rounded),
                  const SizedBox(height: 12),
                  _buildContactSection(),
                  const SizedBox(height: 20),

                  // Address Information Section
                  _buildSectionHeader(
                      'Informasi Alamat', Icons.location_on_rounded),
                  const SizedBox(height: 12),
                  _buildAddressSection(),
                  const SizedBox(height: 20),

                  // Additional Information
                  _buildSectionHeader('Informasi Tambahan', Icons.info_rounded),
                  const SizedBox(height: 12),
                  _buildAdditionalInfo(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build quick action buttons
  Widget _buildQuickActions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (customer.phone != null && customer.phone!.isNotEmpty)
            Expanded(
              child: _buildActionButton(
                icon: Icons.phone_rounded,
                label: 'Telepon',
                color: Colors.green,
                onTap: () {
                  _makePhoneCall(context, customer.phone!);
                },
              ),
            ),
          if (customer.phone != null && customer.phone!.isNotEmpty)
            const SizedBox(width: 12),
          if (customer.email != null && customer.email!.isNotEmpty)
            Expanded(
              child: _buildActionButton(
                icon: Icons.email_rounded,
                label: 'Email',
                color: Colors.blue,
                onTap: () {
                  _sendEmail(context, customer.email!);
                },
              ),
            ),
          if (customer.email != null && customer.email!.isNotEmpty)
            const SizedBox(width: 12),
          Expanded(
            child: _buildActionButton(
              icon: Icons.message_rounded,
              label: 'Chat',
              color: Colors.orange,
              onTap: () {
                _sendMessage(context);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build section header
  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 20,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  /// Build contact information section
  Widget _buildContactSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          if (customer.phone != null && customer.phone!.isNotEmpty)
            _buildDetailRow(
              icon: Icons.phone_rounded,
              iconColor: Colors.green,
              label: 'Telepon',
              value: customer.phone!,
              onCopy: () => _copyToClipboard(customer.phone!),
            ),
          if (customer.phone != null &&
              customer.phone!.isNotEmpty &&
              customer.email != null &&
              customer.email!.isNotEmpty)
            const Divider(height: 24),
          if (customer.email != null && customer.email!.isNotEmpty)
            _buildDetailRow(
              icon: Icons.email_rounded,
              iconColor: Colors.blue,
              label: 'Email',
              value: customer.email!,
              onCopy: () => _copyToClipboard(customer.email!),
            ),
          if ((customer.phone == null || customer.phone!.isEmpty) &&
              (customer.email == null || customer.email!.isEmpty))
            _buildEmptyState('Tidak ada informasi kontak'),
        ],
      ),
    );
  }

  /// Build address information section
  Widget _buildAddressSection() {
    final hasAddress =
        (customer.street != null && customer.street!.isNotEmpty) ||
            (customer.city != null && customer.city!.isNotEmpty) ||
            customer.stateName != null ||
            customer.countryName != null ||
            (customer.zip != null && customer.zip!.isNotEmpty);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: hasAddress
          ? Column(
              children: [
                if (customer.street != null && customer.street!.isNotEmpty)
                  _buildDetailRow(
                    icon: Icons.home_rounded,
                    iconColor: Colors.orange,
                    label: 'Alamat',
                    value: customer.street!,
                    onCopy: () => _copyToClipboard(customer.street!),
                  ),
                if (customer.street != null &&
                    customer.street!.isNotEmpty &&
                    customer.city != null &&
                    customer.city!.isNotEmpty)
                  const Divider(height: 24),
                if (customer.city != null && customer.city!.isNotEmpty)
                  _buildDetailRow(
                    icon: Icons.location_city_rounded,
                    iconColor: Colors.purple,
                    label: 'Kota',
                    value: customer.city!,
                  ),
                if (customer.city != null &&
                    customer.city!.isNotEmpty &&
                    customer.stateName != null)
                  const Divider(height: 24),
                if (customer.stateName != null)
                  _buildDetailRow(
                    icon: Icons.map_rounded,
                    iconColor: Colors.teal,
                    label: 'Provinsi',
                    value: customer.stateName!,
                  ),
                if (customer.stateName != null &&
                    (customer.zip != null && customer.zip!.isNotEmpty))
                  const Divider(height: 24),
                if (customer.zip != null && customer.zip!.isNotEmpty)
                  _buildDetailRow(
                    icon: Icons.markunread_mailbox_rounded,
                    iconColor: Colors.indigo,
                    label: 'Kode POS',
                    value: customer.zip!,
                  ),
                if ((customer.zip != null && customer.zip!.isNotEmpty) &&
                    customer.countryName != null)
                  const Divider(height: 24),
                if (customer.countryName != null)
                  _buildDetailRow(
                    icon: Icons.public_rounded,
                    iconColor: AppTheme.primaryColor,
                    label: 'Negara',
                    value: customer.countryName!,
                  ),
              ],
            )
          : _buildEmptyState('Tidak ada informasi alamat'),
    );
  }

  /// Build additional information section
  Widget _buildAdditionalInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          _buildDetailRow(
            icon: Icons.fingerprint_rounded,
            iconColor: Colors.deepPurple,
            label: 'Customer ID',
            value: customer.id.toString(),
            onCopy: () => _copyToClipboard(customer.id.toString()),
          ),
          const Divider(height: 24),
          _buildDetailRow(
            icon: Icons.location_on_rounded,
            iconColor: Colors.red,
            label: 'Alamat Lengkap',
            value: customer.fullAddress.isNotEmpty
                ? customer.fullAddress
                : 'Tidak ada alamat',
            onCopy: customer.fullAddress.isNotEmpty
                ? () => _copyToClipboard(customer.fullAddress)
                : null,
          ),
        ],
      ),
    );
  }

  /// Build detail row with icon, label, and value
  Widget _buildDetailRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    VoidCallback? onCopy,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Icon
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 20,
            color: iconColor,
          ),
        ),
        const SizedBox(width: 14),

        // Label & Value
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  color: Colors.black87,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),

        // Copy button
        if (onCopy != null)
          IconButton(
            icon: Icon(
              Icons.copy_rounded,
              size: 18,
              color: Colors.grey[400],
            ),
            onPressed: onCopy,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
      ],
    );
  }

  /// Build empty state message
  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(Icons.info_outline, size: 48, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text(
              message,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Show more options bottom sheet
  void _showMoreOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading:
                  const Icon(Icons.share_rounded, color: AppTheme.primaryColor),
              title: const Text('Bagikan Customer'),
              onTap: () {
                Navigator.pop(context);
                _shareCustomer(context);
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.favorite_border_rounded, color: Colors.red),
              title: const Text('Tandai Favorit'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Fitur favorit akan segera hadir')),
                );
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.delete_outline_rounded, color: Colors.red),
              title: const Text('Hapus Customer'),
              onTap: () {
                Navigator.pop(context);
                _confirmDelete(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Copy to clipboard
  void _copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
  }

  /// Make phone call
  void _makePhoneCall(BuildContext context, String phone) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Menelepon: $phone')),
    );
    // TODO: Implement actual phone call using url_launcher
  }

  /// Send email
  void _sendEmail(BuildContext context, String email) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Mengirim email ke: $email')),
    );
    // TODO: Implement actual email using url_launcher
  }

  /// Send message
  void _sendMessage(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Fitur chat akan segera hadir')),
    );
  }

  /// Share customer
  void _shareCustomer(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Fitur share akan segera hadir')),
    );
    // TODO: Implement share using share_plus package
  }

  /// Confirm delete
  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Customer'),
        content: Text('Yakin ingin menghapus ${customer.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
              // TODO: Implement delete customer API
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}
