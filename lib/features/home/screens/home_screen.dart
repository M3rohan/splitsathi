import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:splitsathi/core/constants/group_icons.dart';
import 'package:splitsathi/core/di/service_locator.dart';
import 'package:splitsathi/core/router/app_routes.dart';
import 'package:splitsathi/core/theme/app_theme.dart';
import 'package:splitsathi/features/auth/bloc/auth_bloc.dart';
import 'package:splitsathi/features/auth/bloc/auth_event.dart';
import 'package:splitsathi/features/groups/bloc/group_bloc.dart';
import 'package:splitsathi/features/groups/bloc/group_event.dart';
import 'package:splitsathi/features/groups/bloc/group_state.dart';
import 'package:splitsathi/features/groups/models/group_model.dart';
import 'package:splitsathi/features/home/cubit/home_summary_cubit.dart';
import 'package:splitsathi/features/notifications/bloc/notification_bloc.dart';
import 'package:splitsathi/features/notifications/bloc/notification_event.dart';
import 'package:splitsathi/features/notifications/bloc/notification_state.dart';
import 'package:splitsathi/features/profile/repository/profile_repository.dart';
import 'package:splitsathi/widgets/empty_state.dart';
import 'package:splitsathi/widgets/loading_shimmer.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>.value(value: getIt<AuthBloc>()),
        BlocProvider<GroupBloc>.value(value: getIt<GroupBloc>()),
        BlocProvider<HomeSummaryCubit>.value(value: getIt<HomeSummaryCubit>()),
      ],
      child: const _HomeView(),
    );
  }
}

class _HomeView extends StatefulWidget {
  const _HomeView();

  @override
  State<_HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<_HomeView> {
  @override
  void initState() {
    super.initState();
    final userId = getIt<AuthBloc>().state.user?.uid;
    if (userId != null) {
      context.read<GroupBloc>().add(GroupsSubscriptionRequested(userId));
      getIt<NotificationBloc>().add(NotificationsSubscriptionRequested(userId));
    }
  }

  @override
  Widget build(final BuildContext context) {
    final user = getIt<AuthBloc>().state.user;
    final userId = user?.uid ?? '';
    final appColors = Theme.of(context).extension<AppColors>()!;
    final colorScheme = Theme.of(context).colorScheme;

    return BlocListener<GroupBloc, GroupState>(
      listener: (context, groupState) {
        if (groupState.status == GroupStatus.loaded) {
          context.read<HomeSummaryCubit>().updateGroups(
            groupState.groups,
            userId,
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          scrolledUnderElevation: 0,
          titleSpacing: 20,
          title: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.account_balance_wallet_rounded,
                  size: 21,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'app_name'.tr(),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          actions: [
            BlocBuilder<NotificationBloc, NotificationState>(
              bloc: getIt<NotificationBloc>(),
              builder: (context, notifState) {
                return Stack(
                  children: [
                    IconButton(
                      tooltip: 'Notifications',
                      style: IconButton.styleFrom(
                        backgroundColor: colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.55),
                      ),
                      icon: const Icon(Icons.notifications_outlined),
                      onPressed: () =>
                          context.pushNamed(AppRoutes.notificationsName),
                    ),

                    if (notifState.unreadCount > 0)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: appColors.negative,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Theme.of(context).scaffoldBackgroundColor,
                              width: 1.5,
                            ),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            '${notifState.unreadCount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),

            const SizedBox(width: 4),
            IconButton(
              tooltip: 'Profile',
              style: IconButton.styleFrom(
                backgroundColor: colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.55,
                ),
              ),
              icon: const Icon(Icons.person_outline_rounded),
              onPressed: () => context.pushNamed(AppRoutes.profileName),
            ),

            IconButton(
              tooltip: 'Logout',
              style: IconButton.styleFrom(
                backgroundColor: colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.55,
                ),
              ),
              icon: const Icon(Icons.logout_rounded),
              onPressed: () {
                _confirmLogout(context);
              },
            ),
          ],
        ),
        body: StreamBuilder<Map<String, dynamic>?>(
          stream: getIt<ProfileRepository>().watchProfile(user?.uid ?? ''),
          builder: (context, asyncSnapshot) {
            final displayName =
                asyncSnapshot.data?['name'] as String? ??
                user?.displayName ??
                '';
            return RefreshIndicator(
              onRefresh: () async {
                final userId = getIt<AuthBloc>().state.user?.uid;
                if (userId != null) {
                  context.read<GroupBloc>().add(
                    GroupsSubscriptionRequested(userId),
                  );
                }
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                          decoration: BoxDecoration(
                            color: colorScheme.surface,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: colorScheme.outlineVariant.withValues(
                                alpha: 0.35,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 46,
                                height: 46,
                                decoration: BoxDecoration(
                                  color: colorScheme.primary.withValues(
                                    alpha: 0.12,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.waving_hand_rounded,
                                  color: colorScheme.primary,
                                  size: 23,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'hi_user'.tr(args: [displayName]),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: -0.4,
                                          ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      'your_groups'.tr(),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        )
                        .animate()
                        .fadeIn(duration: 500.ms, curve: Curves.easeOut)
                        .slideX(
                          begin: -0.08,
                          end: 0,
                          duration: 500.ms,
                          curve: Curves.easeOutCubic,
                        )
                        .scale(
                          begin: const Offset(0.97, 0.97),
                          end: const Offset(1, 1),
                          duration: 500.ms,
                          curve: Curves.easeOutCubic,
                        ),

                    const SizedBox(height: 18),

                    BlocBuilder<HomeSummaryCubit, HomeSummaryState>(
                      builder: (context, summaryState) {
                        final isPositive = summaryState.totalBalance >= 0;
                        return Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(22),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    appColors.cardGradientStart,
                                    appColors.cardGradientEnd,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: appColors.cardGradientStart
                                        .withValues(alpha: 0.24),
                                    blurRadius: 28,
                                    spreadRadius: -4,
                                    offset: const Offset(0, 12),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(
                                            alpha: 0.16,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            13,
                                          ),
                                        ),
                                        child: Icon(
                                          isPositive
                                              ? Icons.arrow_downward_rounded
                                              : Icons.arrow_upward_rounded,
                                          color: Colors.white,
                                          size: 21,
                                        ),
                                      ),
                                      const Spacer(),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(
                                            alpha: 0.12,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        child: Text(
                                          isPositive ? 'IN' : 'OUT',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 0.8,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 18),
                                  Text(
                                    isPositive
                                        ? 'you_are_owed_overall'.tr()
                                        : 'you_owe_overall'.tr(),
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.78,
                                      ),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  summaryState.isLoading
                                      ? const SizedBox(
                                          height: 42,
                                          width: 42,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            color: Colors.white,
                                          ),
                                        )
                                      : FittedBox(
                                          fit: BoxFit.scaleDown,
                                          alignment: Alignment.centerLeft,
                                          child: Text(
                                            '₹${summaryState.totalBalance.abs().toStringAsFixed(2)}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 38,
                                              height: 1.1,
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: -1,
                                            ),
                                          ),
                                        ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Icon(
                                        summaryState.totalBalance.abs() < 0.01
                                            ? Icons.check_circle_rounded
                                            : Icons.groups_rounded,
                                        color: Colors.white.withValues(
                                          alpha: 0.82,
                                        ),
                                        size: 16,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        summaryState.totalBalance.abs() < 0.01
                                            ? 'settled_up'.tr()
                                            : 'across_groups'.tr(),
                                        style: TextStyle(
                                          color: Colors.white.withValues(
                                            alpha: 0.82,
                                          ),
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            )
                            .animate()
                            .fadeIn(
                              delay: 150.ms,
                              duration: 550.ms,
                              curve: Curves.easeOut,
                            )
                            .slideY(
                              begin: 0.08,
                              end: 0,
                              delay: 150.ms,
                              duration: 550.ms,
                              curve: Curves.easeOutCubic,
                            )
                            .scale(
                              begin: const Offset(0.94, 0.94),
                              end: const Offset(1, 1),
                              delay: 150.ms,
                              duration: 550.ms,
                              curve: Curves.easeOutBack,
                            );
                      },
                    ),

                    const SizedBox(height: 32),

                    Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'your_groups'.tr(),
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: -0.3,
                                        ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    'create_group_hint'.tr(),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(9),
                              decoration: BoxDecoration(
                                color: colorScheme.primary.withValues(
                                  alpha: 0.10,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.groups_rounded,
                                size: 19,
                                color: colorScheme.primary,
                              ),
                            ),
                          ],
                        )
                        .animate()
                        .fadeIn(
                          delay: 350.ms,
                          duration: 450.ms,
                          curve: Curves.easeOut,
                        )
                        .slideX(
                          begin: -0.05,
                          end: 0,
                          delay: 350.ms,
                          duration: 450.ms,
                          curve: Curves.easeOutCubic,
                        ),

                    const SizedBox(height: 14),

                    BlocBuilder<GroupBloc, GroupState>(
                      builder: (context, state) {
                        if (state.status == GroupStatus.loading ||
                            state.status == GroupStatus.initial) {
                          return const GroupCardShimmer();
                        }

                        if (state.status == GroupStatus.error) {
                          return Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(22),
                            decoration: BoxDecoration(
                              color: colorScheme.errorContainer.withValues(
                                alpha: 0.35,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: appColors.negative.withValues(
                                  alpha: 0.16,
                                ),
                              ),
                            ),
                            child: Column(
                              children: [
                                Container(
                                  width: 46,
                                  height: 46,
                                  decoration: BoxDecoration(
                                    color: appColors.negative.withValues(
                                      alpha: 0.10,
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.error_outline_rounded,
                                    color: appColors.negative,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'something_went_wrong'.tr(),
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.titleSmall
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'create_group_hint'.tr(),
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                ),
                                const SizedBox(height: 12),
                                TextButton.icon(
                                  onPressed: () {
                                    final userId =
                                        getIt<AuthBloc>().state.user?.uid;
                                    if (userId != null) {
                                      context.read<GroupBloc>().add(
                                        GroupsSubscriptionRequested(userId),
                                      );
                                    }
                                  },
                                  icon: const Icon(Icons.refresh_rounded),
                                  label: Text('retry'.tr()),
                                ),
                              ],
                            ),
                          );
                        }

                        if (state.groups.isEmpty) {
                          return EmptyStateWidget(
                            title: 'no_groups_yet'.tr(),
                            subtitle: 'create_group_hint'.tr(),
                          );
                        }
                        return Column(
                          children: List.generate(state.groups.length, (index) {
                            final group = state.groups[index];
                            return _GroupCard(group: group)
                                .animate()
                                .fadeIn(
                                  delay: (450 + index * 90).ms,
                                  duration: 450.ms,
                                  curve: Curves.easeOut,
                                )
                                .slideY(
                                  begin: 0.08,
                                  end: 0,
                                  delay: (450 + index * 90).ms,
                                  duration: 450.ms,
                                  curve: Curves.easeOutCubic,
                                )
                                .scale(
                                  begin: const Offset(0.96, 0.96),
                                  end: const Offset(1, 1),
                                  delay: (450 + index * 90).ms,
                                  duration: 450.ms,
                                  curve: Curves.easeOutCubic,
                                );
                          }),
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        floatingActionButton:
            FloatingActionButton.extended(
                  elevation: 6,
                  onPressed: () {
                    context.pushNamed(AppRoutes.createGroupName);
                  },
                  icon: const Icon(Icons.add_rounded),
                  label: Text(
                    'new_group'.tr(),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                )
                .animate()
                .fadeIn(delay: 850.ms, duration: 400.ms, curve: Curves.easeOut)
                .slideY(
                  begin: 0.35,
                  end: 0,
                  delay: 850.ms,
                  duration: 500.ms,
                  curve: Curves.easeOutBack,
                )
                .scale(
                  begin: const Offset(0.82, 0.82),
                  end: const Offset(1, 1),
                  delay: 850.ms,
                  duration: 500.ms,
                  curve: Curves.easeOutBack,
                ),
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    final authBloc = context.read<AuthBloc>();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.error.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.logout_rounded,
                color: Theme.of(context).colorScheme.error,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text('logout'.tr())),
          ],
        ),
        content: Text(
          'logout_confirm'.tr(),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.45),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('cancel'.tr()),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              if (!authBloc.isClosed) {
                authBloc.add(const AuthLogoutRequested());
              }
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

class _GroupCard extends StatelessWidget {
  final GroupModel group;
  const _GroupCard({required this.group});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        elevation: 0,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          splashColor: colorScheme.primary.withValues(alpha: 0.06),
          highlightColor: colorScheme.primary.withValues(alpha: 0.04),
          onTap: () => context.pushNamed(
            AppRoutes.groupDetailName,
            pathParameters: {'groupId': group.id},
          ),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.38),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        colorScheme.primary.withValues(alpha: 0.16),
                        colorScheme.primary.withValues(alpha: 0.07),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(17),
                  ),
                  child: Center(
                    child: Text(
                      group.emoji ?? GroupIcons.defaultIcon,
                      style: const TextStyle(fontSize: 27),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                            ),
                      ),
                      const SizedBox(height: 7),
                      Row(
                        children: [
                          Icon(
                            Icons.people_alt_outlined,
                            size: 15,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            '${group.memberIds.length} members',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.65,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
