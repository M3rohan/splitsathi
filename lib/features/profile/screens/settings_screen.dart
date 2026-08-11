import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:splitsathi/core/di/service_locator.dart';
import 'package:splitsathi/core/theme/theme_cubit.dart';
import 'package:splitsathi/features/profile/cubit/settings_cubit.dart';

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
                onSelectionChanged: (selection) =>
                    getIt<ThemeCubit>().setTheme(selection.first),
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
            onSelectionChanged: (selection) =>
                context.setLocale(Locale(selection.first)),
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
                onChanged: (value) =>
                    context.read<SettingsCubit>().toggleBiometric(value),
                title: Text('enable_biometric'.tr()),
                subtitle: Text('biometric_hint'.tr()),
                contentPadding: EdgeInsets.zero,
              );
            },
          ),
        ],
      ),
    );
  }
}
