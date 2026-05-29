import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:jihc_volunteers_app/core/constants/app_constants.dart';
import 'package:jihc_volunteers_app/core/shared_widgets/app_widgets.dart';
import 'package:jihc_volunteers_app/core/theme/app_theme.dart';
import 'package:jihc_volunteers_app/features/tasks/screens/task_create_screen.dart';
import 'package:jihc_volunteers_app/features/tasks/screens/task_detail_screen.dart';
import 'package:jihc_volunteers_app/models/task_model.dart';
import 'package:jihc_volunteers_app/models/user_model.dart';
import 'package:jihc_volunteers_app/services/auth_service.dart';
import 'package:jihc_volunteers_app/services/firestore_service.dart';

class MyTasksScreen extends StatefulWidget {
  const MyTasksScreen({super.key});

  @override
  State<MyTasksScreen> createState() => _MyTasksScreenState();
}

class _MyTasksScreenState extends State<MyTasksScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();

  String get _uid => _authService.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<UserModel?>(
      stream: _firestoreService.getUserStream(_uid),
      builder: (BuildContext context, AsyncSnapshot<UserModel?> userSnapshot) {
        final bool isAdmin =
            userSnapshot.data?.role == AppConstants.administratorRole;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(title: const Text('My Applications')),
          body: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Column(
              children: <Widget>[
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppTheme.radius),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    padding: const EdgeInsets.all(6),
                    indicator: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    labelColor: AppColors.primary,
                    unselectedLabelColor: AppColors.textSecondary,
                    tabs: const <Widget>[
                      Tab(text: 'Applied'),
                      Tab(text: 'Created'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: <Widget>[
                      _TaskList(
                        stream: _firestoreService.getMyTasksStream(_uid),
                        emptyTitle: 'No applications yet',
                        emptySubtitle:
                            'Tasks you apply to will appear here for quick access.',
                      ),
                      _TaskList(
                        stream: _firestoreService.getMyCreatedTasksStream(_uid),
                        emptyTitle: 'No created tasks yet',
                        emptySubtitle: isAdmin
                            ? 'Create a volunteer opportunity to start building your own feed.'
                            : 'Only administrators can publish tasks.',
                        showCreateAction: isAdmin,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          floatingActionButton: isAdmin
              ? FloatingActionButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const TaskCreateScreen(),
                      ),
                    );
                  },
                  child: const Icon(Icons.add_rounded),
                )
              : null,
        );
      },
    );
  }
}

class _TaskList extends StatelessWidget {
  const _TaskList({
    required this.stream,
    required this.emptyTitle,
    required this.emptySubtitle,
    this.showCreateAction = false,
  });

  final Stream<List<TaskModel>> stream;
  final String emptyTitle;
  final String emptySubtitle;
  final bool showCreateAction;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<TaskModel>>(
      stream: stream,
      builder: (BuildContext context, AsyncSnapshot<List<TaskModel>> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const AppLoadingWidget();
        }

        if (snapshot.hasError) {
          return AppErrorWidget(message: snapshot.error.toString());
        }

        final List<TaskModel> tasks = snapshot.data ?? <TaskModel>[];
        if (tasks.isEmpty) {
          return AppEmptyWidget(
            icon: Icons.assignment_late_outlined,
            title: emptyTitle,
            subtitle: emptySubtitle,
            actionLabel: showCreateAction ? 'Create task' : null,
            onAction: showCreateAction
                ? () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const TaskCreateScreen(),
                      ),
                    );
                  }
                : null,
          );
        }

        return ListView.separated(
          itemCount: tasks.length,
          padding: const EdgeInsets.only(bottom: 120),
          separatorBuilder: (BuildContext context, int index) =>
              const SizedBox(height: 12),
          itemBuilder: (BuildContext context, int index) {
            final TaskModel task = tasks[index];
            return Card(
              child: InkWell(
                borderRadius: BorderRadius.circular(AppTheme.radius),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => TaskDetailScreen(taskId: task.id),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: <Widget>[
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: AppColors.primarySoft,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child:
                            task.imageUrl != null && task.imageUrl!.isNotEmpty
                            ? Image.network(task.imageUrl!, fit: BoxFit.cover)
                            : const Icon(
                                Icons.volunteer_activism_outlined,
                                color: AppColors.primary,
                              ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              task.title,
                              style: Theme.of(context).textTheme.titleLarge,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              task.location,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: <Widget>[
                                CategoryBadge(label: task.category),
                                const SizedBox(width: 8),
                                Text(
                                  DateFormat('MMM d').format(task.date),
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.textHint,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
