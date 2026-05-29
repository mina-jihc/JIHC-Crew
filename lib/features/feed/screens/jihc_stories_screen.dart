import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:jihc_volunteers_app/core/constants/app_constants.dart';
import 'package:jihc_volunteers_app/core/shared_widgets/app_widgets.dart';
import 'package:jihc_volunteers_app/core/theme/app_theme.dart';
import 'package:jihc_volunteers_app/features/profile/screens/notifications_screen.dart';
import 'package:jihc_volunteers_app/features/tasks/screens/search_screen.dart';
import 'package:jihc_volunteers_app/features/tasks/screens/task_create_screen.dart';
import 'package:jihc_volunteers_app/features/tasks/screens/task_detail_screen.dart';
import 'package:jihc_volunteers_app/features/tasks/screens/task_edit_screen.dart';
import 'package:jihc_volunteers_app/models/task_model.dart';
import 'package:jihc_volunteers_app/models/user_model.dart';
import 'package:jihc_volunteers_app/services/auth_service.dart';
import 'package:jihc_volunteers_app/services/firestore_service.dart';

class JihcStoriesScreen extends StatefulWidget {
  const JihcStoriesScreen({super.key});

  @override
  State<JihcStoriesScreen> createState() => _JihcStoriesScreenState();
}

class _JihcStoriesScreenState extends State<JihcStoriesScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();
  final Set<String> _busyTaskIds = <String>{};

  String get _uid => _authService.currentUser?.uid ?? '';

  String get _firstName {
    final String displayName =
        _authService.currentUser?.displayName?.trim() ?? 'Volunteer';
    final List<String> parts = displayName.split(' ');
    return parts.firstWhere(
      (String value) => value.isNotEmpty,
      orElse: () => 'Volunteer',
    );
  }

  Future<void> _toggleLike(TaskModel task) async {
    if (_uid.isEmpty) {
      if (!mounted) {
        return;
      }
      showTealErrorSnackBar(
        context,
        'Sign in with your official JIHC email to like stories.',
      );
      return;
    }

    setState(() => _busyTaskIds.add(task.id));
    try {
      await _firestoreService.toggleTaskLike(
        taskId: task.id,
        uid: _uid,
        isLiked: task.isLikedBy(_uid),
      );
    } catch (error) {
      if (mounted) {
        showTealErrorSnackBar(context, error.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _busyTaskIds.remove(task.id));
      }
    }
  }

  Future<void> _toggleApplication(TaskModel task) async {
    if (_uid.isEmpty) {
      if (!mounted) {
        return;
      }
      showTealErrorSnackBar(
        context,
        'Sign in with your official JIHC email to apply.',
      );
      return;
    }

    final UserModel? profile = await _firestoreService.getUserProfile(_uid);
    if (profile?.role != AppConstants.volunteerRole) {
      if (!mounted) {
        return;
      }
      showTealErrorSnackBar(
        context,
        'Only volunteers can apply to volunteer moments.',
      );
      return;
    }

    if (!task.volunteers.contains(_uid) && task.isFull) {
      if (!mounted) {
        return;
      }
      showTealErrorSnackBar(context, 'This opportunity is already full.');
      return;
    }

    try {
      if (task.volunteers.contains(_uid)) {
        await _firestoreService.leaveTask(task.id, _uid);
      } else {
        await _firestoreService.joinTask(task.id, _uid);
      }
    } catch (error) {
      if (mounted) {
        showTealErrorSnackBar(context, error.toString());
      }
    }
  }

  Future<void> _openEdit(TaskModel task) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TaskEditScreen(task: task),
      ),
    );
  }

  Future<void> _confirmDelete(TaskModel task) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete post'),
          content: const Text(
            'This will remove the story card and its image from the feed.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: AppColors.error),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      await _firestoreService.deleteTask(task.id);
      if (!mounted) {
        return;
      }
      showTealErrorSnackBar(context, 'Story deleted.');
    } catch (error) {
      if (!mounted) {
        return;
      }
      showTealErrorSnackBar(context, error.toString());
    }
  }

  void _openStory(TaskModel task) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TaskDetailScreen(taskId: task.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String uid = _uid;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double horizontalPadding = constraints.maxWidth < 420 ? 16 : 20;
        final double storyAvatarSize =
            (constraints.maxWidth * 0.18).clamp(58.0, 74.0).toDouble();
        final double storyBarHeight =
            (storyAvatarSize + 58).clamp(124.0, 148.0).toDouble();
        final double cardWidth = constraints.maxWidth;

        return SafeArea(
          child: StreamBuilder<UserModel?>(
            stream: _firestoreService.getUserStream(uid),
            builder:
                (BuildContext context, AsyncSnapshot<UserModel?> userSnapshot) {
              final bool isAdmin =
                  userSnapshot.data?.role == AppConstants.administratorRole;
              final UserModel? currentUser = userSnapshot.data;

              return StreamBuilder<List<TaskModel>>(
                stream: _firestoreService.getTasksStream(),
                builder:
                    (
                      BuildContext context,
                      AsyncSnapshot<List<TaskModel>> taskSnapshot,
                    ) {
                  if (taskSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const AppLoadingWidget(
                      message: 'Loading JIHC Stories...',
                    );
                  }

                  if (taskSnapshot.hasError) {
                    return AppErrorWidget(
                      message: taskSnapshot.error.toString(),
                      onRetry: () => setState(() {}),
                    );
                  }

                  final List<TaskModel> stories =
                      List<TaskModel>.from(taskSnapshot.data ?? <TaskModel>[])
                        ..sort(
                          (TaskModel a, TaskModel b) => b.createdAt.compareTo(
                            a.createdAt,
                          ),
                        );

                  final List<TaskModel> recentStories = stories.length > 12
                      ? stories.sublist(0, 12)
                      : stories;

                  return RefreshIndicator(
                    color: AppColors.primary,
                    onRefresh: () async {
                      await Future<void>.delayed(const Duration(milliseconds: 250));
                    },
                    child: CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
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
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    UserAvatar(
                                      photoUrl: currentUser?.photoUrl,
                                      displayName:
                                          currentUser?.displayName ??
                                          _authService.currentUser?.displayName ??
                                          'Volunteer',
                                      radius: 24,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: <Widget>[
                                          Row(
                                            children: <Widget>[
                                              Flexible(
                                                child: Text(
                                                  'Hello, $_firstName',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .headlineMedium,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              if (isAdmin) ...<Widget>[
                                                const SizedBox(width: 8),
                                                const _VerifiedBadge(),
                                              ],
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Discover volunteer moments, apply instantly, and keep the feed calm.',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    _HeaderActionButton(
                                      icon: Icons.search_rounded,
                                      onPressed: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute<void>(
                                            builder: (_) => const SearchScreen(),
                                          ),
                                        );
                                      },
                                    ),
                                    const SizedBox(width: 10),
                                    _HeaderActionButton(
                                      icon: Icons.notifications_none_rounded,
                                      onPressed: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute<void>(
                                            builder: (_) =>
                                                const NotificationsScreen(),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(
                                      AppTheme.radius,
                                    ),
                                    border:
                                        Border.all(color: AppColors.border),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text(
                                        'JIHC Stories',
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineSmall,
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'Dobro.rf calmness, Instagram-style storytelling, and Teal-first actions.',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium,
                                      ),
                                      const SizedBox(height: 16),
                                      Row(
                                        children: <Widget>[
                                          Expanded(
                                            child: _MetricTile(
                                              label: 'Moments',
                                              value: stories.length.toString(),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: _MetricTile(
                                              label: 'Open',
                                              value: stories
                                                  .where(
                                                    (TaskModel story) =>
                                                        !story.isFull,
                                                  )
                                                  .length
                                                  .toString(),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: _MetricTile(
                                              label: 'Applied',
                                              value: stories
                                                  .where(
                                                    (TaskModel story) => story
                                                        .volunteers
                                                        .contains(uid),
                                                  )
                                                  .length
                                                  .toString(),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 18),
                                Row(
                                  children: <Widget>[
                                    Text(
                                      'Recent activity',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge,
                                    ),
                                    const Spacer(),
                                    Text(
                                      'Stories',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: AppColors.textSecondary,
                                          ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: SizedBox(
                            height: storyBarHeight,
                            child: ListView.separated(
                              padding: EdgeInsets.fromLTRB(
                                horizontalPadding,
                                14,
                                horizontalPadding,
                                0,
                              ),
                              scrollDirection: Axis.horizontal,
                              itemCount: recentStories.isEmpty
                                  ? 1
                                  : recentStories.length,
                              separatorBuilder:
                                  (BuildContext context, int index) =>
                                      const SizedBox(width: 12),
                              itemBuilder: (BuildContext context, int index) {
                                final TaskModel story = recentStories.isEmpty
                                    ? TaskModel(
                                        id: 'empty',
                                        title: 'No stories yet',
                                        description:
                                            'Add volunteer moments to populate the feed.',
                                        category: 'Community',
                                        creatorId: '',
                                        creatorName: 'JIHC Crew',
                                        date: DateTime.now(),
                                        location: 'JIHC',
                                        maxVolunteers: 0,
                                        volunteers: const <String>[],
                                        status: 'open',
                                        createdAt: DateTime.now(),
                                        imageUrl: null,
                                      )
                                    : recentStories[index];

                                return _StoryAvatarCard(
                                  story: story,
                                  size: storyAvatarSize,
                                  onTap: recentStories.isEmpty
                                      ? null
                                      : () => _openStory(story),
                                );
                              },
                            ),
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(
                              horizontalPadding,
                              24,
                              horizontalPadding,
                              8,
                            ),
                            child: SectionHeader(
                              title: 'Volunteer Moments',
                              actionLabel: isAdmin ? 'Create post' : null,
                              onAction: isAdmin
                                  ? () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute<void>(
                                          builder: (_) =>
                                              const TaskCreateScreen(),
                                        ),
                                      );
                                    }
                                  : null,
                            ),
                          ),
                        ),
                        if (stories.isEmpty)
                          SliverFillRemaining(
                            hasScrollBody: false,
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: horizontalPadding,
                              ),
                              child: const AppEmptyWidget(
                                icon: Icons.photo_library_outlined,
                                title: 'No volunteer stories yet',
                                subtitle:
                                    'Post a new moment or create a volunteer opportunity to start the feed.',
                              ),
                            ),
                          )
                        else
                          SliverPadding(
                            padding: EdgeInsets.fromLTRB(
                              horizontalPadding,
                              0,
                              horizontalPadding,
                              120,
                            ),
                            sliver: SliverList.separated(
                              itemCount: stories.length,
                              separatorBuilder:
                                  (BuildContext context, int index) =>
                                      const SizedBox(height: 18),
                              itemBuilder: (BuildContext context, int index) {
                                final TaskModel story = stories[index];
                                final bool isLiked = story.isLikedBy(uid);
                                final bool isApplied =
                                    story.volunteers.contains(uid);
                                final bool canApply =
                                    !isAdmin &&
                                    profileAllowsApplication(
                                      currentUser: currentUser,
                                    );

                                return _StoryPostCard(
                                  story: story,
                                  cardWidth: cardWidth,
                                  isAdmin: isAdmin,
                                  isLiked: isLiked,
                                  isApplied: isApplied,
                                  canApply: canApply,
                                  isBusy: _busyTaskIds.contains(story.id),
                                  onTap: () => _openStory(story),
                                  onLikeTap: () => _toggleLike(story),
                                  onApplyTap: () => _toggleApplication(story),
                                  onEditTap: () => _openEdit(story),
                                  onDeleteTap: () => _confirmDelete(story),
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  bool profileAllowsApplication({required UserModel? currentUser}) {
    return currentUser?.role == AppConstants.volunteerRole;
  }
}

class _VerifiedBadge extends StatelessWidget {
  const _VerifiedBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Icon(
            Icons.verified_rounded,
            size: 16,
            color: AppColors.primary,
          ),
          const SizedBox(width: 6),
          Text(
            'Verified',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _HeaderActionButton extends StatelessWidget {
  const _HeaderActionButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
          ),
          child: Icon(icon, color: AppColors.textPrimary),
        ),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.primary,
                ),
          ),
          const SizedBox(height: 4),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _StoryAvatarCard extends StatelessWidget {
  const _StoryAvatarCard({
    required this.story,
    required this.size,
    required this.onTap,
  });

  final TaskModel story;
  final double size;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(size),
      child: SizedBox(
        width: size,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: size,
              height: size,
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: <Color>[AppColors.primary, AppColors.primaryDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: ClipOval(
                child: story.imageUrl != null && story.imageUrl!.isNotEmpty
                    ? Image.network(
                        story.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder:
                            (
                              BuildContext context,
                              Object error,
                              StackTrace? stackTrace,
                            ) {
                              return _StoryFallbackAvatar(story: story);
                            },
                      )
                    : _StoryFallbackAvatar(story: story),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              story.creatorName.split(' ').first,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _StoryFallbackAvatar extends StatelessWidget {
  const _StoryFallbackAvatar({required this.story});

  final TaskModel story;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primarySoft,
      alignment: Alignment.center,
      child: Icon(
        Icons.volunteer_activism_rounded,
        color: AppColors.primary,
        size: sizeForText(story.title),
      ),
    );
  }

  double sizeForText(String value) {
    return value.length > 22 ? 28 : 34;
  }
}

class _StoryPostCard extends StatelessWidget {
  const _StoryPostCard({
    required this.story,
    required this.cardWidth,
    required this.isAdmin,
    required this.isLiked,
    required this.isApplied,
    required this.canApply,
    required this.isBusy,
    required this.onTap,
    required this.onLikeTap,
    required this.onApplyTap,
    required this.onEditTap,
    required this.onDeleteTap,
  });

  final TaskModel story;
  final double cardWidth;
  final bool isAdmin;
  final bool isLiked;
  final bool isApplied;
  final bool canApply;
  final bool isBusy;
  final VoidCallback onTap;
  final VoidCallback onLikeTap;
  final VoidCallback onApplyTap;
  final VoidCallback onEditTap;
  final VoidCallback onDeleteTap;

  @override
  Widget build(BuildContext context) {
    final String dateLabel = DateFormat('MMM d, h:mm a').format(story.createdAt);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                UserAvatar(
                  photoUrl: story.imageUrl,
                  displayName: story.creatorName,
                  radius: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Flexible(
                            child: Text(
                              story.creatorName,
                              style: Theme.of(context).textTheme.titleMedium,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.verified_rounded,
                            size: 16,
                            color: AppColors.primary,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$dateLabel - ${story.location}',
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (isAdmin)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      IconButton(
                        tooltip: 'Edit',
                        onPressed: onEditTap,
                        icon: const Icon(Icons.edit_outlined),
                        color: AppColors.primary,
                      ),
                      IconButton(
                        tooltip: 'Delete',
                        onPressed: onDeleteTap,
                        icon: const Icon(Icons.delete_outline_rounded),
                        color: AppColors.error,
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 14),
            GestureDetector(
              onTap: onTap,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: AspectRatio(
                  aspectRatio: 4 / 5,
                  child: story.imageUrl != null && story.imageUrl!.isNotEmpty
                      ? Image.network(
                          story.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (
                                BuildContext context,
                                Object error,
                                StackTrace? stackTrace,
                              ) {
                                return _PostFallback(width: cardWidth);
                              },
                        )
                      : _PostFallback(width: cardWidth),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              story.title,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              story.description,
              style: Theme.of(context).textTheme.bodyMedium,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 14),
            Row(
              children: <Widget>[
                _HeartAction(
                  liked: isLiked,
                  count: story.likesCount,
                  isBusy: isBusy,
                  onTap: onLikeTap,
                ),
                const SizedBox(width: 12),
                if (canApply)
                  Expanded(
                    child: TealButton(
                      label: isApplied ? 'Withdraw' : 'Apply',
                      onPressed: isBusy ? null : onApplyTap,
                      isLoading: isBusy,
                    ),
                  )
                else
                  Expanded(
                    child: Container(
                      height: 56,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceMuted,
                        borderRadius: BorderRadius.circular(AppTheme.radius),
                      ),
                      child: Text(
                        'Admin controls enabled',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HeartAction extends StatelessWidget {
  const _HeartAction({
    required this.liked,
    required this.count,
    required this.onTap,
    required this.isBusy,
  });

  final bool liked;
  final int count;
  final VoidCallback onTap;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: liked ? AppColors.primarySoft : AppColors.surfaceMuted,
      borderRadius: BorderRadius.circular(AppTheme.radius),
      child: InkWell(
        onTap: isBusy ? null : onTap,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radius),
            border: Border.all(
              color: liked ? AppColors.primary : AppColors.border,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                color: liked ? AppColors.primary : AppColors.textSecondary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                count.toString(),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: liked ? AppColors.primary : AppColors.textPrimary,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PostFallback extends StatelessWidget {
  const _PostFallback({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      color: AppColors.primarySoft,
      alignment: Alignment.center,
      child: Icon(
        Icons.volunteer_activism_rounded,
        color: AppColors.primary,
        size: (width * 0.18).clamp(48.0, 72.0).toDouble(),
      ),
    );
  }
}
