import 'package:flutter/material.dart';

import 'package:jihc_volunteers_app/core/constants/app_constants.dart';
import 'package:jihc_volunteers_app/core/shared_widgets/app_widgets.dart';
import 'package:jihc_volunteers_app/core/theme/app_theme.dart';
import 'package:jihc_volunteers_app/features/chat/screens/group_chat_room_screen.dart';
import 'package:jihc_volunteers_app/services/auth_service.dart';
import 'package:jihc_volunteers_app/services/firestore_service.dart';

class NewChatScreen extends StatefulWidget {
  const NewChatScreen({super.key});

  @override
  State<NewChatScreen> createState() => _NewChatScreenState();
}

class _NewChatScreenState extends State<NewChatScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _membersController = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();

  String _category = AppConstants.chatCategories.first;
  bool _loading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _membersController.dispose();
    super.dispose();
  }

  Future<void> _createChat() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final String title = _titleController.text.trim();
    final String? uid = _authService.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      showTealErrorSnackBar(context, 'Please sign in again to create a chat.');
      return;
    }

    setState(() => _loading = true);

    try {
      final List<String> emails = _parseEmails(_membersController.text);
      final List<String> memberIds = await _firestoreService.findUserIdsByEmails(
        emails,
      );
      if (mounted && emails.isNotEmpty && memberIds.length < emails.length) {
        showTealErrorSnackBar(
          context,
          'Some emails were not found and were skipped.',
        );
      }

      final String chatId = await _firestoreService.createCustomChatRoom(
        title: title,
        category: _category,
        creatorId: uid,
        memberIds: memberIds,
      );

      if (!mounted) {
        return;
      }

      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => GroupChatRoomScreen(
            chatId: chatId,
            title: title,
            category: _category,
          ),
        ),
      );
    } catch (error) {
      if (mounted) {
        showTealErrorSnackBar(context, error.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  List<String> _parseEmails(String rawInput) {
    return rawInput
        .split(RegExp(r'[\n,;]'))
        .map((String value) => value.trim().toLowerCase())
        .where((String value) =>
            value.isNotEmpty &&
            value.endsWith(AppConstants.officialEmailDomain))
        .toSet()
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('New chat')),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 48,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Open a focused group chat',
                            style: Theme.of(context).textTheme.displaySmall,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Create a new room, choose a category, and invite JIHC members by email.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 24),
                          TextFormField(
                            controller: _titleController,
                            decoration: const InputDecoration(
                              labelText: 'Chat title',
                              prefixIcon: Icon(Icons.forum_outlined),
                            ),
                            validator: (String? value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Chat title is required.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            initialValue: _category,
                            decoration: const InputDecoration(
                              labelText: 'Category',
                              prefixIcon: Icon(Icons.category_outlined),
                            ),
                            items: AppConstants.chatCategories
                                .map(
                                  (String category) => DropdownMenuItem<String>(
                                    value: category,
                                    child: Text(category),
                                  ),
                                )
                                .toList(),
                            onChanged: (String? value) {
                              if (value != null) {
                                setState(() => _category = value);
                              }
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _membersController,
                            maxLines: 4,
                            decoration: const InputDecoration(
                              labelText: 'Member emails',
                              alignLabelWithHint: true,
                              prefixIcon: Icon(Icons.person_add_alt_1_rounded),
                              hintText:
                                  'student1@jihc.edu.kz, student2@jihc.edu.kz',
                            ),
                            validator: (String? value) {
                              if ((value ?? '').trim().isEmpty) {
                                return null;
                              }

                              final List<String> emails = _parseEmails(
                                value ?? '',
                              );
                              if (emails.isEmpty) {
                                return 'Enter JIHC emails separated by commas or new lines.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),
                          TealButton(
                            label: 'Create chat',
                            onPressed: _createChat,
                            isLoading: _loading,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Only official @jihc.edu.kz emails are accepted.',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
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
