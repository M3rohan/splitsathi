import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:splitsathi/core/constants/group_icons.dart';
import 'package:splitsathi/core/security/biometric_guard.dart';
import 'package:splitsathi/features/expenses/repository/expense_repository.dart';
import 'package:splitsathi/features/groups/repository/group_repository.dart';
import 'package:splitsathi/services/analytics_service.dart';
import 'package:splitsathi/widgets/empty_state.dart';
import '../cubit/group_detail_cubit.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/constants/expense_categories.dart';
import '../../auth/bloc/auth_bloc.dart';

class GroupDetailScreen extends StatelessWidget {
  final String groupId;

  const GroupDetailScreen({super.key, required this.groupId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<GroupDetailCubit>(
      create: (_) => getIt<GroupDetailCubit>()..watchGroup(groupId),
      child: const _GroupDetailView(),
    );
  }
}

class _GroupDetailView extends StatelessWidget {
  const _GroupDetailView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GroupDetailCubit, GroupDetailState>(
      builder: (context, state) {
        if (state.status == GroupDetailStatus.loading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (state.status == GroupDetailStatus.notFound ||
            state.status == GroupDetailStatus.error) {
          return Scaffold(
            appBar: AppBar(),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'group_not_found'.tr(),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }

        final group = state.group!;
        final currentUserId = getIt<AuthBloc>().state.user?.uid ?? '';

        final myBalance = state.netBalances[currentUserId] ?? 0.0;

        final isPositive = myBalance >= 0;

        final appColors = Theme.of(context).extension<AppColors>()!;

        final colorScheme = Theme.of(context).colorScheme;

        String nameFor(String uid) {
          final m = state.members.firstWhere(
            (m) => m['uid'] == uid,
            orElse: () => {'name': '?'},
          );

          return (m['name'] as String?)?.isNotEmpty == true
              ? m['name']
              : (m['email'] ?? '?');
        }

        final groupTotal = state.expenses.fold(
          0.0,
          (sum, expense) => sum + expense.amount,
        );

        return Scaffold(
          appBar: AppBar(
            elevation: 0,
            scrolledUnderElevation: 0,
            titleSpacing: 16,
            title: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      group.emoji ?? GroupIcons.defaultIcon,
                      style: const TextStyle(fontSize: 21),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    group.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.pie_chart_outline_rounded),
                tooltip: 'insights'.tr(),
                onPressed: () => context.pushNamed(
                  AppRoutes.insightsName,
                  pathParameters: {'groupId': group.id},
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) async {
                  if (value == 'delete') {
                    final allowed = await BiometricGuard.checkAccess(
                      reason: 'Authenticate to delete this group',
                    );

                    if (!allowed) return;

                    if (context.mounted) {
                      _confirmDeleteGroup(context, group.id);
                    }
                  } else if (value == 'leave') {
                    _confirmLeaveGroup(context, group.id, currentUserId);
                  }
                },
                itemBuilder: (context) {
                  final isCreator = currentUserId == group.createdBy;

                  return [
                    if (!isCreator)
                      PopupMenuItem(
                        value: 'leave',
                        child: Text('leave_group'.tr()),
                      ),
                    if (isCreator)
                      PopupMenuItem(
                        value: 'delete',
                        child: Text('delete_group'.tr()),
                      ),
                  ];
                },
              ),
            ],
          ),

          body: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.fromLTRB(
              20,
              12,
              20,
              MediaQuery.of(context).viewInsets.bottom + 110,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
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
                            color: appColors.cardGradientStart.withValues(
                              alpha: 0.28,
                            ),
                            blurRadius: 24,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.14),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Icon(
                                  isPositive
                                      ? Icons.arrow_downward_rounded
                                      : Icons.arrow_upward_rounded,
                                  color: Colors.white,
                                  size: 23,
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 11,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  isPositive ? 'OWED' : 'OWE',
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
                            isPositive ? 'you_are_owed'.tr() : 'you_owe'.tr(),
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.78),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),

                          const SizedBox(height: 5),

                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              '₹${myBalance.abs().toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 38,
                                height: 1.1,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -1,
                              ),
                            ),
                          ),

                          const SizedBox(height: 8),

                          Text(
                            state.expenses.isEmpty
                                ? 'no_expenses_yet'.tr()
                                : 'group_total'.tr(
                                    args: [groupTotal.toStringAsFixed(2)],
                                  ),
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.78),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    )
                    .animate()
                    .fadeIn(duration: 500.ms, curve: Curves.easeOut)
                    .slideY(
                      begin: 0.07,
                      end: 0,
                      duration: 500.ms,
                      curve: Curves.easeOutCubic,
                    )
                    .scale(
                      begin: const Offset(0.94, 0.94),
                      end: const Offset(1, 1),
                      duration: 500.ms,
                      curve: Curves.easeOutBack,
                    ),

                const SizedBox(height: 22),

                if (state.dueRecurringExpenses.isNotEmpty)
                  Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 18),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: appColors.warning.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: appColors.warning.withValues(alpha: 0.28),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: appColors.warning.withValues(
                                  alpha: 0.14,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.notifications_active_rounded,
                                color: appColors.warning,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'recurring_due'.tr(
                                  args: [
                                    state.dueRecurringExpenses.length
                                        .toString(),
                                  ],
                                ),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                      .animate()
                      .fadeIn(duration: 400.ms)
                      .slideY(begin: 0.05, end: 0, duration: 400.ms),

                if (state.settlements.isNotEmpty) ...[
                  Text(
                        'suggested_settlements'.tr(),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      )
                      .animate()
                      .fadeIn(delay: 150.ms, duration: 400.ms)
                      .slideX(
                        begin: -0.04,
                        end: 0,
                        delay: 150.ms,
                        duration: 400.ms,
                      ),

                  const SizedBox(height: 12),

                  ...List.generate(state.settlements.length, (index) {
                    final s = state.settlements[index];

                    return Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.40),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: colorScheme.outlineVariant.withValues(
                                alpha: 0.25,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: colorScheme.primary.withValues(
                                    alpha: 0.10,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 18,
                                  color: colorScheme.primary,
                                ),
                              ),

                              const SizedBox(width: 10),

                              Expanded(
                                child: Text(
                                  '${nameFor(s.fromUserId)} → ${nameFor(s.toUserId)}',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(fontWeight: FontWeight.w600),
                                ),
                              ),

                              const SizedBox(width: 10),

                              Flexible(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    '₹${s.amount.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: colorScheme.primary,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                        .animate()
                        .fadeIn(delay: (200 + index * 60).ms, duration: 350.ms)
                        .slideX(
                          begin: -0.05,
                          end: 0,
                          delay: (200 + index * 60).ms,
                          duration: 350.ms,
                          curve: Curves.easeOutCubic,
                        );
                  }),

                  const SizedBox(height: 18),
                ],

                Text(
                      'members'.tr(),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    )
                    .animate()
                    .fadeIn(delay: 250.ms, duration: 400.ms)
                    .slideX(
                      begin: -0.04,
                      end: 0,
                      delay: 250.ms,
                      duration: 400.ms,
                    ),

                const SizedBox(height: 12),

                ...List.generate(state.members.length, (index) {
                  final member = state.members[index];

                  final isYou = member['uid'] == currentUserId;

                  final isCreator = member['uid'] == group.createdBy;

                  final currentUserIsCreator = currentUserId == group.createdBy;

                  final memberBalance = state.netBalances[member['uid']];

                  final memberName =
                      (member['name'] as String?)?.isNotEmpty == true
                      ? member['name']
                      : member['email'] ?? '';

                  return Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(13),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest.withValues(
                            alpha: 0.40,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: colorScheme.outlineVariant.withValues(
                              alpha: 0.25,
                            ),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            CircleAvatar(
                              radius: 21,
                              backgroundColor: colorScheme.primary.withValues(
                                alpha: 0.13,
                              ),
                              child: Text(
                                memberName.isNotEmpty
                                    ? memberName[0].toUpperCase()
                                    : '?',
                                style: TextStyle(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),

                            const SizedBox(width: 12),

                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          isYou
                                              ? '$memberName (${'you'.tr()})'
                                              : memberName,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                      ),
                                    ],
                                  ),

                                  if (member['email'] != null)
                                    Text(
                                      member['email'],
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall,
                                    ),

                                  if (memberBalance != null) ...[
                                    const SizedBox(height: 3),
                                    Text(
                                      '${memberBalance >= 0 ? '+' : ''}'
                                      '₹${memberBalance.toStringAsFixed(0)}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: memberBalance >= 0
                                            ? appColors.positive
                                            : appColors.negative,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),

                            const SizedBox(width: 12),

                            SizedBox(
                              width: 40,
                              height: 40,
                              child: isCreator
                                  ? Center(
                                      child: Icon(
                                        Icons.star_rounded,
                                        size: 22,
                                        color: appColors.warning,
                                      ),
                                    )
                                  : currentUserIsCreator && !isYou
                                  ? IconButton(
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      tooltip: 'Remove member',
                                      icon: const Icon(
                                        Icons.person_remove_outlined,
                                        size: 20,
                                      ),
                                      onPressed: () => _confirmRemoveMember(
                                        context,
                                        group.id,
                                        member['uid'],
                                        member['name'] ?? '',
                                      ),
                                    )
                                  : const SizedBox.shrink(),
                            ),
                          ],
                        ),
                      )
                      .animate()
                      .fadeIn(delay: (300 + index * 60).ms, duration: 350.ms)
                      .slideX(
                        begin: -0.05,
                        end: 0,
                        delay: (300 + index * 60).ms,
                        duration: 350.ms,
                        curve: Curves.easeOutCubic,
                      );
                }),

                const SizedBox(height: 28),

                Text(
                      'expenses'.tr(),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    )
                    .animate()
                    .fadeIn(delay: 500.ms, duration: 400.ms)
                    .slideX(
                      begin: -0.04,
                      end: 0,
                      delay: 500.ms,
                      duration: 400.ms,
                    ),

                const SizedBox(height: 12),

                if (state.expenses.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: EmptyStateWidget(
                      title: 'no_expenses_added'.tr(),
                      size: 100,
                    ),
                  )
                else
                  ...List.generate(state.expenses.length, (index) {
                    final expense = state.expenses[index];

                    final payerName = nameFor(expense.paidBy);

                    return GestureDetector(
                      onLongPress: () async {
                        final allowed = await BiometricGuard.checkAccess(
                          reason: 'Authenticate to delete this expense',
                        );

                        if (!allowed) return;

                        if (context.mounted) {
                          await getIt<ExpenseRepository>().deleteExpense(
                            group.id,
                            expense.id,
                          );
                        }
                      },
                      child:
                          Container(
                                width: double.infinity,
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.all(13),
                                decoration: BoxDecoration(
                                  color: colorScheme.surfaceContainerHighest
                                      .withValues(alpha: 0.40),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: colorScheme.outlineVariant
                                        .withValues(alpha: 0.25),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 42,
                                      height: 42,
                                      decoration: BoxDecoration(
                                        color: colorScheme.primary.withValues(
                                          alpha: 0.10,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        ExpenseCategories.iconForId(
                                          expense.category,
                                        ),
                                        color: colorScheme.primary,
                                        size: 20,
                                      ),
                                    ),

                                    const SizedBox(width: 12),

                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            expense.description,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            'paid_by_name'.tr(
                                              args: [payerName],
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: Theme.of(
                                              context,
                                            ).textTheme.bodySmall,
                                          ),
                                        ],
                                      ),
                                    ),

                                    const SizedBox(width: 10),

                                    Flexible(
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        alignment: Alignment.centerRight,
                                        child: Text(
                                          '₹${expense.amount.toStringAsFixed(2)}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                              .animate()
                              .fadeIn(
                                delay: (600 + index * 60).ms,
                                duration: 350.ms,
                              )
                              .slideY(
                                begin: 0.04,
                                end: 0,
                                delay: (600 + index * 60).ms,
                                duration: 350.ms,
                                curve: Curves.easeOutCubic,
                              ),
                    );
                  }),
              ],
            ),
          ),

          floatingActionButton:
              FloatingActionButton.extended(
                    elevation: 6,
                    onPressed: () {
                      final uid = getIt<AuthBloc>().state.user?.uid;

                      if (uid == null) return;

                      context.pushNamed(
                        AppRoutes.addExpenseName,
                        pathParameters: {'groupId': group.id},
                        extra: {
                          'groupName': group.name,
                          'members': state.members,
                          'currentUserId': uid,
                        },
                      );
                    },
                    icon: const Icon(Icons.add_rounded),
                    label: Text(
                      'add_expense'.tr(),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  )
                  .animate()
                  .fadeIn(delay: 750.ms, duration: 400.ms)
                  .slideY(
                    begin: 0.30,
                    end: 0,
                    delay: 750.ms,
                    duration: 500.ms,
                    curve: Curves.easeOutBack,
                  )
                  .scale(
                    begin: const Offset(0.85, 0.85),
                    end: const Offset(1, 1),
                    delay: 750.ms,
                    duration: 500.ms,
                    curve: Curves.easeOutBack,
                  ),
        );
      },
    );
  }

  void _confirmDeleteGroup(BuildContext context, String groupId) {
    final errorColor = Theme.of(context).colorScheme.error;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Icon(Icons.delete_outline_rounded, color: errorColor),
            const SizedBox(width: 10),
            Expanded(child: Text('delete_group'.tr())),
          ],
        ),
        content: Text('delete_group_confirm'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('cancel'.tr()),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);

              context.goNamed(AppRoutes.homeName);

              await getIt<GroupRepository>().deleteGroup(groupId);

              getIt<AnalyticsService>().logGroupDeleted();
            },
            child: Text('delete'.tr(), style: TextStyle(color: errorColor)),
          ),
        ],
      ),
    );
  }

  void _confirmRemoveMember(
    BuildContext context,
    String groupId,
    String memberId,
    String memberName,
  ) {
    final errorColor = Theme.of(context).colorScheme.error;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Icon(Icons.person_remove_outlined, color: errorColor),
            const SizedBox(width: 10),
            Expanded(child: Text('remove_member'.tr())),
          ],
        ),
        content: Text('remove_member_confirm'.tr(args: [memberName])),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('cancel'.tr()),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);

              await getIt<GroupRepository>().removeMemberFromGroup(
                groupId,
                memberId,
              );

              getIt<AnalyticsService>().logMemberRemoved();
            },
            child: Text('remove'.tr(), style: TextStyle(color: errorColor)),
          ),
        ],
      ),
    );
  }

  void _confirmLeaveGroup(BuildContext context, String groupId, String userId) {
    final errorColor = Theme.of(context).colorScheme.error;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Icon(Icons.exit_to_app_rounded, color: errorColor),
            const SizedBox(width: 10),
            Expanded(child: Text('leave_group'.tr())),
          ],
        ),
        content: Text('leave_group_confirm'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('cancel'.tr()),
          ),
          TextButton(
            onPressed: () async {
              final navigator = context;

              navigator.goNamed(AppRoutes.homeName);

              await getIt<GroupRepository>().leaveGroup(groupId, userId);

              getIt<AnalyticsService>().logGroupLeft();
            },
            child: Text('leave'.tr(), style: TextStyle(color: errorColor)),
          ),
        ],
      ),
    );
  }
}
