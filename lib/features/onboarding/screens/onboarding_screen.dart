import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:jihc_volunteers_app/core/constants/app_constants.dart';
import 'package:jihc_volunteers_app/core/shared_widgets/app_widgets.dart';
import 'package:jihc_volunteers_app/core/theme/app_theme.dart';
import 'package:jihc_volunteers_app/core/widgets/brand_widgets.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _pageIndex = 0;

  static const List<_SlideData> _slides = <_SlideData>[
    _SlideData(
      title: 'Join the Community',
      subtitle:
          'Meet volunteers, discover campus initiatives, and start in a calm, friendly space.',
      variant: 0,
    ),
    _SlideData(
      title: 'Post Your Impact',
      subtitle:
          'Share volunteer moments with clean photo cards and keep the feed focused on action.',
      variant: 1,
    ),
    _SlideData(
      title: 'Level Up Your Rank',
      subtitle:
          'Earn badges, build momentum, and grow from novice to legend through every mission.',
      variant: 2,
    ),
  ];

  Future<void> _finish() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.onboardingPreferenceKey, true);
    if (!mounted) {
      return;
    }
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppConstants.loginRoute,
      (Route<dynamic> route) => false,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isLastPage = _pageIndex == _slides.length - 1;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            return Stack(
              children: <Widget>[
                Positioned(
                  top: -120,
                  left: -120,
                  child: _SoftBlob(color: AppColors.primarySoft, size: 240),
                ),
                Positioned(
                  right: -100,
                  bottom: 80,
                  child: _SoftBlob(color: const Color(0xFFF4EEDD), size: 200),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                  child: Column(
                    children: <Widget>[
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _finish,
                          child: const Text('Skip'),
                        ),
                      ),
                      Expanded(
                        child: PageView.builder(
                          controller: _pageController,
                          itemCount: _slides.length,
                          onPageChanged: (int index) {
                            setState(() => _pageIndex = index);
                          },
                          itemBuilder: (BuildContext context, int index) {
                            final _SlideData slide = _slides[index];
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                const Spacer(),
                                Center(
                                  child: VolunteerIllustration(
                                    variant: slide.variant,
                                  ),
                                ),
                                const SizedBox(height: 28),
                                Text(
                                  slide.title,
                                  style: Theme.of(context)
                                      .textTheme
                                      .displaySmall,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  slide.subtitle,
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                                const Spacer(),
                              ],
                            );
                          },
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List<Widget>.generate(
                          _slides.length,
                          (int index) => AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            margin: const EdgeInsets.only(right: 8),
                            width: _pageIndex == index ? 28 : 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: _pageIndex == index
                                  ? AppColors.primary
                                  : AppColors.border,
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      TealButton(
                        label: isLastPage ? 'Get started' : 'Continue',
                        onPressed: () async {
                          if (isLastPage) {
                            await _finish();
                            return;
                          }
                          await _pageController.nextPage(
                            duration: const Duration(milliseconds: 280),
                            curve: Curves.easeOut,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SlideData {
  const _SlideData({
    required this.title,
    required this.subtitle,
    required this.variant,
  });

  final String title;
  final String subtitle;
  final int variant;
}

class _SoftBlob extends StatelessWidget {
  const _SoftBlob({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.8),
        shape: BoxShape.circle,
      ),
    );
  }
}
