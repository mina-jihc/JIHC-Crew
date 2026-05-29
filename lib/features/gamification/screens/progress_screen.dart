import 'package:flutter/material.dart';

import 'package:jihc_volunteers_app/core/shared_widgets/app_widgets.dart';
import 'package:jihc_volunteers_app/core/theme/app_theme.dart';
import 'package:jihc_volunteers_app/models/user_model.dart';
import 'package:jihc_volunteers_app/services/auth_service.dart';
import 'package:jihc_volunteers_app/services/firestore_service.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final FirestoreService firestoreService = FirestoreService();
    final AuthService authService = AuthService();
    final String uid = authService.currentUser?.uid ?? '';

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double horizontalPadding = constraints.maxWidth < 420 ? 16 : 20;

        return SafeArea(
          child: StreamBuilder<UserModel?>(
            stream: firestoreService.getUserStream(uid),
            builder: (BuildContext context, AsyncSnapshot<UserModel?> snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const AppLoadingWidget(message: 'Loading progress...');
              }

              if (snapshot.hasError) {
                return AppErrorWidget(message: snapshot.error.toString());
              }

              final UserModel? user = snapshot.data;
              if (user == null) {
                return const AppEmptyWidget(
                  icon: Icons.emoji_events_outlined,
                  title: 'No progress yet',
                  subtitle:
                      'Sign in to track ranks, badges, and volunteer momentum.',
                );
              }

              final _RankStep currentRank = _rankFor(user.tasksCompleted);
              final _RankStep nextRank = _nextRankFor(user.tasksCompleted);
              final double progressValue = _rankProgress(user.tasksCompleted);
              final double badgeItemExtent = constraints.maxWidth < 420
                  ? 148
                  : 160;

              return CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: <Widget>[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        12,
                        horizontalPadding,
                        0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Progress',
                            style: Theme.of(context).textTheme.displaySmall,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Track your rank, unlock badges, and keep building momentum.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 20),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(
                                AppTheme.radius,
                              ),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              children: <Widget>[
                                Expanded(
                                  flex: 4,
                                  child: AspectRatio(
                                    aspectRatio: 1,
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: <Widget>[
                                        SizedBox.expand(
                                          child: CircularProgressIndicator(
                                            value: progressValue,
                                            strokeWidth: 12,
                                            backgroundColor:
                                                AppColors.surfaceMuted,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                        Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: <Widget>[
                                            Text(
                                              currentRank.title,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleLarge,
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              '${user.tasksCompleted} tasks',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .headlineSmall
                                                  ?.copyWith(
                                                    color: AppColors.primary,
                                                  ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              nextRank.title == currentRank.title
                                                  ? 'Top rank reached'
                                                  : 'Next: ${nextRank.title}',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall,
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  flex: 5,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text(
                                        'Rank path',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleLarge,
                                      ),
                                      const SizedBox(height: 10),
                                      _RankChipRow(
                                        steps: _rankSteps,
                                        current: currentRank.title,
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'You are ${_progressDescription(user.tasksCompleted)} of the way to ${nextRank.title.toLowerCase()}.',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        24,
                        horizontalPadding,
                        12,
                      ),
                      child: Row(
                        children: <Widget>[
                          Text(
                            'Badges',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const Spacer(),
                          Text(
                            '${_unlockedBadges(user.tasksCompleted).length}/${_badges.length} unlocked',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      0,
                      horizontalPadding,
                      120,
                    ),
                    sliver: SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        mainAxisExtent: badgeItemExtent,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (BuildContext context, int index) {
                          final _BadgeSpec badge = _badges[index];
                          final bool unlocked =
                              user.tasksCompleted >= badge.threshold;
                          return _BadgeTile(
                            badge: badge,
                            unlocked: unlocked,
                          );
                        },
                        childCount: _badges.length,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  _RankStep _rankFor(int tasksCompleted) {
    _RankStep current = _rankSteps.first;
    for (final _RankStep step in _rankSteps) {
      if (tasksCompleted >= step.threshold) {
        current = step;
      }
    }
    return current;
  }

  _RankStep _nextRankFor(int tasksCompleted) {
    for (final _RankStep step in _rankSteps) {
      if (tasksCompleted < step.threshold) {
        return step;
      }
    }
    return _rankSteps.last;
  }

  double _rankProgress(int tasksCompleted) {
    if (tasksCompleted >= _rankSteps.last.threshold) {
      return 1;
    }

    _RankStep current = _rankSteps.first;
    _RankStep next = _rankSteps.last;
    for (int index = 0; index < _rankSteps.length; index++) {
      final _RankStep step = _rankSteps[index];
      if (tasksCompleted >= step.threshold) {
        current = step;
        if (index + 1 < _rankSteps.length) {
          next = _rankSteps[index + 1];
        }
      }
    }

    final int progressRange = next.threshold - current.threshold;
    if (progressRange <= 0) {
      return 1;
    }
    return ((tasksCompleted - current.threshold) / progressRange).clamp(0, 1);
  }

  String _progressDescription(int tasksCompleted) {
    if (tasksCompleted >= _rankSteps.last.threshold) {
      return 'fully';
    }

    _RankStep current = _rankSteps.first;
    _RankStep next = _rankSteps[1];
    for (int index = 0; index < _rankSteps.length; index++) {
      final _RankStep step = _rankSteps[index];
      if (tasksCompleted >= step.threshold) {
        current = step;
        if (index + 1 < _rankSteps.length) {
          next = _rankSteps[index + 1];
        }
      }
    }

    final int progressRange = next.threshold - current.threshold;
    final int progress = tasksCompleted - current.threshold;
    final int percent = progressRange <= 0
        ? 100
        : ((progress / progressRange) * 100).round();
    return '$percent%';
  }

  List<_BadgeSpec> _unlockedBadges(int tasksCompleted) {
    return _badges
        .where((_BadgeSpec badge) => tasksCompleted >= badge.threshold)
        .toList();
  }
}

class _RankChipRow extends StatelessWidget {
  const _RankChipRow({required this.steps, required this.current});

  final List<_RankStep> steps;
  final String current;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: steps.map((_RankStep step) {
        final bool active = step.title == current;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: active ? AppColors.primarySoft : AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            step.title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: active ? AppColors.primary : AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
          ),
        );
      }).toList(),
    );
  }
}

class _BadgeTile extends StatelessWidget {
  const _BadgeTile({required this.badge, required this.unlocked});

  final _BadgeSpec badge;
  final bool unlocked;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: unlocked ? Colors.white : AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: unlocked ? AppColors.primarySoft : AppColors.border,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: unlocked
                  ? AppColors.primarySoft
                  : AppColors.border.withValues(alpha: 0.55),
              shape: BoxShape.circle,
            ),
            child: Icon(
              unlocked ? badge.icon : Icons.lock_outline_rounded,
              color: unlocked ? AppColors.primary : AppColors.textHint,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            badge.title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: unlocked ? AppColors.textPrimary : AppColors.textHint,
                  fontWeight: FontWeight.w700,
                ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            '${badge.threshold} tasks',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textHint,
                ),
          ),
        ],
      ),
    );
  }
}

class _RankStep {
  const _RankStep(this.title, this.threshold);

  final String title;
  final int threshold;
}

class _BadgeSpec {
  const _BadgeSpec(this.title, this.icon, this.threshold);

  final String title;
  final IconData icon;
  final int threshold;
}

const List<_RankStep> _rankSteps = <_RankStep>[
  _RankStep('Novice', 0),
  _RankStep('Activist', 10),
  _RankStep('Hero', 25),
  _RankStep('Legend', 50),
];

const List<_BadgeSpec> _badges = <_BadgeSpec>[
  _BadgeSpec('First Mission', Icons.flag_rounded, 1),
  _BadgeSpec('Eco King', Icons.eco_rounded, 5),
  _BadgeSpec('100 Hours', Icons.schedule_rounded, 20),
  _BadgeSpec('Team Builder', Icons.groups_rounded, 10),
  _BadgeSpec('Community Spark', Icons.light_mode_rounded, 15),
  _BadgeSpec('Legendary Impact', Icons.emoji_events_rounded, 50),
];
