import 'package:flutter/material.dart';

import 'package:jihc_volunteers_app/core/shared_widgets/app_widgets.dart';
import 'package:jihc_volunteers_app/core/theme/app_theme.dart';
import 'package:jihc_volunteers_app/features/profile/screens/about_screen.dart';
import 'package:jihc_volunteers_app/features/profile/screens/notifications_screen.dart';
import 'package:jihc_volunteers_app/features/gamification/screens/progress_screen.dart';
import 'package:jihc_volunteers_app/services/auth_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthService authService = AuthService();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: <Widget>[
          SoftCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'App preferences',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),
                const Text(
                  'A calm, minimal settings surface for quick access.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _ActionTile(
            icon: Icons.notifications_none_rounded,
            title: 'Notification Center',
            subtitle: 'Review updates and reminders.',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const NotificationsScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          _ActionTile(
            icon: Icons.emoji_events_outlined,
            title: 'Progress',
            subtitle: 'Track ranks and unlocked badges.',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const ProgressScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          _ActionTile(
            icon: Icons.info_outline_rounded,
            title: 'About',
            subtitle: 'Project details and author information.',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const AboutScreen()),
              );
            },
          ),
          const SizedBox(height: 12),
          _ActionTile(
            icon: Icons.logout_rounded,
            title: 'Sign out',
            subtitle: 'Return to onboarding.',
            destructive: true,
            onTap: () async {
              await authService.signOut(context);
            },
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radius),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: <Widget>[
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: destructive
                      ? AppColors.error.withValues(alpha: 0.10)
                      : AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  icon,
                  color: destructive ? AppColors.error : AppColors.primary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(title, style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}
