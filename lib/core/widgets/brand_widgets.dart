import 'package:flutter/material.dart';

import 'package:jihc_volunteers_app/core/constants/app_constants.dart';
import 'package:jihc_volunteers_app/core/theme/app_theme.dart';

class JihcLogoBadge extends StatelessWidget {
  const JihcLogoBadge({super.key, this.size = 120});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(size * 0.25),
        border: Border.all(color: AppColors.border),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Image.asset(
        'assets/brand/jihc_logo.jpg',
        fit: BoxFit.contain,
      ),
    );
  }
}

class VolunteerLogoMark extends StatelessWidget {
  const VolunteerLogoMark({super.key, this.size = 88, this.showWordmark = true});

  final double size;
  final bool showWordmark;

  @override
  Widget build(BuildContext context) {
    final double ringSize = size;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: ringSize,
          height: ringSize,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: <Color>[AppColors.primary, AppColors.primaryDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.16),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              Container(
                width: ringSize * 0.74,
                height: ringSize * 0.74,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.92),
                    width: 2,
                  ),
                ),
              ),
              Container(
                width: ringSize * 0.5,
                height: ringSize * 0.5,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary, width: 3.5),
                ),
              ),
              Icon(
                Icons.volunteer_activism_rounded,
                color: AppColors.primaryDark,
                size: ringSize * 0.32,
              ),
              Positioned(
                top: ringSize * 0.13,
                right: ringSize * 0.20,
                child: _OrbitDot(size: ringSize * 0.09),
              ),
              Positioned(
                left: ringSize * 0.18,
                top: ringSize * 0.19,
                child: _OrbitDot(size: ringSize * 0.06),
              ),
              Positioned(
                right: ringSize * 0.17,
                bottom: ringSize * 0.17,
                child: _OrbitDot(size: ringSize * 0.07),
              ),
            ],
          ),
        ),
        if (showWordmark) ...<Widget>[
          const SizedBox(height: 12),
          Text(
            AppConstants.appName,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Volunteer together',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}

class VolunteerIllustration extends StatelessWidget {
  const VolunteerIllustration({super.key, required this.variant});

  final int variant;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final List<_AvatarSpec> avatars = _avatarsForVariant(variant);
        final double scale =
            (constraints.maxWidth / 520).clamp(0.74, 1.0).toDouble();
        final double leftCardWidth = 120 * scale;
        final double middleCardWidth = 132 * scale;
        final double rightCardWidth = 126 * scale;
        final double leftCardHeight = 130 * scale;
        final double middleCardHeight = 150 * scale;
        final double rightCardHeight = 138 * scale;
        final double actionSize = 48 * scale;

        return Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 520),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(36),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.06),
                blurRadius: 24,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: AspectRatio(
            aspectRatio: 1.15,
            child: Stack(
              children: <Widget>[
                Positioned.fill(
                  child: Align(
                    alignment: Alignment.center,
                    child: LayoutBuilder(
                      builder:
                          (
                            BuildContext context,
                            BoxConstraints blobConstraints,
                          ) {
                        final double blobWidth =
                            blobConstraints.maxWidth * 0.58;
                        final double blobHeight =
                            blobConstraints.maxWidth * 0.4;
                        return Container(
                          width: blobWidth,
                          height: blobHeight,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF4EEDD),
                            borderRadius: BorderRadius.circular(96),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                Positioned(
                  left: 18 * scale,
                  top: 28 * scale,
                  child: _NetworkLine(
                    color: AppColors.primary.withValues(alpha: 0.34),
                    size: Size(180 * scale, 120 * scale),
                  ),
                ),
                Positioned(
                  right: 16 * scale,
                  top: 40 * scale,
                  child: _NetworkLine(
                    color: AppColors.primary.withValues(alpha: 0.34),
                    flip: true,
                    size: Size(180 * scale, 120 * scale),
                  ),
                ),
                Positioned(
                  left: 26 * scale,
                  bottom: 26 * scale,
                  child: _PersonCard(
                    icon: avatars[0].icon,
                    color: avatars[0].color,
                    label: avatars[0].label,
                    width: leftCardWidth,
                    height: leftCardHeight,
                  ),
                ),
                Positioned(
                  top: 20 * scale,
                  left: 108 * scale,
                  right: 108 * scale,
                  child: _PersonCard(
                    icon: avatars[1].icon,
                    color: avatars[1].color,
                    label: avatars[1].label,
                    width: middleCardWidth,
                    height: middleCardHeight,
                  ),
                ),
                Positioned(
                  right: 18 * scale,
                  bottom: 36 * scale,
                  child: _PersonCard(
                    icon: avatars[2].icon,
                    color: avatars[2].color,
                    label: avatars[2].label,
                    width: rightCardWidth,
                    height: rightCardHeight,
                  ),
                ),
                Positioned(
                  left: 70 * scale,
                  right: 70 * scale,
                  bottom: 12 * scale,
                  child: Container(
                    padding: EdgeInsets.all(14 * scale),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24 * scale),
                      border: Border.all(color: AppColors.border),
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: AppColors.textPrimary.withValues(alpha: 0.05),
                          blurRadius: 14,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      children: <Widget>[
                        Container(
                          width: actionSize,
                          height: actionSize,
                          decoration: BoxDecoration(
                            color: AppColors.primarySoft,
                            borderRadius: BorderRadius.circular(16 * scale),
                          ),
                          child: const Icon(
                            Icons.laptop_chromebook_rounded,
                            color: AppColors.primary,
                          ),
                        ),
                        SizedBox(width: 12 * scale),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Text(
                                'JIHC Crew',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              SizedBox(height: 2 * scale),
                              Text(
                                'Volunteer together',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<_AvatarSpec> _avatarsForVariant(int value) {
    switch (value) {
      case 1:
        return const <_AvatarSpec>[
          _AvatarSpec(Icons.eco_outlined, AppColors.primary, 'Eco'),
          _AvatarSpec(Icons.groups_rounded, AppColors.primaryDark, 'Team'),
          _AvatarSpec(Icons.favorite_outline_rounded, Color(0xFFE76F51), 'Care'),
        ];
      case 2:
        return const <_AvatarSpec>[
          _AvatarSpec(Icons.sports_basketball_rounded, AppColors.primary, 'Sport'),
          _AvatarSpec(Icons.volunteer_activism_rounded, AppColors.primaryDark, 'Help'),
          _AvatarSpec(Icons.celebration_rounded, Color(0xFF7C6EE6), 'Join'),
        ];
      default:
        return const <_AvatarSpec>[
          _AvatarSpec(Icons.draw_rounded, AppColors.primary, 'Create'),
          _AvatarSpec(Icons.camera_alt_rounded, AppColors.primaryDark, 'Capture'),
          _AvatarSpec(Icons.handyman_outlined, Color(0xFF7C6EE6), 'Build'),
        ];
    }
  }
}

class _AvatarSpec {
  const _AvatarSpec(this.icon, this.color, this.label);

  final IconData icon;
  final Color color;
  final String label;
}

class _PersonCard extends StatelessWidget {
  const _PersonCard({
    required this.icon,
    required this.color,
    required this.label,
    required this.width,
    required this.height,
  });

  final IconData icon;
  final Color color;
  final String label;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: color.withValues(alpha: 0.12)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: color.withValues(alpha: 0.10),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          CircleAvatar(
            radius: 26,
            backgroundColor: color.withValues(alpha: 0.12),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _NetworkLine extends StatelessWidget {
  const _NetworkLine({
    required this.color,
    this.flip = false,
    this.size = const Size(180, 120),
  });

  final Color color;
  final bool flip;
  final Size size;

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scaleX: flip ? -1 : 1,
      child: CustomPaint(
        size: size,
        painter: _NetworkLinePainter(color: color),
      ),
    );
  }
}

class _NetworkLinePainter extends CustomPainter {
  const _NetworkLinePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final Path path = Path()
      ..moveTo(0, size.height * 0.55)
      ..quadraticBezierTo(
        size.width * 0.40,
        size.height * 0.15,
        size.width * 0.75,
        size.height * 0.50,
      )
      ..quadraticBezierTo(
        size.width * 0.86,
        size.height * 0.62,
        size.width,
        size.height * 0.42,
      );

    canvas.drawPath(path, paint);

    final Paint dotPaint = Paint()..color = color;
    canvas.drawCircle(Offset(size.width * 0.40, size.height * 0.28), 6, dotPaint);
    canvas.drawCircle(Offset(size.width * 0.75, size.height * 0.50), 6, dotPaint);
    canvas.drawCircle(Offset(size.width, size.height * 0.42), 8, dotPaint);
  }

  @override
  bool shouldRepaint(covariant _NetworkLinePainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

class _OrbitDot extends StatelessWidget {
  const _OrbitDot({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: AppColors.primary,
        shape: BoxShape.circle,
      ),
    );
  }
}
