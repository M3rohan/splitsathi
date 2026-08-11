import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:splitsathi/core/di/service_locator.dart';
import 'package:splitsathi/core/router/app_routes.dart';
import 'package:splitsathi/core/theme/app_theme.dart';
import 'package:splitsathi/features/auth/bloc/auth_bloc.dart';
import 'package:splitsathi/features/auth/bloc/auth_event.dart';
import 'package:splitsathi/features/auth/bloc/auth_state.dart';
import 'package:splitsathi/widgets/animated_dots.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AuthBloc>.value(
      value: getIt<AuthBloc>()..add(const AuthCheckRequested()),
      child: const _SplashView(),
    );
  }
}

class _SplashView extends StatefulWidget {
  const _SplashView();

  @override
  State<_SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<_SplashView> {
  AuthState? _pendingState;
  bool _minimumTimeElapsed = false;

  @override
  void initState() {
    super.initState();

    Future.delayed(const Duration(milliseconds: 2200), () {
      if (!mounted) return;
      setState(() => _minimumTimeElapsed = true);
      _navigateIfReady();
    });
  }

  void _navigateIfReady() {
    if (_minimumTimeElapsed && _pendingState != null) {
      final state = _pendingState!;
      if (state.status == AuthStatus.authenticated) {
        context.goNamed(AppRoutes.homeName);
      } else if (state.status == AuthStatus.unauthenticated) {
        context.goNamed(AppRoutes.loginName);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        _pendingState = state;
        _navigateIfReady();
      },
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryColor.withValues(alpha: 0.35),
                          blurRadius: 35,
                          spreadRadius: 6,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Image.asset(
                        'assets/images/app_icon.png',
                        width: 120,
                        height: 120,
                        fit: BoxFit.cover,
                      ),
                    ),
                  )
                  .animate()
                  .fadeIn(duration: 400.ms)
                  .scale(
                    begin: const Offset(0.8, 0.8),
                    end: const Offset(1, 1),
                    curve: Curves.easeOutBack,
                  )
                  .then()
                  .shimmer(duration: 1200.ms),
              const SizedBox(height: 24),
              Text(
                    'app_name'.tr(),
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  )
                  .animate()
                  .fadeIn(delay: 300.ms, duration: 500.ms)
                  .slideY(begin: 0.3, end: 0, curve: Curves.easeOut),
              const SizedBox(height: 8),
              Text(
                'tagline'.tr(),
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ).animate().fadeIn(delay: 500.ms, duration: 500.ms),
              const SizedBox(height: 60),
              const AnimatedDots().animate().fadeIn(delay: 700.ms),
            ],
          ),
        ),
      ),
    );
  }
}
