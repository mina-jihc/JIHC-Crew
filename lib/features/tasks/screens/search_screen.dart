import 'package:flutter/material.dart';

import 'package:jihc_volunteers_app/core/shared_widgets/app_widgets.dart';
import 'package:jihc_volunteers_app/core/theme/app_theme.dart';
import 'package:jihc_volunteers_app/features/tasks/screens/task_detail_screen.dart';
import 'package:jihc_volunteers_app/models/task_model.dart';
import 'package:jihc_volunteers_app/services/firestore_service.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String query = _searchController.text.trim().toLowerCase();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Search tasks',
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
          ),
          onChanged: (_) => setState(() {}),
        ),
      ),
      body: StreamBuilder<List<TaskModel>>(
        stream: _firestoreService.getTasksStream(),
        builder: (BuildContext context, AsyncSnapshot<List<TaskModel>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AppLoadingWidget();
          }

          if (snapshot.hasError) {
            return AppErrorWidget(message: snapshot.error.toString());
          }

          final List<TaskModel> tasks = snapshot.data ?? <TaskModel>[];
          final List<TaskModel> filtered = query.isEmpty
              ? tasks
              : tasks.where((TaskModel task) {
                  final String haystack =
                      '${task.title} ${task.description} ${task.location} ${task.category}'
                          .toLowerCase();
                  return haystack.contains(query);
                }).toList();

          if (filtered.isEmpty) {
            return const AppEmptyWidget(
              icon: Icons.search_off_rounded,
              title: 'No search results',
              subtitle: 'Try another keyword or browse the full feed.',
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: filtered.length,
            separatorBuilder: (BuildContext context, int index) =>
                const SizedBox(height: 12),
            itemBuilder: (BuildContext context, int index) {
              final TaskModel task = filtered[index];
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
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: AppColors.primarySoft,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Icon(
                            Icons.search_rounded,
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
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${task.category} • ${task.location}',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
