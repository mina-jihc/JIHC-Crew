import 'package:flutter/material.dart';

import 'package:jihc_volunteers_app/core/constants/app_constants.dart';
import 'package:jihc_volunteers_app/core/shared_widgets/app_widgets.dart';
import 'package:jihc_volunteers_app/core/theme/app_theme.dart';
import 'package:jihc_volunteers_app/features/chat/screens/chat_list_screen.dart';
import 'package:jihc_volunteers_app/features/profile/screens/about_screen.dart';
import 'package:jihc_volunteers_app/features/profile/screens/edit_profile_screen.dart';
import 'package:jihc_volunteers_app/features/profile/screens/notifications_screen.dart';
import 'package:jihc_volunteers_app/features/gamification/screens/progress_screen.dart';
import 'package:jihc_volunteers_app/features/settings/screens/settings_screen.dart';
import 'package:jihc_volunteers_app/models/user_model.dart';
import 'package:jihc_volunteers_app/services/auth_service.dart';
import 'package:jihc_volunteers_app/services/firestore_service.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthService authService = AuthService();
    final FirestoreService firestoreService = FirestoreService();
    final String uid = authService.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Profile'),
        actions: <Widget>[
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const NotificationsScreen(),
                ),
              );
            },
            icon: const Icon(Icons.notifications_none_rounded),
          ),
        ],
      ),
      body: StreamBuilder<UserModel?>(
        stream: firestoreService.getUserStream(uid),
        builder: (BuildContext context, AsyncSnapshot<UserModel?> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AppLoadingWidget();
          }

          final UserModel? user =
              snapshot.data ??
              ((authService.currentUser?.email != null)
                  ? UserModel.fromAuth(
                      uid: uid,
                      displayName:
                          authService.currentUser?.displayName ??
                          'JIHC Student',
                      email: authService.currentUser?.email ?? '',
                      photoUrl: authService.currentUser?.photoURL,
                    )
                  : null);

          if (user == null) {
            return const AppEmptyWidget(
              icon: Icons.person_outline_rounded,
              title: 'No active student profile',
              subtitle:
                  'Sign in to view your profile, task history, and crews.',
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
            child: Column(
              children: <Widget>[
                SoftCard(
                  child: Column(
                    children: <Widget>[
                      UserAvatar(
                        photoUrl: user.photoUrl,
                        displayName: user.displayName,
                        radius: 42,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        user.displayName,
                        style: Theme.of(context).textTheme.headlineMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        user.email,
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      CategoryBadge(
                        label:
                            (user.role ?? AppConstants.volunteerRole)
                                .toUpperCase(),
                      ),
                      if ((user.bio ?? '').trim().isNotEmpty) ...<Widget>[
                        const SizedBox(height: 10),
                        Text(
                          user.bio!,
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SoftCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Identity Block',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 14),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: AppColors.primarySoft,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              AppConstants.authorName,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'ID: ${AppConstants.studentId}',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: AppColors.primary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: _StatCard(
                        label: 'Tasks completed',
                        value: user.tasksCompleted.toString(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        label: 'Crews joined',
                        value: user.crewsJoined.toString(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SoftCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: <Widget>[
                      _ProfileTile(
                        icon: Icons.edit_outlined,
                        label: 'Edit profile',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => EditProfileScreen(user: user),
                            ),
                          );
                        },
                      ),
                      const Divider(height: 1),
                      _ProfileTile(
                        icon: Icons.chat_bubble_outline_rounded,
                        label: 'Chat List',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const ChatListScreen(),
                            ),
                          );
                        },
                      ),
                      const Divider(height: 1),
                      _ProfileTile(
                        icon: Icons.emoji_events_outlined,
                        label: 'Progress',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const ProgressScreen(),
                            ),
                          );
                        },
                      ),
                      const Divider(height: 1),
                      _ProfileTile(
                        icon: Icons.settings_outlined,
                        label: 'Settings',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const SettingsScreen(),
                            ),
                          );
                        },
                      ),
                      const Divider(height: 1),
                      _ProfileTile(
                        icon: Icons.info_outline_rounded,
                        label: 'About the project',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const AboutScreen(),
                            ),
                          );
                        },
                      ),
                      const Divider(height: 1),
                      _ProfileTile(
                        icon: Icons.logout_rounded,
                        label: 'Log out',
                        onTap: () async {
                          await authService.signOut(context);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            value,
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              fontSize: 28,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.primarySoft,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(icon, color: AppColors.primary),
      ),
      title: Text(label),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}
