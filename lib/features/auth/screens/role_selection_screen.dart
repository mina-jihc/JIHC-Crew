import 'package:flutter/material.dart';

import 'package:jihc_volunteers_app/core/constants/app_constants.dart';
import 'package:jihc_volunteers_app/core/shared_widgets/app_widgets.dart';
import 'package:jihc_volunteers_app/core/theme/app_theme.dart';
import 'package:jihc_volunteers_app/core/widgets/brand_widgets.dart';
import 'package:jihc_volunteers_app/services/auth_service.dart';
import 'package:jihc_volunteers_app/services/firestore_service.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();

  String? _selectedRole;
  bool _loading = false;

  Future<void> _continue() async {
    final String? uid = _authService.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      showTealErrorSnackBar(context, 'Please sign in again to continue.');
      return;
    }
    if (_selectedRole == null) {
      showTealErrorSnackBar(context, 'Please choose a role to continue.');
      return;
    }

    setState(() => _loading = true);

    try {
      await _firestoreService.setUserRole(uid, _selectedRole!);
      if (!mounted) {
        return;
      }
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppConstants.homeRoute,
        (Route<dynamic> route) => false,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      showTealErrorSnackBar(context, error.toString());
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool volunteerSelected =
        _selectedRole == AppConstants.volunteerRole;
    final bool adminSelected =
        _selectedRole == AppConstants.administratorRole;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 48,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const SizedBox(height: 8),
                        const Center(
                          child: VolunteerLogoMark(size: 92),
                        ),
                        const SizedBox(height: 28),
                        Text(
                          'Choose your role',
                          style: Theme.of(context).textTheme.displaySmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'This helps us tailor the experience for volunteers and administrators.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 28),
                        _RoleTile(
                          title: 'Volunteer',
                          subtitle:
                              'Apply to tasks, join chats, and track your impact.',
                          icon: Icons.volunteer_activism_rounded,
                          selected: volunteerSelected,
                          onTap: () {
                            setState(() => _selectedRole = AppConstants.volunteerRole);
                          },
                        ),
                        const SizedBox(height: 14),
                        _RoleTile(
                          title: 'Administrator',
                          subtitle:
                              'Create tasks, manage content, and guide the crew.',
                          icon: Icons.admin_panel_settings_rounded,
                          selected: adminSelected,
                          onTap: () {
                            setState(
                              () => _selectedRole =
                                  AppConstants.administratorRole,
                            );
                          },
                        ),
                        const SizedBox(height: 24),
                        TealButton(
                          label: 'Continue',
                          onPressed: _continue,
                          isLoading: _loading,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _RoleTile extends StatelessWidget {
  const _RoleTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppTheme.radius),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
              width: selected ? 1.8 : 1,
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: selected
                    ? AppColors.primary.withValues(alpha: 0.12)
                    : AppColors.textPrimary.withValues(alpha: 0.04),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.primarySoft
                      : AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(icon, color: AppColors.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              Icon(
                selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                color: selected ? AppColors.primary : AppColors.textHint,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
