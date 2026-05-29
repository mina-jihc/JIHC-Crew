class AppConstants {
  const AppConstants._();

  static const String appName = 'JIHC Crew';
  static const String appVersion = '1.0.0';
  static const String authorName = 'Zhaylau Amina';
  static const String studentId = '090830652605';
  static const String officialEmailDomain = '@jihc.edu.kz';
  static const String volunteerRole = 'volunteer';
  static const String administratorRole = 'administrator';

  static const String splashRoute = '/';
  static const String onboardingRoute = '/onboarding';
  static const String roleSelectionRoute = '/role-selection';
  static const String loginRoute = '/login';
  static const String registerRoute = '/register';
  static const String forgotPasswordRoute = '/forgot-password';
  static const String homeRoute = '/home';
  static const String chatListRoute = '/chat-list';
  static const String ecologyChatRoute = '/chat-ecology';
  static const String sportsChatRoute = '/chat-events';
  static const String charityChatRoute = '/chat-charity';
  static const String leaderboardRoute = '/leaderboard';
  static const String progressRoute = '/progress';
  static const String settingsRoute = '/settings';
  static const String taskCreateRoute = '/tasks/create';
  static const String crewCreateRoute = '/crews/create';
  static const String aboutRoute = '/about';
  static const String notificationsRoute = '/notifications';

  static const String onboardingPreferenceKey = 'onboarding_done';

  static const List<String> chatCategories = <String>[
    'Ecology',
    'Sports',
    'Charity',
  ];

  static const List<String> taskCategories = <String>[
    'All',
    'Environment',
    'Education',
    'Community',
    'Health',
    'Culture',
    'Sports',
  ];
}
