import 'package:flutter/material.dart';

import 'package:jihc_volunteers_app/core/constants/app_constants.dart';
import 'package:jihc_volunteers_app/core/shared_widgets/app_widgets.dart';
import 'package:jihc_volunteers_app/core/theme/app_theme.dart';
import 'package:jihc_volunteers_app/core/widgets/brand_widgets.dart';
import 'package:jihc_volunteers_app/services/auth_service.dart';
import 'package:jihc_volunteers_app/services/firestore_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();

  bool _obscurePassword = true;
  bool _emailLoading = false;
  bool _googleLoading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
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
      _emailLoading = true;
      _error = null;
    });

    try {
      await _authService.signInWithEmail(
        email,
        _passwordController.text,
      );
      if (!mounted) {
        return;
      }
      await _routeAfterAuth();
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
        setState(() => _emailLoading = false);
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _googleLoading = true;
      _error = null;
    });

    try {
      final result = await _authService.signInWithGoogle();
      if (!mounted || result == null) {
        return;
      }
      await _routeAfterAuth();
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
        setState(() => _googleLoading = false);
      }
    }
  }

  Future<void> _routeAfterAuth() async {
    final String uid = _authService.currentUser?.uid ?? '';
    final String? role = await _firestoreService.getUserRole(uid);
    if (!mounted) {
      return;
    }

    Navigator.of(context).pushNamedAndRemoveUntil(
      role == null || role.isEmpty
          ? AppConstants.roleSelectionRoute
          : AppConstants.homeRoute,
      (Route<dynamic> route) => false,
    );
  }

  bool _isOfficialEmail(String email) {
    return email.trim().toLowerCase().endsWith(AppConstants.officialEmailDomain);
  }

  bool _isAccessDenied(Object error) {
    return error.toString().toLowerCase().contains('access denied');
  }

  String _mapError(Object error) {
    final String message = error.toString().toLowerCase();
    if (message.contains('user-not-found')) {
      return 'No account was found for that email address.';
    }
    if (message.contains('wrong-password') ||
        message.contains('invalid-credential')) {
      return 'The email or password is incorrect.';
    }
    if (message.contains('invalid-email')) {
      return 'Enter a valid email address.';
    }
    if (message.contains('firebase is not configured')) {
      return 'Firebase is not configured yet. Add your project keys to continue.';
    }
    return 'Sign in failed. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
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
                        const SizedBox(height: 12),
                        const Center(child: JihcLogoBadge(size: 122)),
                        const SizedBox(height: 28),
                        Text(
                          'Welcome back to ${AppConstants.appName}',
                          style: Theme.of(context).textTheme.displaySmall,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Sign in to explore volunteer opportunities, crews, and activity across campus.',
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
                              border: Border.all(
                                color: AppColors.error.withValues(
                                  alpha: 0.18,
                                ),
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
                                obscureText: _obscurePassword,
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                  prefixIcon: const Icon(
                                    Icons.lock_outline_rounded,
                                  ),
                                  suffixIcon: IconButton(
                                    onPressed: () {
                                      setState(
                                        () => _obscurePassword = !_obscurePassword,
                                      );
                                    },
                                    icon: Icon(
                                      _obscurePassword
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
                              const SizedBox(height: 10),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pushNamed(
                                      AppConstants.forgotPasswordRoute,
                                    );
                                  },
                                  child: const Text('Forgot password?'),
                                ),
                              ),
                              const SizedBox(height: 8),
                              TealButton(
                                label: 'Sign in',
                                onPressed: _signIn,
                                isLoading: _emailLoading,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: <Widget>[
                            const Expanded(child: Divider()),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              child: Text(
                                'or',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                            const Expanded(child: Divider()),
                          ],
                        ),
                        const SizedBox(height: 24),
                        OutlinedButton(
                          onPressed: _googleLoading ? null : _signInWithGoogle,
                          child: _googleLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.2,
                                  ),
                                )
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    Icon(Icons.g_mobiledata_rounded, size: 28),
                                    SizedBox(width: 8),
                                    Text('Continue with Google'),
                                  ],
                                ),
                        ),
                        const SizedBox(height: 28),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Text(
                              'New to JIHC Crew?',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pushNamed(
                                  AppConstants.registerRoute,
                                );
                              },
                              child: const Text('Create account'),
                            ),
                          ],
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
