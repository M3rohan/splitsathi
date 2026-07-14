import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:splitsathi/core/router/app_routes.dart';
import 'package:splitsathi/core/router/route_transitions.dart';
import 'package:splitsathi/features/auth/screens/login_screen.dart';
import 'package:splitsathi/features/auth/screens/signup_screen.dart';

class AppRouter {
  AppRouter._();

  static final GoRouter router = GoRouter(
    initialLocation: AppRoutes.login,
    debugLogDiagnostics: true,
    routes: [
      // GoRoute(
      //   path: AppRoutes.splash,
      //   name: AppRoutes.splashName,
      //   pageBuilder: (context, state) => buildPageWithTransition(
      //     context: context,
      //     state: state,
      //     child: const _PlaceholderScreen(title: 'Splash'),
      //   ),
      // ),
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
          child: const _PlaceholderScreen(title: 'Home'),
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
            child: _PlaceholderScreen(title: 'Group Detail: $groupId'),
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
