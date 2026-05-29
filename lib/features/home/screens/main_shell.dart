import 'package:flutter/material.dart';

import 'package:jihc_volunteers_app/core/theme/app_theme.dart';
import 'package:jihc_volunteers_app/features/chat/screens/chat_list_screen.dart';
import 'package:jihc_volunteers_app/features/feed/screens/jihc_stories_screen.dart';
import 'package:jihc_volunteers_app/features/gamification/screens/progress_screen.dart';
import 'package:jihc_volunteers_app/features/profile/screens/profile_screen.dart';
import 'package:jihc_volunteers_app/features/tasks/screens/my_tasks_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  static const List<Widget> _screens = <Widget>[
    JihcStoriesScreen(),
    MyTasksScreen(),
    ChatListScreen(),
    ProgressScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double horizontalMargin = constraints.maxWidth < 420 ? 14 : 20;

        return Scaffold(
          body: IndexedStack(index: _currentIndex, children: _screens),
          extendBody: true,
          bottomNavigationBar: SafeArea(
            minimum: EdgeInsets.fromLTRB(horizontalMargin, 0, horizontalMargin, 14),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppTheme.radius),
                border: Border.all(color: AppColors.border),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: AppColors.textPrimary.withValues(alpha: 0.06),
                    blurRadius: 22,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppTheme.radius),
                child: NavigationBar(
                  selectedIndex: _currentIndex,
                  onDestinationSelected: (int index) {
                    setState(() => _currentIndex = index);
                  },
                  destinations: const <NavigationDestination>[
                    NavigationDestination(
                      icon: Icon(Icons.home_outlined),
                      selectedIcon: Icon(Icons.home_rounded),
                      label: 'Home',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.assignment_outlined),
                      selectedIcon: Icon(Icons.assignment_rounded),
                      label: 'Applications',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.chat_bubble_outline_rounded),
                      selectedIcon: Icon(Icons.chat_bubble_rounded),
                      label: 'Chats',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.insights_outlined),
                      selectedIcon: Icon(Icons.insights_rounded),
                      label: 'Progress',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.person_outline_rounded),
                      selectedIcon: Icon(Icons.person_rounded),
                      label: 'Profile',
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
