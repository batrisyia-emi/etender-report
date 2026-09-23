// lib/reports/widgets/dashboard/supplier/supplier_notifications_card.dart
//
// The portal's notification feed.
import 'package:flutter/material.dart';

import 'package:etender_reports/reports/widgets/dashboard/dashboard_cards.dart';
import 'package:etender_reports/reports/widgets/dashboard/dashboard_primitives.dart';
import 'package:etender_reports/reports/widgets/dashboard/dashboard_theme.dart';
import 'package:etender_reports/shared/utils/formatters.dart';

class SupplierNotificationsCard extends StatelessWidget {
  const SupplierNotificationsCard({
    super.key,
    required this.notifications,
    required this.readNotifications,
    required this.onMarkAllRead,
  });

  final List<Map<String, dynamic>> notifications;

  /// Indices the supplier has already cleared this session.
  final Set<int> readNotifications;
  final VoidCallback onMarkAllRead;

  static Color _colorOf(Object? severity) => switch (severity?.toString()) {
    'danger' => DashTheme.danger,
    'warning' => DashTheme.warning,
    'success' => DashTheme.success,
    _ => DashTheme.info,
  };

  @override
  Widget build(BuildContext context) {
    var unread = 0;
    for (var i = 0; i < notifications.length; i++) {
      if (notifications[i]['unread'] == true &&
          !readNotifications.contains(i)) {
        unread++;
      }
    }

    return DashCard(
      icon: Icons.notifications_none,
      title: 'Notifications',
      subtitle: unread == 0 ? 'All caught up' : '$unread unread',
      padded: false,
      trailing: unread == 0
          ? null
          : DashButton(label: 'Mark all read', onTap: onMarkAllRead),
      child: notifications.isEmpty
          ? const Padding(
              padding: EdgeInsets.symmetric(horizontal: 18, vertical: 24),
              child: Text(
                'Nothing to read.',
                style: TextStyle(fontSize: 12, color: DashTheme.muted),
              ),
            )
          : Column(
              children: [
                for (var i = 0; i < notifications.length; i++)
                  SupplierNotificationRow(
                    notification: notifications[i],
                    color: _colorOf(notifications[i]['severity']),
                    unread:
                        notifications[i]['unread'] == true &&
                        !readNotifications.contains(i),
                  ),
              ],
            ),
    );
  }
}

class SupplierNotificationRow extends StatelessWidget {
  const SupplierNotificationRow({
    super.key,
    required this.notification,
    required this.color,
    required this.unread,
  });

  final Map<String, dynamic> notification;
  final Color color;
  final bool unread;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
      decoration: BoxDecoration(
        // Unread carries the same pale tint the KPI cards use for an
        // accent, so it reads as emphasis rather than as a new colour.
        color: unread ? DashTheme.tintOf(color) : null,
        border: const Border(bottom: BorderSide(color: DashTheme.border)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 4),
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  notification['message']?.toString() ?? '',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.35,
                    color: DashTheme.text,
                    fontWeight: unread ? FontWeight.w500 : FontWeight.normal,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  formatLastUpdate(notification['timestamp']),
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: DashTheme.muted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
