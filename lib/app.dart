import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:splitsathi/core/security/developer_mode_guard.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_cubit.dart';
import 'core/router/app_router.dart';
import 'core/di/service_locator.dart';
import 'core/utils/connectivity_cubit.dart';

final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

class SplitSathiApp extends StatelessWidget {
  const SplitSathiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [BlocProvider<ThemeCubit>(create: (_) => getIt<ThemeCubit>())],
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, themeMode) {
          return _ConnectivityListener(
            child: DeveloperModeGuard(
              child: MaterialApp.router(
                title: 'SplitSathi',
                debugShowCheckedModeBanner: false,
                scaffoldMessengerKey: scaffoldMessengerKey,
                theme: AppTheme.lightTheme,
                darkTheme: AppTheme.darkTheme,
                themeMode: themeMode,
                localizationsDelegates: context.localizationDelegates,
                supportedLocales: context.supportedLocales,
                locale: context.locale,
                routerConfig: AppRouter.router,
                // builder: (context, child) {
                //   return DeveloperModeGuard(
                //     child: child ?? const SizedBox.shrink(),
                //   );
                // },
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Listens to connectivity globally and shows/hides a persistent
/// Snackbar via the app-wide ScaffoldMessengerKey — works on every
/// screen without needing to embed anything screen-by-screen.
class _ConnectivityListener extends StatefulWidget {
  final Widget child;
  const _ConnectivityListener({required this.child});

  @override
  State<_ConnectivityListener> createState() => _ConnectivityListenerState();
}

class _ConnectivityListenerState extends State<_ConnectivityListener> {
  bool _isShowingOfflineSnackbar = false;

  @override
  void initState() {
    super.initState();
    getIt<ConnectivityCubit>().stream.listen(_handleConnectivityChange);
  }

  void _handleConnectivityChange(bool isOnline) {
    final messenger = scaffoldMessengerKey.currentState;
    if (messenger == null) return;

    if (!isOnline && !_isShowingOfflineSnackbar) {
      _isShowingOfflineSnackbar = true;
      messenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.cloud_off_rounded, size: 16, color: Colors.white),
              SizedBox(width: 8),
              Expanded(child: Text('offline_message'.tr())),
            ],
          ),
          backgroundColor: Colors.orange.shade700,
          duration: const Duration(days: 1),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } else if (isOnline && _isShowingOfflineSnackbar) {
      _isShowingOfflineSnackbar = false;
      messenger.hideCurrentSnackBar();
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
