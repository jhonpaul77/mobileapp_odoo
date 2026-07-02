import 'package:flutter/material.dart';
import 'package:pintarx/config/theme.dart';

class AppHeader extends StatefulWidget {
  final String title;
  final String? subtitle;
  final bool showDate;
  final bool showNotification;
  final VoidCallback? onNotificationTap;

  const AppHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.showDate = true,
    this.showNotification = true,
    this.onNotificationTap,
  });

  @override
  State<AppHeader> createState() => _AppHeaderState();
}

class _AppHeaderState extends State<AppHeader> {
  int unreadCount = 3; // TODO: Ambil dari NotificationService nanti

  @override
  void initState() {
    super.initState();
    _loadUnreadCount();
  }

  Future<void> _loadUnreadCount() async {
    // TODO: Uncomment ketika NotificationService sudah siap
    // final count = await NotificationService().getUnreadCount();
    // if (mounted) setState(() => unreadCount = count);
  }

  // Helper untuk format tanggal Indonesia
  String _formatDate(DateTime date) {
    final days = ['Minggu', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'];
    final months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];

    final dayName = days[date.weekday % 7];
    final day = date.day;
    final monthName = months[date.month - 1];
    final year = date.year;

    return '$dayName, $day $monthName $year';
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateString = _formatDate(now);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ═══════════════════════════════════════════════════════════════
        // TOP ROW: Title + Notification Icon
        // ═══════════════════════════════════════════════════════════════
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Left: Title & Subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  if (widget.subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      widget.subtitle!,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Right: Notification Button
            if (widget.showNotification)
              Stack(
                children: [
                  IconButton(
                    onPressed: widget.onNotificationTap,
                    icon: const Icon(
                      Icons.notifications_rounded,
                      size: 28,
                      color: AppTheme.textPrimary,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  // Badge dengan unread count
                  if (unreadCount > 0)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.errorColor,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Text(
                          unreadCount > 99 ? '99+' : '$unreadCount',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
          ],
        ),

        // ═══════════════════════════════════════════════════════════════
        // DATE DISPLAY (Optional)
        // ═══════════════════════════════════════════════════════════════
        if (widget.showDate) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.calendar_today_rounded,
                color: AppTheme.textSecondary,
                size: 14,
              ),
              const SizedBox(width: 6),
              Text(
                dateString,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}