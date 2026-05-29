import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'package:jihc_volunteers_app/core/constants/app_constants.dart';
import 'package:jihc_volunteers_app/core/theme/app_theme.dart';
import 'package:jihc_volunteers_app/features/auth/screens/forgot_password_screen.dart';
import 'package:jihc_volunteers_app/features/auth/screens/login_screen.dart';
import 'package:jihc_volunteers_app/features/auth/screens/register_screen.dart';
import 'package:jihc_volunteers_app/features/auth/screens/role_selection_screen.dart';
import 'package:jihc_volunteers_app/features/auth/screens/splash_screen.dart';
import 'package:jihc_volunteers_app/features/chat/screens/chat_list_screen.dart';
import 'package:jihc_volunteers_app/features/chat/screens/group_chat_room_screen.dart';
import 'package:jihc_volunteers_app/features/crews/screens/crew_create_screen.dart';
import 'package:jihc_volunteers_app/features/home/screens/main_shell.dart';
import 'package:jihc_volunteers_app/features/leaderboard/screens/leaderboard_screen.dart';
import 'package:jihc_volunteers_app/features/gamification/screens/progress_screen.dart';
import 'package:jihc_volunteers_app/features/onboarding/screens/onboarding_screen.dart';
import 'package:jihc_volunteers_app/features/profile/screens/about_screen.dart';
import 'package:jihc_volunteers_app/features/profile/screens/notifications_screen.dart';
import 'package:jihc_volunteers_app/features/settings/screens/settings_screen.dart';
import 'package:jihc_volunteers_app/features/tasks/screens/task_create_screen.dart';
import 'package:jihc_volunteers_app/firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const JihcCrewApp(firebaseConfigured: true));
}

class JihcCrewApp extends StatelessWidget {
  const JihcCrewApp({super.key, required this.firebaseConfigured});

  final bool firebaseConfigured;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: AppConstants.splashRoute,
      routes: <String, WidgetBuilder>{
        AppConstants.splashRoute: (_) =>
            SplashScreen(firebaseConfigured: firebaseConfigured),
        AppConstants.onboardingRoute: (_) => const OnboardingScreen(),
        AppConstants.roleSelectionRoute: (_) => const RoleSelectionScreen(),
        AppConstants.loginRoute: (_) => const LoginScreen(),
        AppConstants.registerRoute: (_) => const RegisterScreen(),
        AppConstants.forgotPasswordRoute: (_) => const ForgotPasswordScreen(),
        AppConstants.homeRoute: (_) => const MainShell(),
        AppConstants.chatListRoute: (_) => const ChatListScreen(),
        AppConstants.ecologyChatRoute: (_) => const EcologyChatScreen(),
        AppConstants.sportsChatRoute: (_) => const EventsChatScreen(),
        AppConstants.charityChatRoute: (_) => const CharityChatScreen(),
        AppConstants.leaderboardRoute: (_) => const LeaderboardScreen(),
        AppConstants.progressRoute: (_) => const ProgressScreen(),
        AppConstants.settingsRoute: (_) => const SettingsScreen(),
        AppConstants.taskCreateRoute: (_) => const TaskCreateScreen(),
        AppConstants.crewCreateRoute: (_) => const CrewCreateScreen(),
        AppConstants.aboutRoute: (_) => const AboutScreen(),
        AppConstants.notificationsRoute: (_) => const NotificationsScreen(),
      },
    );
  }
}
