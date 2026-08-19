import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:splitsathi/core/constants/avatar_options.dart';
import 'package:splitsathi/core/di/service_locator.dart';
import 'package:splitsathi/core/router/app_routes.dart';
import 'package:splitsathi/features/auth/bloc/auth_bloc.dart';
import 'package:splitsathi/features/auth/bloc/auth_event.dart';
import 'package:splitsathi/features/profile/repository/profile_repository.dart';
import 'package:splitsathi/services/analytics_service.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = getIt<AuthBloc>().state.user;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text('profile'.tr())),
      body: StreamBuilder<Map<String, dynamic>?>(
        stream: getIt<ProfileRepository>().watchProfile(user?.uid ?? ''),
        builder: (context, snapshot) {
          final avatarId = snapshot.data?['avatarId'] as String?;
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
                          color: colorScheme.primary.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: colorScheme.primary,
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
                    GestureDetector(
                      onTap: () =>
                          _showEditNameDialog(context, user?.uid ?? '', name),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            name,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            Icons.edit_outlined,
                            size: 16,
                            color: colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                        ],
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
              _SettingsTile(
                icon: Icons.info_outline_rounded,
                title: 'about_us'.tr(),
                onTap: () => context.pushNamed(AppRoutes.aboutUsName),
              ),
              _SettingsTile(
                icon: Icons.star_outline_rounded,
                title: 'rate_us'.tr(),
                onTap: _launchPlayStoreReview,
              ),
              _SettingsTile(
                icon: Icons.share_outlined,
                title: 'share_app'.tr(),
                onTap: _shareApp,
              ),
              _SettingsTile(
                icon: Icons.logout_rounded,
                title: 'logout'.tr(),
                onTap: () => _confirmLogout(context),
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
    final colorScheme = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsetsGeometry.all(24),
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
                      getIt<AnalyticsService>().logAvatarChanged();
                      if (sheetContext.mounted) Navigator.pop(sheetContext);
                    },
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? colorScheme.primary.withValues(alpha: 0.2)
                            : colorScheme.surfaceContainerHighest,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? colorScheme.primary
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

  void _showEditNameDialog(
    BuildContext context,
    String userId,
    String currentName,
  ) {
    final controller = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('edit_name'.tr()),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(labelText: 'full_name'.tr()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('cancel'.tr()),
          ),
          TextButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                await getIt<ProfileRepository>().updateName(userId, newName);
              }
              if (dialogContext.mounted) Navigator.pop(dialogContext);
            },
            child: Text('save'.tr()),
          ),
        ],
      ),
    );
  }

  Future<void> _launchPlayStoreReview() async {
    const packageName = 'com.rohan.splitsathi';
    final marketUri = Uri.parse('market://details?id=$packageName');
    final webUri = Uri.parse(
      'https://play.google.com/store/apps/details?id=$packageName',
    );

    if (await canLaunchUrl(marketUri)) {
      await launchUrl(marketUri);
      getIt<AnalyticsService>().logAppRated();
    } else {
      await launchUrl(webUri, mode: LaunchMode.externalApplication);
      getIt<AnalyticsService>().logAppRated();
    }
  }

  Future<void> _shareApp() async {
    const packageName = 'com.rohan.splitsathi';
    await Share.share(
      'Check out SplitSathi — split expenses with friends easily!\nhttps://play.google.com/store/apps/details?id=$packageName',
    );
    getIt<AnalyticsService>().logAppShared();
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('logout'.tr()),
        content: Text('logout_confirm'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('cancel'.tr()),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              getIt<AuthBloc>().add(const AuthLogoutRequested());
            },
            child: Text(
              'logout'.tr(),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
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
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(icon, color: colorScheme.primary),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: colorScheme.onSurface.withValues(alpha: 0.4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
