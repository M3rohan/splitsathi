import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:splitsathi/core/di/service_locator.dart';
import 'package:splitsathi/core/router/app_routes.dart';
import 'package:splitsathi/core/theme/app_theme.dart';
import 'package:splitsathi/core/theme/theme_cubit.dart';
import 'package:splitsathi/features/auth/bloc/auth_bloc.dart';
import 'package:splitsathi/features/auth/bloc/auth_event.dart';
import 'package:splitsathi/features/auth/repository/auth_repository.dart';
import 'package:splitsathi/features/profile/cubit/settings_cubit.dart';
import 'package:splitsathi/services/analytics_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SettingsCubit>(
      create: (_) => getIt<SettingsCubit>(),
      child: const _SettingsView(),
    );
  }
}

class _SettingsView extends StatelessWidget {
  const _SettingsView();

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColors>()!;

    return Scaffold(
      appBar: AppBar(title: Text('settings'.tr())),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'appearance'.tr(),
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 12),

          BlocBuilder<ThemeCubit, ThemeMode>(
            bloc: getIt<ThemeCubit>(),
            builder: (context, themeMode) {
              return SegmentedButton<ThemeMode>(
                segments: [
                  ButtonSegment(
                    value: ThemeMode.light,
                    label: Text('light'.tr()),
                    icon: const Icon(Icons.light_mode_outlined),
                  ),
                  ButtonSegment(
                    value: ThemeMode.dark,
                    label: Text('dark'.tr()),
                    icon: const Icon(Icons.dark_mode_outlined),
                  ),
                  ButtonSegment(
                    value: ThemeMode.system,
                    label: Text('system'.tr()),
                    icon: const Icon(Icons.settings_suggest_outlined),
                  ),
                ],
                selected: {themeMode},
                onSelectionChanged: (selection) {
                  getIt<ThemeCubit>().setTheme(selection.first);
                  getIt<AnalyticsService>().logThemeChanged(
                    mode: selection.first.name,
                  );
                },
              );
            },
          ),
          const SizedBox(height: 28),
          Text('language'.tr(), style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 12),

          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'en', label: Text('English')),
              ButtonSegment(value: 'hi', label: Text('हिंदी')),
              ButtonSegment(value: 'mr', label: Text('मराठी')),
            ],
            selected: {context.locale.languageCode},
            onSelectionChanged: (selection) {
              context.setLocale(Locale(selection.first));
              getIt<AnalyticsService>().logLanguageChanged(
                language: selection.first,
              );
            },
          ),

          const SizedBox(height: 28),
          Text('security'.tr(), style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 12),

          BlocBuilder<SettingsCubit, SettingsState>(
            builder: (context, state) {
              if (!state.biometricSupported) {
                return Text(
                  'biometric_not_supported'.tr(),
                  style: Theme.of(context).textTheme.bodySmall,
                );
              }
              return SwitchListTile(
                value: state.biometricEnabled,
                onChanged: (value) {
                  context.read<SettingsCubit>().toggleBiometric(value);
                  getIt<AnalyticsService>().logBiometricToggled(enabled: value);
                },
                title: Text('enable_biometric'.tr()),
                subtitle: Text('biometric_hint'.tr()),
                contentPadding: EdgeInsets.zero,
              );
            },
          ),

          const SizedBox(height: 28),
          Text(
            'danger_zone'.tr(),
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(color: appColors.negative),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: appColors.negative,
              side: BorderSide(color: appColors.negative),
            ),
            onPressed: () => _showDeleteAccountFlow(context),
            icon: const Icon(Icons.delete_forever_outlined),
            label: Text('delete_account'.tr()),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountFlow(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColors>()!;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('delete_account'.tr()),
        content: Text('delete_account_warning'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('cancel'.tr()),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _promptPasswordAndDelete(context);
            },
            child: Text(
              'continue_word'.tr(),
              style: TextStyle(color: appColors.negative),
            ),
          ),
        ],
      ),
    );
  }

  void _promptPasswordAndDelete(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColors>()!;
    final passwordController = TextEditingController();
    String? error;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          return AlertDialog(
            title: Text('confirm_password'.tr()),
            content: TextField(
              controller: passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'password'.tr(),
                errorText: error,
              ),
            ),

            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text('cancel'.tr()),
              ),
              TextButton(
                onPressed: () async {
                  try {
                    await getIt<AuthRepository>().reauthenticate(
                      passwordController.text,
                    );
                    await getIt<AuthRepository>().deleteAccount();
                    getIt<AuthBloc>().add(const AuthLogoutRequested());
                    getIt<AnalyticsService>().logAccountDeleted();
                    if (dialogContext.mounted) Navigator.pop(dialogContext);
                    if (context.mounted) context.goNamed(AppRoutes.loginName);
                  } catch (e) {
                    setDialogState(() => error = 'incorrect_password'.tr());
                  }
                },
                child: Text(
                  'delete'.tr(),
                  style: TextStyle(color: appColors.negative),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
