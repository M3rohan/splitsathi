import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:splitsathi/core/di/service_locator.dart';
import 'package:splitsathi/core/router/app_routes.dart';
import 'package:splitsathi/core/router/route_transitions.dart';
import 'package:splitsathi/features/auth/bloc/auth_bloc.dart';
import 'package:splitsathi/features/auth/bloc/auth_state.dart';
import 'package:splitsathi/features/auth/screens/login_screen.dart';
import 'package:splitsathi/features/auth/screens/signup_screen.dart';
import 'package:splitsathi/features/groups/screens/create_group_screen.dart';
import 'package:splitsathi/features/groups/screens/group_detail_screen.dart';
import 'package:splitsathi/features/home/screens/home_screen.dart';
import 'package:splitsathi/features/onboarding/screens/splash_screen.dart';

class AppRouter {
  AppRouter._();

  static final GoRouter router = GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    refreshListenable: GoRouterRefreshStream(getIt<AuthBloc>().stream),
    redirect: (context, state) {
      final authState = getIt<AuthBloc>().state;
      final isAuthenticated = authState.status == AuthStatus.authenticated;
      final isGoingToSplash = state.matchedLocation == AppRoutes.splash;
      final isGoingToAuth =
          state.matchedLocation == AppRoutes.login ||
          state.matchedLocation == AppRoutes.signup;

      // Let splash screen handle its own initial routing logic
      if (isGoingToSplash) return null;

      // Logged in but trying to visit login/signup → send to home
      if (isAuthenticated && isGoingToAuth) return AppRoutes.home;

      // Not logged in and trying to visit a protected route → send to login
      if (!isAuthenticated &&
          authState.status != AuthStatus.initial &&
          authState.status != AuthStatus.loading &&
          !isGoingToAuth) {
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
          child: const _PlaceholderScreen(title: 'Profile'),
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
