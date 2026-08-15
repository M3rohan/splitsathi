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
        BlocProvider<HomeSummaryCubit>(
          create: (_) => getIt<HomeSummaryCubit>(),
        ),
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
          title: Text('app_name'.tr()),
          actions: [
            BlocBuilder<NotificationBloc, NotificationState>(
              bloc: getIt<NotificationBloc>(),
              builder: (context, notifState) {
                return Stack(
                  children: [
                    IconButton(
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
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
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
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),

            IconButton(
              icon: const Icon(Icons.person_outline_rounded),
              onPressed: () => context.pushNamed(AppRoutes.profileName),
            ),

            IconButton(
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
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                          'hi_user'.tr(args: [displayName]),
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        )
                        .animate()
                        .fadeIn(duration: 400.ms)
                        .slideX(begin: -0.1, end: 0),

                    const SizedBox(height: 24),

                    BlocBuilder<HomeSummaryCubit, HomeSummaryState>(
                      builder: (context, summaryState) {
                        final isPositive = summaryState.totalBalance >= 0;
                        return Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(24.0),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    AppTheme.primaryColor,
                                    AppTheme.secondaryColor,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.primaryColor.withValues(
                                      alpha: 0.3,
                                    ),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isPositive
                                        ? 'you_are_owed_overall'.tr()
                                        : 'you_owe_overall'.tr(),
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.85,
                                      ),
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  summaryState.isLoading
                                      ? const SizedBox(
                                          height: 36,
                                          width: 36,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : Text(
                                          '₹${summaryState.totalBalance.abs().toStringAsFixed(2)}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 36,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                  const SizedBox(height: 4),
                                  Text(
                                    summaryState.totalBalance.abs() < 0.01
                                        ? 'settled_up'.tr()
                                        : 'across_groups'.tr(),
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.85,
                                      ),
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            )
                            .animate()
                            .fadeIn(delay: 200.ms, duration: 500.ms)
                            .scale(
                              begin: const Offset(0.95, 0.95),
                              end: const Offset(1, 1),
                              curve: Curves.easeOut,
                            );
                      },
                    ),

                    const SizedBox(height: 32),

                    Text(
                      'your_groups'.tr(),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ).animate().fadeIn(delay: 400.ms),

                    const SizedBox(height: 16),

                    BlocBuilder<GroupBloc, GroupState>(
                      builder: (context, state) {
                        if (state.status == GroupStatus.loading ||
                            state.status == GroupStatus.initial) {
                          return const GroupCardShimmer();
                        }

                        if (state.status == GroupStatus.error) {
                          return Container(
                            padding: EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .errorContainer
                                  .withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              children: [
                                Icon(Icons.error_outline_rounded),
                                const SizedBox(height: 8),
                                Text(
                                  'something_went_wrong'.tr(),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 12),
                                TextButton(
                                  onPressed: () {
                                    final userId =
                                        getIt<AuthBloc>().state.user?.uid;
                                    if (userId != null) {
                                      context.read<GroupBloc>().add(
                                        GroupsSubscriptionRequested(userId),
                                      );
                                    }
                                  },
                                  child: Text('retry'.tr()),
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
                                  delay: (400 + index * 80).ms,
                                  duration: 400.ms,
                                )
                                .slideY(begin: 0.1, end: 0);
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
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            context.pushNamed(AppRoutes.createGroupName);
          },

          icon: const Icon(Icons.add),
          label: Text('new_group'.tr()),
        ).animate().fadeIn(delay: 600.ms, curve: Curves.easeOutBack),
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    final authBloc = context.read<AuthBloc>();
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
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        elevation: 1,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => context.pushNamed(
            AppRoutes.groupDetailName,
            pathParameters: {'groupId': group.id},
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      group.emoji ?? GroupIcons.defaultIcon,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        group.name,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${group.memberIds.length} members',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
