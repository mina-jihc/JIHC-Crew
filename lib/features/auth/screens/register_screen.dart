import 'package:flutter/material.dart';

import 'package:jihc_volunteers_app/core/constants/app_constants.dart';
import 'package:jihc_volunteers_app/core/shared_widgets/app_widgets.dart';
import 'package:jihc_volunteers_app/core/theme/app_theme.dart';
import 'package:jihc_volunteers_app/core/widgets/brand_widgets.dart';
import 'package:jihc_volunteers_app/services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  final AuthService _authService = AuthService();

  bool _passwordObscured = true;
  bool _confirmObscured = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final String email = _emailController.text.trim();
    if (!_isOfficialEmail(email)) {
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
      await _authService.registerWithEmail(
        email,
        _passwordController.text,
        _nameController.text,
      );
      if (!mounted) {
        return;
      }
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppConstants.roleSelectionRoute,
        (Route<dynamic> route) => false,
      );
    } catch (error) {
      if (_isAccessDenied(error)) {
        if (!mounted) {
          return;
        }
        showTealErrorSnackBar(
          context,
          'Access denied. Use your official JIHC email.',
        );
        return;
      }
      setState(() => _error = _mapError(error));
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  bool _isOfficialEmail(String email) {
    return email.trim().toLowerCase().endsWith(AppConstants.officialEmailDomain);
  }

  bool _isAccessDenied(Object error) {
    return error.toString().toLowerCase().contains('access denied');
  }

  String _mapError(Object error) {
    final String message = error.toString().toLowerCase();
    if (message.contains('email-already-in-use')) {
      return 'That email address is already in use.';
    }
    if (message.contains('weak-password')) {
      return 'Choose a stronger password.';
    }
    if (message.contains('invalid-email')) {
      return 'Enter a valid email address.';
    }
    if (message.contains('firebase is not configured')) {
      return 'Firebase is not configured yet. Add your project keys to continue.';
    }
    return 'Registration failed. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Create account')),
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
                        const Center(
                          child: VolunteerLogoMark(
                            size: 80,
                            showWordmark: false,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Join ${AppConstants.appName}',
                          style: Theme.of(context).textTheme.displaySmall,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Create your student volunteer profile and start discovering new work around campus.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 28),
                        if (_error != null) ...<Widget>[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: AppColors.error.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(
                                AppTheme.radius,
                              ),
                            ),
                            child: Text(
                              _error!,
                              style: Theme.of(
                                context,
                              ).textTheme.bodyMedium?.copyWith(
                                color: AppColors.error,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                        Form(
                          key: _formKey,
                          child: Column(
                            children: <Widget>[
                              TextFormField(
                                controller: _nameController,
                                textCapitalization: TextCapitalization.words,
                                decoration: const InputDecoration(
                                  labelText: 'Full name',
                                  prefixIcon: Icon(
                                    Icons.person_outline_rounded,
                                  ),
                                ),
                                validator: (String? value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Full name is required.';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                decoration: const InputDecoration(
                                  labelText: 'Email',
                                  prefixIcon: Icon(Icons.mail_outline_rounded),
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
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _passwordObscured,
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                  prefixIcon: const Icon(
                                    Icons.lock_outline_rounded,
                                  ),
                                  suffixIcon: IconButton(
                                    onPressed: () {
                                      setState(
                                        () =>
                                            _passwordObscured =
                                                !_passwordObscured,
                                      );
                                    },
                                    icon: Icon(
                                      _passwordObscured
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                    ),
                                  ),
                                ),
                                validator: (String? value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Password is required.';
                                  }
                                  if (value.length < 6) {
                                    return 'Password must be at least 6 characters.';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _confirmController,
                                obscureText: _confirmObscured,
                                decoration: InputDecoration(
                                  labelText: 'Confirm password',
                                  prefixIcon: const Icon(
                                    Icons.lock_outline_rounded,
                                  ),
                                  suffixIcon: IconButton(
                                    onPressed: () {
                                      setState(
                                        () =>
                                            _confirmObscured =
                                                !_confirmObscured,
                                      );
                                    },
                                    icon: Icon(
                                      _confirmObscured
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                    ),
                                  ),
                                ),
                                validator: (String? value) {
                                  if (value != _passwordController.text) {
                                    return 'Passwords do not match.';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 24),
                              TealButton(
                                label: 'Create account',
                                onPressed: _register,
                                isLoading: _loading,
                              ),
                            ],
                          ),
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
