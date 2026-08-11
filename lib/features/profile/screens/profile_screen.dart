import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:splitsathi/core/constants/avatar_options.dart';
import 'package:splitsathi/core/di/service_locator.dart';
import 'package:splitsathi/core/router/app_routes.dart';
import 'package:splitsathi/core/theme/app_theme.dart';
import 'package:splitsathi/features/auth/bloc/auth_bloc.dart';
import 'package:splitsathi/features/profile/repository/profile_repository.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = getIt<AuthBloc>().state.user;

    return Scaffold(
      appBar: AppBar(title: Text('profile'.tr())),
      body: StreamBuilder<Map<String, dynamic>?>(
        stream: getIt<ProfileRepository>().watchProfile(user?.uid ?? ''),
        builder: (context, snapshot) {
          final avatarId = snapshot.data?['avatarId'] as String;
          final name =
              snapshot.data?['name'] as String? ?? user?.displayName ?? '';
          final email = snapshot.data?['email'] as String? ?? user?.email ?? '';

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Center(
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: () =>
                          _showAvatarPicker(context, user?.uid ?? '', avatarId),
                      child: Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppTheme.primaryColor,
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            AvatarOptions.emojiFor(avatarId),
                            style: const TextStyle(fontSize: 40),
                          ),
                        ),
                      ),
                    ).animate().scale(
                      duration: 300.ms,
                      curve: Curves.easeOutBack,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      name,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(email, style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              _SettingsTile(
                icon: Icons.settings_outlined,
                title: 'settings'.tr(),
                onTap: () => context.pushNamed(AppRoutes.settingsName),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAvatarPicker(
    BuildContext context,
    String userId,
    String? currentAvatarId,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsetsGeometry.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'choose_avatar'.tr(),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 14,
                runSpacing: 14,
                alignment: WrapAlignment.center,
                children: AvatarOptions.options.map((id) {
                  final isSelected = id == currentAvatarId;
                  return GestureDetector(
                    onTap: () async {
                      await getIt<ProfileRepository>().updateAvatar(userId, id);
                      if (sheetContext.mounted) Navigator.pop(sheetContext);
                    },
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.primaryColor.withValues(alpha: 0.2)
                            : Theme.of(
                                context,
                              ).colorScheme.surfaceContainerHighest,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.primaryColor
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          AvatarOptions.emojiMap[id]!,
                          style: const TextStyle(fontSize: 26),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(icon, color: AppTheme.primaryColor),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
                const Icon(Icons.chevron_right_rounded),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
