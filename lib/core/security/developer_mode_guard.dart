import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../router/app_router.dart';
import '../theme/app_theme.dart';

class DeveloperModeGuard extends StatefulWidget {
  final Widget child;
  const DeveloperModeGuard({super.key, required this.child});

  @override
  State<DeveloperModeGuard> createState() => _DeveloperModeGuardState();
}

class _DeveloperModeGuardState extends State<DeveloperModeGuard>
    with WidgetsBindingObserver {
  static const _platform = MethodChannel('com.rohan.splitsathi/settings');
  static const _dismissedKey = 'dev_mode_warning_dismissed';
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) _checkDeveloperMode();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _overlayEntry?.remove();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkDeveloperMode();
    }
  }

  Future<bool> _isDeveloperModeEnabled() async {
    if (!Platform.isAndroid) return false;
    try {
      final result = await _platform.invokeMethod<bool>(
        'isDeveloperModeEnabled',
      );
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<void> _checkDeveloperMode() async {
    final isDevMode = await _isDeveloperModeEnabled();
    final prefs = await SharedPreferences.getInstance();

    if (!isDevMode) {
      await prefs.remove(_dismissedKey);
      return;
    }

    final alreadyDismissed = prefs.getBool(_dismissedKey) ?? false;
    if (!alreadyDismissed && _overlayEntry == null) {
      _showOverlayWarning();
    }
  }

  void _showOverlayWarning() {
    final navigatorState = AppRouter.rootNavigatorKey.currentState;
    final overlayState = navigatorState?.overlay;
    if (overlayState == null) return;

    final navigatorContext = AppRouter.rootNavigatorKey.currentContext;
    if (navigatorContext == null) return;
    final theme = Theme.of(navigatorContext);
    final appColors = theme.extension<AppColors>()!;

    _overlayEntry = OverlayEntry(
      builder: (overlayContext) {
        return Positioned.fill(
          child: Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  onTap: () {},
                  child: Container(color: Colors.black.withValues(alpha: 0.35)),
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Material(
                  color: Colors.transparent,
                  child: SafeArea(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(24),
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 16,
                            offset: Offset(0, -4),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 40,
                            height: 4,
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.2,
                              ),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          Icon(
                            Icons.info_outline_rounded,
                            size: 44,
                            color: appColors.warning,
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'developer_mode_title'.tr(),
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'developer_mode_message_soft'.tr(),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.7,
                              ),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: () => _platform.invokeMethod(
                                'openDeveloperOptions',
                              ),
                              child: Text('go_to_settings'.tr()),
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: TextButton(
                              onPressed: _dismissOverlay,
                              child: Text('dismiss'.tr()),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );

    overlayState.insert(_overlayEntry!);
  }

  Future<void> _dismissOverlay() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_dismissedKey, true);
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
