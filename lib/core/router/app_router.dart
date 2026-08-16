import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:splitsathi/core/di/service_locator.dart';
import 'package:splitsathi/core/router/app_routes.dart';
import 'package:splitsathi/core/router/route_transitions.dart';
import 'package:splitsathi/features/auth/bloc/auth_bloc.dart';
import 'package:splitsathi/features/auth/bloc/auth_state.dart';
import 'package:splitsathi/features/auth/screens/forgot_password_screen.dart';
import 'package:splitsathi/features/auth/screens/login_screen.dart';
import 'package:splitsathi/features/auth/screens/signup_screen.dart';
import 'package:splitsathi/features/expenses/screens/add_expense_screen.dart';
import 'package:splitsathi/features/groups/screens/create_group_screen.dart';
import 'package:splitsathi/features/groups/screens/group_detail_screen.dart';
import 'package:splitsathi/features/home/screens/home_screen.dart';
import 'package:splitsathi/features/insights/screens/insights_screen.dart';
import 'package:splitsathi/features/notifications/screens/notifications_screen.dart';
import 'package:splitsathi/features/onboarding/screens/splash_screen.dart';
import 'package:splitsathi/features/profile/screens/about_us_screen.dart';
import 'package:splitsathi/features/profile/screens/profile_screen.dart';
import 'package:splitsathi/features/profile/screens/settings_screen.dart';

class AppRouter {
  AppRouter._();

  static final GlobalKey<NavigatorState> rootNavigatorKey =
      GlobalKey<NavigatorState>();

  static final GoRouter router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    refreshListenable: GoRouterRefreshStream(getIt<AuthBloc>().stream),
    redirect: (context, state) {
      final authState = getIt<AuthBloc>().state;
      final isAuthenticated = authState.status == AuthStatus.authenticated;
      final isGoingToSplash = state.matchedLocation == AppRoutes.splash;
      final isGoingToPublicAuthRoute =
          state.matchedLocation == AppRoutes.login ||
          state.matchedLocation == AppRoutes.signup ||
          state.matchedLocation == AppRoutes.forgotPassword;

      // Let splash screen handle its own initial routing logic
      if (isGoingToSplash) return null;

      // Logged in but trying to visit login/signup → send to home
      if (isAuthenticated && isGoingToPublicAuthRoute) return AppRoutes.home;

      // Not logged in and trying to visit a protected route → send to login
      if (!isAuthenticated &&
          authState.status != AuthStatus.initial &&
          authState.status != AuthStatus.loading &&
          !isGoingToPublicAuthRoute) {
        return AppRoutes.login;
      }

      return null; // no redirect needed
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        name: AppRoutes.splashName,
        pageBuilder: (context, state) => buildPageWithTransition(
          context: context,
          state: state,
          child: const SplashScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.login,
        name: AppRoutes.loginName,
        pageBuilder: (context, state) => buildPageWithTransition(
          context: context,
          state: state,
          child: const LoginScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.signup,
        name: AppRoutes.signupName,
        pageBuilder: (context, state) => buildPageWithTransition(
          context: context,
          state: state,
          child: const SignupScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.home,
        name: AppRoutes.homeName,
        pageBuilder: (context, state) => buildPageWithTransition(
          context: context,
          state: state,
          child: const HomeScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.createGroup,
        name: AppRoutes.createGroupName,
        pageBuilder: (context, state) => buildPageWithTransition(
          context: context,
          state: state,
          child: const CreateGroupScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.groups,
        name: AppRoutes.groupsName,
        pageBuilder: (context, state) => buildPageWithTransition(
          context: context,
          state: state,
          child: const _PlaceholderScreen(title: 'Groups'),
        ),
      ),
      GoRoute(
        path: AppRoutes.groupDetail,
        name: AppRoutes.groupDetailName,
        pageBuilder: (context, state) {
          final groupId = state.pathParameters['groupId']!;
          return buildPageWithTransition(
            context: context,
            state: state,
            child: GroupDetailScreen(groupId: groupId),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.profile,
        name: AppRoutes.profileName,
        pageBuilder: (context, state) => buildPageWithTransition(
          context: context,
          state: state,
          child: const ProfileScreen(),
        ),
      ),

      GoRoute(
        path: AppRoutes.settings,
        name: AppRoutes.settingsName,
        pageBuilder: (context, state) => buildPageWithTransition(
          context: context,
          state: state,
          child: const SettingsScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.addExpense,
        name: AppRoutes.addExpenseName,
        pageBuilder: (context, state) {
          final groupId = state.pathParameters['groupId']!;
          final extra = state.extra as Map<String, dynamic>;
          return buildPageWithTransition(
            context: context,
            state: state,
            child: AddExpenseScreen(
              groupId: groupId,
              groupName: extra['groupName'] as String,
              members: extra['members'] as List<Map<String, dynamic>>,
              currentUserId: extra['currentUserId'] as String,
            ),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.notifications,
        name: AppRoutes.notificationsName,
        pageBuilder: (context, state) => buildPageWithTransition(
          context: context,
          state: state,
          child: const NotificationsScreen(),
        ),
      ),

      GoRoute(
        path: AppRoutes.insights,
        name: AppRoutes.insightsName,
        pageBuilder: (context, state) {
          final groupId = state.pathParameters['groupId']!;
          return buildPageWithTransition(
            context: context,
            state: state,
            child: InsightsScreen(groupId: groupId),
          );
        },
      ),

      GoRoute(
        path: AppRoutes.forgotPassword,
        name: AppRoutes.forgotPasswordName,
        pageBuilder: (context, state) => buildPageWithTransition(
          context: context,
          state: state,
          child: const ForgotPasswordScreen(),
        ),
      ),

      GoRoute(
        path: AppRoutes.aboutUs,
        name: AppRoutes.aboutUsName,
        pageBuilder: (context, state) => buildPageWithTransition(
          context: context,
          state: state,
          child: const AboutUsScreen(),
        ),
      ),
    ],
  );
}

class _PlaceholderScreen extends StatelessWidget {
  final String title;
  const _PlaceholderScreen({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              // Navigate back to the login screen
            },
          ),
        ],
      ),
      body: Center(child: Text('$title Screen — logged in!')),
    );
  }
}

/// Bridges a Bloc's Stream<State> into a Listenable,
/// which is what GoRouter's refreshListenable requires.
class GoRouterRefreshStream extends ChangeNotifier {
  late final Stream<dynamic> _stream;

  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _stream = stream.asBroadcastStream();
    _stream.listen((_) => notifyListeners());
  }
}
