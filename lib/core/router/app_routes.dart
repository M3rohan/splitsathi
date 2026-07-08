class AppRoutes {
  AppRoutes._();
  static const String splash = '/';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String forgotPassword = '/forgot-password';
  static const String onboarding = '/onboarding';

  static const String home = '/home';
  static const String groups = '/groups';
  static const String createGroup = '/groups/create';
  static const String groupDetail = '/groups/:groupId';
  static const String addExpense = '/groups/:groupId/add-expense';
  static const String expenseDetail = '/groups/:groupId/expense/:expenseId';
  static const String settleUp = '/groups/:groupId/settle-up';
  static const String insights = '/groups/:groupId/insights';

  static const String profile = '/profile';
  static const String settings = '/settings';
  static const String notifications = '/notifications';

  // ---------- Route Names (used for context.goNamed()) ----------
  static const String splashName = 'splash';
  static const String loginName = 'login';
  static const String signupName = 'signup';
  static const String forgotPasswordName = 'forgotPassword';
  static const String onboardingName = 'onboarding';

  static const String homeName = 'home';
  static const String groupsName = 'groups';
  static const String createGroupName = 'createGroup';
  static const String groupDetailName = 'groupDetail';
  static const String addExpenseName = 'addExpense';
  static const String expenseDetailName = 'expenseDetail';
  static const String settleUpName = 'settleUp';
  static const String insightsName = 'insights';

  static const String profileName = 'profile';
  static const String settingsName = 'settings';
  static const String notificationsName = 'notifications';

  // ---------- Helper methods for building dynamic paths ----------
  static String groupDetailPath(String groupId) => '/groups/$groupId';

  static String addExpensePath(String groupId) =>
      '/groups/$groupId/add-expense';

  static String expenseDetailPath(String groupId, String expenseId) =>
      '/groups/$groupId/expense/$expenseId';

  static String settleUpPath(String groupId) => '/groups/$groupId/settle-up';

  static String insightsPath(String groupId) => '/groups/$groupId/insights';
}
