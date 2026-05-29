import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:jihc_volunteers_app/core/constants/app_constants.dart';
import 'package:jihc_volunteers_app/core/shared_widgets/app_widgets.dart';
import 'package:jihc_volunteers_app/core/theme/app_theme.dart';
import 'package:jihc_volunteers_app/features/tasks/screens/task_edit_screen.dart';
import 'package:jihc_volunteers_app/models/task_model.dart';
import 'package:jihc_volunteers_app/models/user_model.dart';
import 'package:jihc_volunteers_app/services/auth_service.dart';
import 'package:jihc_volunteers_app/services/firestore_service.dart';

class TaskDetailScreen extends StatefulWidget {
  const TaskDetailScreen({super.key, required this.taskId});

  final String taskId;

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();
  bool _joinLoading = false;
  late final Future<UserModel?> _profileFuture;

  String get _uid => _authService.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    _profileFuture = _firestoreService.getUserProfile(_uid);
  }

  Future<void> _toggleJoin(TaskModel task) async {
    if (_uid.isEmpty) {
      _showSnack('Sign in first to apply.', isError: true);
      return;
    }

    setState(() => _joinLoading = true);
    try {
      if (task.volunteers.contains(_uid)) {
        await _firestoreService.leaveTask(task.id, _uid);
        _showSnack('You withdrew your application.');
      } else {
        await _firestoreService.joinTask(task.id, _uid);
        _showSnack('You applied to this task.');
      }
    } catch (error) {
      _showSnack(error.toString(), isError: true);
    } finally {
      if (mounted) {
        setState(() => _joinLoading = false);
      }
    }
  }

  Future<void> _confirmDelete(TaskModel task) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete task'),
          content: const Text(
            'This will permanently remove the volunteer task from the feed.',
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
      Navigator.of(context).pop();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Task deleted.')));
    } catch (error) {
      _showSnack(error.toString(), isError: true);
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserModel?>(
      future: _profileFuture,
      builder: (BuildContext context, AsyncSnapshot<UserModel?> profileSnapshot) {
        if (profileSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: AppLoadingWidget());
        }

        final bool canApply =
            profileSnapshot.data?.role == AppConstants.volunteerRole;
        final bool signedIn = _uid.isNotEmpty;

        return StreamBuilder<TaskModel?>(
          stream: _firestoreService.getTaskStream(widget.taskId),
          builder: (BuildContext context, AsyncSnapshot<TaskModel?> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(body: AppLoadingWidget());
            }

            if (snapshot.hasError) {
              return Scaffold(
                appBar: AppBar(),
                body: AppErrorWidget(message: snapshot.error.toString()),
              );
            }

            final TaskModel? task = snapshot.data;
            if (task == null) {
              return Scaffold(
                appBar: AppBar(),
                body: const AppEmptyWidget(
                  icon: Icons.search_off_rounded,
                  title: 'Task not found',
                  subtitle: 'This volunteer task may have been removed.',
                ),
              );
            }

            final bool isCreator = task.creatorId == _uid;
            final bool isAdmin =
                profileSnapshot.data?.role == AppConstants.administratorRole;
            final bool canManage = isCreator || isAdmin;
            final bool isJoined = task.volunteers.contains(_uid);

            return Scaffold(
              backgroundColor: AppColors.background,
              appBar: AppBar(
                title: const Text('Task details'),
                actions: <Widget>[
                  if (canManage)
                    IconButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => TaskEditScreen(task: task),
                          ),
                        );
                      },
                      icon: const Icon(Icons.edit_outlined),
                    ),
                  if (canManage)
                    IconButton(
                      onPressed: () => _confirmDelete(task),
                      icon: const Icon(Icons.delete_outline_rounded),
                    ),
                ],
              ),
              body: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 140),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppTheme.radius),
                      child: AspectRatio(
                        aspectRatio: 16 / 9,
                        child:
                            task.imageUrl != null && task.imageUrl!.isNotEmpty
                            ? Image.network(
                                task.imageUrl!,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              )
                            : Container(
                                color: AppColors.primarySoft,
                                alignment: Alignment.center,
                                child: const Icon(
                                  Icons.volunteer_activism_outlined,
                                  color: AppColors.primary,
                                  size: 72,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: <Widget>[
                        CategoryBadge(label: task.category),
                        if (!canManage && !canApply) ...<Widget>[
                          const SizedBox(width: 10),
                          const CategoryBadge(label: 'ADMIN VIEW'),
                        ],
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      task.title,
                      style: Theme.of(context).textTheme.displaySmall,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      task.description,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 20),
                    _InfoRow(
                      icon: Icons.calendar_today_outlined,
                      label: DateFormat('EEEE, MMMM d, y').format(task.date),
                    ),
                    const SizedBox(height: 12),
                    _InfoRow(
                      icon: Icons.location_on_outlined,
                      label: task.location,
                    ),
                    const SizedBox(height: 12),
                    _InfoRow(
                      icon: Icons.people_outline_rounded,
                      label:
                          '${task.volunteers.length} of ${task.maxVolunteers} volunteers joined',
                    ),
                    const SizedBox(height: 12),
                    _InfoRow(
                      icon: Icons.person_outline_rounded,
                      label: task.creatorName,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Capacity',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: LinearProgressIndicator(
                        minHeight: 10,
                        value: task.maxVolunteers == 0
                            ? 0
                            : task.volunteers.length / task.maxVolunteers,
                      ),
                    ),
                    if (!canManage && !canApply) ...<Widget>[
                      const SizedBox(height: 20),
                      SoftCard(
                        child: Text(
                          signedIn
                              ? 'Administrators manage tasks from the feed. Volunteers can apply to join here.'
                              : 'Sign in with your official JIHC email to apply to volunteer tasks.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              bottomNavigationBar: !isCreator && canApply
                  ? SafeArea(
                      minimum: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      child: TealButton(
                        label: isJoined ? 'Withdraw application' : 'Apply',
                        onPressed: task.isFull && !isJoined
                            ? null
                            : () => _toggleJoin(task),
                        isLoading: _joinLoading,
                      ),
                    )
                  : null,
            );
          },
        );
      },
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textPrimary),
          ),
        ),
      ],
    );
  }
}
