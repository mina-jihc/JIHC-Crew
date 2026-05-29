import 'package:flutter/material.dart';

import 'package:jihc_volunteers_app/core/shared_widgets/app_widgets.dart';
import 'package:jihc_volunteers_app/core/theme/app_theme.dart';
import 'package:jihc_volunteers_app/features/crews/screens/crew_edit_screen.dart';
import 'package:jihc_volunteers_app/models/crew_model.dart';
import 'package:jihc_volunteers_app/services/auth_service.dart';
import 'package:jihc_volunteers_app/services/firestore_service.dart';

class CrewDetailScreen extends StatefulWidget {
  const CrewDetailScreen({super.key, required this.crewId});

  final String crewId;

  @override
  State<CrewDetailScreen> createState() => _CrewDetailScreenState();
}

class _CrewDetailScreenState extends State<CrewDetailScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();
  bool _loading = false;

  String get _uid => _authService.currentUser?.uid ?? '';

  Future<void> _toggleMembership(CrewModel crew) async {
    if (_uid.isEmpty) {
      _showSnack('Sign in first to join a crew.', isError: true);
      return;
    }

    setState(() => _loading = true);

    try {
      if (crew.members.contains(_uid)) {
        await _firestoreService.leaveCrew(crew.id, _uid);
        _showSnack('You left this crew.');
      } else {
        await _firestoreService.joinCrew(crew.id, _uid);
        _showSnack('You joined this crew.');
      }
    } catch (error) {
      _showSnack(error.toString(), isError: true);
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _deleteCrew(CrewModel crew) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete crew'),
          content: const Text(
            'This will permanently remove the crew and its current details.',
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
      await _firestoreService.deleteCrew(crew.id);
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Crew deleted.')));
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
    return StreamBuilder<CrewModel?>(
      stream: _firestoreService.getCrewStream(widget.crewId),
      builder: (BuildContext context, AsyncSnapshot<CrewModel?> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: AppLoadingWidget());
        }

        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(),
            body: AppErrorWidget(message: snapshot.error.toString()),
          );
        }

        final CrewModel? crew = snapshot.data;
        if (crew == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const AppEmptyWidget(
              icon: Icons.group_off_outlined,
              title: 'Crew not found',
              subtitle: 'This crew may have been removed from the hub.',
            ),
          );
        }

        final bool isCreator = crew.creatorId == _uid;
        final bool isJoined = crew.members.contains(_uid);

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text('Crew details'),
            actions: <Widget>[
              if (isCreator)
                IconButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => CrewEditScreen(crew: crew),
                      ),
                    );
                  },
                  icon: const Icon(Icons.edit_outlined),
                ),
              if (isCreator)
                IconButton(
                  onPressed: () => _deleteCrew(crew),
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
                    child: crew.imageUrl != null && crew.imageUrl!.isNotEmpty
                        ? Image.network(
                            crew.imageUrl!,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            color: AppColors.primarySoft,
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.groups_rounded,
                              color: AppColors.primary,
                              size: 76,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 20),
                CategoryBadge(label: crew.category),
                const SizedBox(height: 12),
                Text(
                  crew.name,
                  style: Theme.of(context).textTheme.displaySmall,
                ),
                const SizedBox(height: 12),
                Text(
                  crew.description,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 20),
                Row(
                  children: <Widget>[
                    const Icon(
                      Icons.people_outline_rounded,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '${crew.members.length} students in this crew',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          bottomNavigationBar: isCreator
              ? null
              : SafeArea(
                  minimum: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: TealButton(
                    label: isJoined ? 'Leave crew' : 'Join crew',
                    onPressed: () => _toggleMembership(crew),
                    isLoading: _loading,
                  ),
                ),
        );
      },
    );
  }
}
