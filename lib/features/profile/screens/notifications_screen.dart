import 'package:flutter/material.dart';

import 'package:jihc_volunteers_app/core/theme/app_theme.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<_NotificationItem> items = <_NotificationItem>[
      const _NotificationItem(
        title: 'New ecology mission posted',
        subtitle: 'Fresh clean-up work is now available for volunteers.',
        icon: Icons.eco_outlined,
      ),
      const _NotificationItem(
        title: 'Your application was received',
        subtitle: 'Task creators can see your response in the applications tab.',
        icon: Icons.check_circle_outline_rounded,
      ),
      const _NotificationItem(
        title: 'Group chat reminder',
        subtitle: 'Keep updates short, clear, and useful for everyone.',
        icon: Icons.forum_outlined,
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Notification Center')),
      body: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: items.length,
        separatorBuilder: (BuildContext context, int index) =>
            const SizedBox(height: 12),
        itemBuilder: (BuildContext context, int index) {
          final _NotificationItem item = items[index];
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: <Widget>[
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Icon(item.icon, color: AppColors.primary),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          item.title,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.subtitle,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _NotificationItem {
  const _NotificationItem({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;
}
