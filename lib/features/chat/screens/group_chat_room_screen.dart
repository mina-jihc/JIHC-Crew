import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:jihc_volunteers_app/core/constants/app_constants.dart';
import 'package:jihc_volunteers_app/core/shared_widgets/app_widgets.dart';
import 'package:jihc_volunteers_app/core/theme/app_theme.dart';
import 'package:jihc_volunteers_app/models/chat_message_model.dart';
import 'package:jihc_volunteers_app/models/user_model.dart';
import 'package:jihc_volunteers_app/services/auth_service.dart';
import 'package:jihc_volunteers_app/services/firestore_service.dart';

class GroupChatRoomScreen extends StatefulWidget {
  const GroupChatRoomScreen({
    super.key,
    required this.chatId,
    required this.title,
    required this.category,
  });

  final String chatId;
  final String title;
  final String category;

  @override
  State<GroupChatRoomScreen> createState() => _GroupChatRoomScreenState();
}

class _GroupChatRoomScreenState extends State<GroupChatRoomScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();
  final TextEditingController _messageController = TextEditingController();
  bool _sending = false;

  String get _uid => _authService.currentUser?.uid ?? '';

  String get _displayName =>
      _authService.currentUser?.displayName?.trim().isNotEmpty == true
          ? _authService.currentUser!.displayName!.trim()
          : 'JIHC Student';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _firestoreService.ensureChatRoom(
        chatId: widget.chatId,
        title: widget.title,
        category: widget.category,
      );
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final String text = _messageController.text.trim();
    if (text.isEmpty || _uid.isEmpty) {
      return;
    }

    setState(() => _sending = true);
    try {
      await _firestoreService.sendChatMessage(
        chatId: widget.chatId,
        senderId: _uid,
        senderName: _displayName,
        message: text,
      );
      _messageController.clear();
    } catch (error) {
      if (mounted) {
        showTealErrorSnackBar(context, error.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
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
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(widget.title),
                Text(
                  widget.category,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            actions: <Widget>[
              if (isAdmin)
                IconButton(
                  tooltip: 'Add members',
                  onPressed: _promptAddMembers,
                  icon: const Icon(Icons.person_add_alt_1_rounded),
                ),
            ],
          ),
          body: Column(
            children: <Widget>[
              Expanded(
                child: StreamBuilder<List<ChatMessageModel>>(
                  stream: _firestoreService.getChatMessagesStream(widget.chatId),
                  builder:
                      (
                        BuildContext context,
                        AsyncSnapshot<List<ChatMessageModel>> snapshot,
                      ) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const AppLoadingWidget(
                            message: 'Loading chat...',
                          );
                        }

                        if (snapshot.hasError) {
                          return AppErrorWidget(
                            message: snapshot.error.toString(),
                            onRetry: () => setState(() {}),
                          );
                        }

                        final List<ChatMessageModel> messages =
                            snapshot.data ?? <ChatMessageModel>[];
                        if (messages.isEmpty) {
                          return const AppEmptyWidget(
                            icon: Icons.forum_outlined,
                            title: 'No messages yet',
                            subtitle:
                                'Start the first conversation and keep it calm, useful, and friendly.',
                          );
                        }

                        return ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                          itemCount: messages.length,
                          separatorBuilder: (BuildContext context, int index) =>
                              const SizedBox(height: 10),
                          itemBuilder: (BuildContext context, int index) {
                            final ChatMessageModel message = messages[index];
                            final bool isMine = message.senderId == _uid;
                            return _MessageBubble(
                              message: message,
                              isMine: isMine,
                              isAdmin: isAdmin,
                              onLongPress: isAdmin
                                  ? () => _confirmDeleteMessage(message)
                                  : null,
                            );
                          },
                        );
                      },
                ),
              ),
              SafeArea(
                top: false,
                minimum: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppTheme.radius),
                    border: Border.all(color: AppColors.border),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: AppColors.textPrimary.withValues(alpha: 0.05),
                        blurRadius: 18,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          textInputAction: TextInputAction.send,
                          minLines: 1,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            hintText: 'Write a message',
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 8),
                          ),
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 52,
                        height: 52,
                        child: FilledButton(
                          onPressed: _sending ? null : _sendMessage,
                          child: _sending
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.send_rounded, size: 18),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmDeleteMessage(ChatMessageModel message) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete message'),
          content: const Text(
            'This will remove the message for everyone in the chat.',
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
      await _firestoreService.deleteChatMessage(
        chatId: widget.chatId,
        messageId: message.id,
      );
    } catch (error) {
      if (mounted) {
        showTealErrorSnackBar(context, error.toString());
      }
    }
  }

  Future<void> _promptAddMembers() async {
    final TextEditingController controller = TextEditingController();
    try {
      final bool? confirmed = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Add members'),
            content: TextField(
              controller: controller,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'member1@jihc.edu.kz, member2@jihc.edu.kz',
                helperText: 'Use official JIHC emails separated by commas.',
              ),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Add'),
              ),
            ],
          );
        },
      );

      if (confirmed != true) {
        return;
      }

      final List<String> emails = controller.text
          .split(RegExp(r'[\n,;]'))
          .map((String value) => value.trim().toLowerCase())
          .where(
            (String value) =>
                value.isNotEmpty &&
                value.endsWith(AppConstants.officialEmailDomain),
          )
          .toSet()
          .toList();

      if (emails.isEmpty) {
        _showSnack('Enter at least one official @jihc.edu.kz email.');
        return;
      }

      final List<String> memberIds = await _firestoreService.findUserIdsByEmails(
        emails,
      );
      if (memberIds.isEmpty) {
        if (!mounted) {
          return;
        }
        _showSnack('No matching JIHC users were found.');
        return;
      }

      await _firestoreService.addMembersToChatRoom(
        chatId: widget.chatId,
        memberIds: memberIds,
      );

      if (!mounted) {
        return;
      }

      _showSnack('Members added to the chat.');
    } catch (error) {
      _showSnack(error.toString());
    } finally {
      controller.dispose();
    }
  }

  void _showSnack(String message) {
    if (!mounted) {
      return;
    }
    showTealErrorSnackBar(context, message);
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.isMine,
    required this.isAdmin,
    this.onLongPress,
  });

  final ChatMessageModel message;
  final bool isMine;
  final bool isAdmin;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final Color bubbleColor = isMine
        ? AppColors.primary
        : AppColors.surfaceMuted;
    final Color textColor = isMine ? Colors.white : AppColors.textPrimary;
    final Color metaColor = isMine
        ? Colors.white.withValues(alpha: 0.78)
        : AppColors.textSecondary;
    final String timeLabel = DateFormat('HH:mm').format(message.sentAt);

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: GestureDetector(
          onLongPress: onLongPress,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: bubbleColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isMine ? Colors.transparent : AppColors.border,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  message.senderName,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: metaColor,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  message.message,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: textColor,
                      ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      timeLabel,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: metaColor,
                          ),
                    ),
                    if (isAdmin) ...<Widget>[
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.shield_outlined,
                        size: 14,
                        color: AppColors.primary,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class EcologyChatScreen extends StatelessWidget {
  const EcologyChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const GroupChatRoomScreen(
      chatId: 'ecology',
      title: 'Ecology Chat',
      category: 'Ecology',
    );
  }
}

class EventsChatScreen extends StatelessWidget {
  const EventsChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const GroupChatRoomScreen(
      chatId: 'sports',
      title: 'Events Chat',
      category: 'Sports',
    );
  }
}

class CharityChatScreen extends StatelessWidget {
  const CharityChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const GroupChatRoomScreen(
      chatId: 'charity',
      title: 'Charity Chat',
      category: 'Charity',
    );
  }
}
