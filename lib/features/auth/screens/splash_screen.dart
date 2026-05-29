import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:jihc_volunteers_app/core/constants/app_constants.dart';
import 'package:jihc_volunteers_app/core/theme/app_theme.dart';
import 'package:jihc_volunteers_app/core/widgets/brand_widgets.dart';
import 'package:jihc_volunteers_app/services/firestore_service.dart';
import 'package:jihc_volunteers_app/services/auth_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.firebaseConfigured});

  final bool firebaseConfigured;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    _scaleAnimation = Tween<double>(
      begin: 0.88,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _controller.forward();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future<void>.delayed(const Duration(milliseconds: 1800));
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final bool onboardingDone =
        prefs.getBool(AppConstants.onboardingPreferenceKey) ?? false;

    if (!mounted) {
      return;
    }

    if (!onboardingDone) {
      Navigator.of(context).pushReplacementNamed(AppConstants.onboardingRoute);
      return;
    }

    if (!widget.firebaseConfigured || _authService.currentUser == null) {
      Navigator.of(context).pushReplacementNamed(AppConstants.loginRoute);
      return;
    }

    final String uid = _authService.currentUser!.uid;
    final String? role = await _firestoreService.getUserRole(uid);
    if (!mounted) {
      return;
    }

    Navigator.of(context).pushReplacementNamed(
      role == null || role.isEmpty
          ? AppConstants.roleSelectionRoute
          : AppConstants.homeRoute,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final double logoSize =
                (constraints.maxWidth * 0.42).clamp(150.0, 190.0).toDouble();

            return Center(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      JihcLogoBadge(size: logoSize),
                      const SizedBox(height: 28),
                      const SizedBox(
                        width: 26,
                        height: 26,
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                          strokeWidth: 2.8,
                        ),
                      ),
                    ],
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
