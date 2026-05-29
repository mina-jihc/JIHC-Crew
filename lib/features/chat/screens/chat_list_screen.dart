import 'package:flutter/material.dart';

import 'package:jihc_volunteers_app/core/constants/app_constants.dart';
import 'package:jihc_volunteers_app/core/shared_widgets/app_widgets.dart';
import 'package:jihc_volunteers_app/core/theme/app_theme.dart';
import 'package:jihc_volunteers_app/features/chat/screens/group_chat_room_screen.dart';
import 'package:jihc_volunteers_app/features/chat/screens/new_chat_screen.dart';
import 'package:jihc_volunteers_app/models/chat_room_model.dart';
import 'package:jihc_volunteers_app/models/user_model.dart';
import 'package:jihc_volunteers_app/services/auth_service.dart';
import 'package:jihc_volunteers_app/services/firestore_service.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthService authService = AuthService();
    final FirestoreService firestoreService = FirestoreService();
    final String uid = authService.currentUser?.uid ?? '';

    return StreamBuilder<UserModel?>(
      stream: firestoreService.getUserStream(uid),
      builder: (BuildContext context, AsyncSnapshot<UserModel?> userSnapshot) {
        final bool isAdmin =
            userSnapshot.data?.role == AppConstants.administratorRole;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(title: const Text('Chat List')),
          floatingActionButton: isAdmin
              ? FloatingActionButton.extended(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const NewChatScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add_comment_outlined),
                  label: const Text('New chat'),
                )
              : null,
          body: SafeArea(
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final double sidePadding = constraints.maxWidth < 420 ? 16 : 20;
                return SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    sidePadding,
                    20,
                    sidePadding,
                    isAdmin ? 120 : 20,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 720),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Volunteer chats',
                            style: Theme.of(context).textTheme.displaySmall,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Use the preset category rooms or open a focused group chat with your team.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 20),
                          ..._buildPresetRooms(context),
                          const SizedBox(height: 26),
                          Row(
                            children: <Widget>[
                              Text(
                                'Custom chats',
                                style:
                                    Theme.of(context).textTheme.headlineSmall,
                              ),
                              const Spacer(),
                              if (isAdmin)
                                Text(
                                  'Admins can create rooms',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(color: AppColors.textHint),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          StreamBuilder<List<ChatRoomModel>>(
                            stream: firestoreService.getCustomChatRoomsStream(),
                            builder:
                                (
                                  BuildContext context,
                                  AsyncSnapshot<List<ChatRoomModel>>
                                      chatSnapshot,
                                ) {
                              if (chatSnapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Padding(
                                  padding: EdgeInsets.only(top: 10),
                                  child: AppLoadingWidget(
                                    message: 'Loading custom chats...',
                                  ),
                                );
                              }

                              if (chatSnapshot.hasError) {
                                return AppErrorWidget(
                                  message: chatSnapshot.error.toString(),
                                  onRetry: () {},
                                );
                              }

                              final List<ChatRoomModel> customRooms =
                                  chatSnapshot.data ?? <ChatRoomModel>[];

                              if (customRooms.isEmpty) {
                                return AppEmptyWidget(
                                  icon: Icons.forum_outlined,
                                  title: isAdmin
                                      ? 'No custom chats yet'
                                      : 'No custom chats available',
                                  subtitle: isAdmin
                                      ? 'Tap the plus button to open a new group chat and invite members.'
                                      : 'You will see invited group chats here.',
                                );
                              }

                              return ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: customRooms.length,
                                separatorBuilder:
                                    (BuildContext context, int index) =>
                                        const SizedBox(height: 12),
                                itemBuilder: (BuildContext context, int index) {
                                  final ChatRoomModel room = customRooms[index];
                                  return _ChatRoomCard(
                                    title: room.title,
                                    subtitle:
                                        '${room.category} • ${room.memberCount} members',
                                    icon: Icons.forum_rounded,
                                    color: AppColors.primary,
                                    onTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute<void>(
                                          builder: (_) => GroupChatRoomScreen(
                                            chatId: room.id,
                                            title: room.title,
                                            category: room.category,
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildPresetRooms(BuildContext context) {
    return AppConstants.chatCategories
        .map(
          (String category) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _ChatRoomCard(
              title: category,
              subtitle: _subtitleForCategory(category),
              icon: _iconForCategory(category),
              color: _colorForCategory(category),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => _screenForCategory(category),
                  ),
                );
              },
            ),
          ),
        )
        .toList(growable: false);
  }

  String _subtitleForCategory(String category) {
    switch (category) {
      case 'Ecology':
        return 'Talk about clean-up actions and sustainability work.';
      case 'Sports':
        return 'Coordinate events, fitness drives, and campus games.';
      case 'Charity':
        return 'Plan donation drives and support missions together.';
      default:
        return 'A focused volunteer conversation space.';
    }
  }

  IconData _iconForCategory(String category) {
    switch (category) {
      case 'Ecology':
        return Icons.eco_outlined;
      case 'Sports':
        return Icons.sports_basketball_rounded;
      case 'Charity':
        return Icons.favorite_outline_rounded;
      default:
        return Icons.forum_outlined;
    }
  }

  Color _colorForCategory(String category) {
    switch (category) {
      case 'Ecology':
        return AppColors.primary;
      case 'Sports':
        return const Color(0xFF3A7CA5);
      case 'Charity':
        return const Color(0xFFE76F51);
      default:
        return AppColors.primary;
    }
  }

  Widget _screenForCategory(String category) {
    switch (category) {
      case 'Ecology':
        return const EcologyChatScreen();
      case 'Sports':
        return const EventsChatScreen();
      case 'Charity':
        return const CharityChatScreen();
      default:
        return const EcologyChatScreen();
    }
  }
}

class _ChatRoomCard extends StatelessWidget {
  const _ChatRoomCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radius),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: <Widget>[
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
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
  }
}
