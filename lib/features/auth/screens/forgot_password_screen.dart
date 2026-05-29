import 'package:flutter/material.dart';

import 'package:jihc_volunteers_app/core/constants/app_constants.dart';
import 'package:jihc_volunteers_app/core/shared_widgets/app_widgets.dart';
import 'package:jihc_volunteers_app/core/theme/app_theme.dart';
import 'package:jihc_volunteers_app/core/widgets/brand_widgets.dart';
import 'package:jihc_volunteers_app/services/auth_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final AuthService _authService = AuthService();

  bool _loading = false;
  bool _sent = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendReset() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final String email = _emailController.text.trim();
    if (!email.trim().toLowerCase().endsWith(AppConstants.officialEmailDomain)) {
      showTealErrorSnackBar(
        context,
        'Access denied. Use your official JIHC email.',
      );
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await _authService.resetPassword(email);
      if (mounted) {
        setState(() => _sent = true);
      }
    } catch (error) {
      if (error.toString().toLowerCase().contains('access denied')) {
        if (!mounted) {
          return;
        }
        showTealErrorSnackBar(
          context,
          'Access denied. Use your official JIHC email.',
        );
        return;
      }
      setState(() {
        _error =
            error.toString().toLowerCase().contains(
              'firebase is not configured',
            )
            ? 'Firebase is not configured yet. Add your project keys to continue.'
            : 'Unable to send a reset email right now.';
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Reset password')),
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
                    child: _sent
                        ? const EmptyStateWidget(
                            icon: Icons.mark_email_read_outlined,
                            title: 'Reset link sent',
                            subtitle:
                                'Check your email for the link to create a new password.',
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              const Center(
                                child: VolunteerLogoMark(
                                  size: 72,
                                  showWordmark: false,
                                ),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                'We will email your reset link',
                                style: Theme.of(context).textTheme.displaySmall,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Enter the address connected to your JIHC Crew account.',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              const SizedBox(height: 24),
                              if (_error != null) ...<Widget>[
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(18),
                                  decoration: BoxDecoration(
                                    color: AppColors.error.withValues(
                                      alpha: 0.08,
                                    ),
                                    borderRadius: BorderRadius.circular(
                                      AppTheme.radius,
                                    ),
                                  ),
                                  child: Text(
                                    _error!,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(color: AppColors.error),
                                  ),
                                ),
                                const SizedBox(height: 18),
                              ],
                              Form(
                                key: _formKey,
                                child: TextFormField(
                                  controller: _emailController,
                                  decoration: const InputDecoration(
                                    labelText: 'Email',
                                    prefixIcon: Icon(
                                      Icons.mail_outline_rounded,
                                    ),
                                  ),
                                  validator: (String? value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Email is required.';
                                    }
                                    if (!value.contains('@')) {
                                      return 'Enter a valid email.';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(height: 24),
                              TealButton(
                                label: 'Send reset link',
                                onPressed: _sendReset,
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
