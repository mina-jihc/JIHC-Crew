import 'package:flutter/material.dart';

import 'package:jihc_volunteers_app/core/shared_widgets/app_widgets.dart';
import 'package:jihc_volunteers_app/core/theme/app_theme.dart';
import 'package:jihc_volunteers_app/features/crews/screens/crew_create_screen.dart';
import 'package:jihc_volunteers_app/features/crews/screens/crew_detail_screen.dart';
import 'package:jihc_volunteers_app/models/crew_model.dart';
import 'package:jihc_volunteers_app/services/auth_service.dart';
import 'package:jihc_volunteers_app/services/firestore_service.dart';

class CrewHubScreen extends StatelessWidget {
  const CrewHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final FirestoreService firestoreService = FirestoreService();
    final String uid = AuthService().currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Crew hub')),
      body: StreamBuilder<List<CrewModel>>(
        stream: firestoreService.getCrewsStream(),
        builder:
            (BuildContext context, AsyncSnapshot<List<CrewModel>> snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const AppLoadingWidget(message: 'Loading crews...');
              }

              if (snapshot.hasError) {
                return AppErrorWidget(message: snapshot.error.toString());
              }

              final List<CrewModel> crews = snapshot.data ?? <CrewModel>[];
              if (crews.isEmpty) {
                return AppEmptyWidget(
                  icon: Icons.groups_outlined,
                  title: 'No crews yet',
                  subtitle: 'Create the first student volunteer crew for JIHC.',
                  actionLabel: 'Create crew',
                  onAction: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const CrewCreateScreen(),
                      ),
                    );
                  },
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(20),
                itemCount: crews.length,
                separatorBuilder: (BuildContext context, int index) =>
                    const SizedBox(height: 14),
                itemBuilder: (BuildContext context, int index) {
                  final CrewModel crew = crews[index];
                  final bool isJoined = crew.members.contains(uid);
                  return Card(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(AppTheme.radius),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => CrewDetailScreen(crewId: crew.id),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: <Widget>[
                            Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                color: AppColors.primarySoft,
                                borderRadius: BorderRadius.circular(22),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child:
                                  crew.imageUrl != null &&
                                      crew.imageUrl!.isNotEmpty
                                  ? Image.network(
                                      crew.imageUrl!,
                                      fit: BoxFit.cover,
                                    )
                                  : const Icon(
                                      Icons.groups_rounded,
                                      color: AppColors.primary,
                                      size: 34,
                                    ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    crew.name,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleLarge,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    crew.description,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: <Widget>[
                                      CategoryBadge(label: crew.category),
                                      const SizedBox(width: 8),
                                      Text(
                                        '${crew.members.length} members',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodySmall,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            if (isJoined)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primarySoft,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  'Joined',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const CrewCreateScreen()),
          );
        },
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}
