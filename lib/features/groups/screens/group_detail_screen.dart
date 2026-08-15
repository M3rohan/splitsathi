import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:splitsathi/core/constants/group_icons.dart';
import 'package:splitsathi/core/security/biometric_guard.dart';
import 'package:splitsathi/features/expenses/repository/expense_repository.dart';
import 'package:splitsathi/features/groups/repository/group_repository.dart';
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
            body: Center(child: Text('group_not_found'.tr())),
          );
        }

        final group = state.group!;
        final currentUserId = getIt<AuthBloc>().state.user?.uid ?? '';
        final myBalance = state.netBalances[currentUserId] ?? 0.0;
        final isPositive = myBalance >= 0;

        String nameFor(String uid) {
          final m = state.members.firstWhere(
            (m) => m['uid'] == uid,
            orElse: () => {'name': '?'},
          );
          return (m['name'] as String?)?.isNotEmpty == true
              ? m['name']
              : (m['email'] ?? '?');
        }

        return Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                Text(
                  group.emoji ?? GroupIcons.defaultIcon,
                  style: const TextStyle(fontSize: 22),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(group.name, overflow: TextOverflow.ellipsis),
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
                    if (context.mounted) _confirmDeleteGroup(context, group.id);
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
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
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
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isPositive ? 'you_are_owed'.tr() : 'you_owe'.tr(),
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '₹${myBalance.abs().toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            state.expenses.isEmpty
                                ? 'no_expenses_yet'.tr()
                                : 'group_total'.tr(
                                    args: [
                                      state.expenses
                                          .fold(0.0, (s, e) => s + e.amount)
                                          .toStringAsFixed(2),
                                    ],
                                  ),
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    )
                    .animate()
                    .fadeIn(duration: 400.ms)
                    .scale(
                      begin: const Offset(0.95, 0.95),
                      end: const Offset(1, 1),
                    ),

                const SizedBox(height: 24),

                if (state.dueRecurringExpenses.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.orange.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.notifications_active_rounded,
                          color: Colors.orange,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'recurring_due'.tr(
                              args: [
                                state.dueRecurringExpenses.length.toString(),
                              ],
                            ),
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(),

                const SizedBox(height: 24),

                if (state.settlements.isNotEmpty) ...[
                  Text(
                    'suggested_settlements'.tr(),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ).animate().fadeIn(delay: 150.ms),
                  const SizedBox(height: 12),
                  ...List.generate(state.settlements.length, (index) {
                    final s = state.settlements[index];
                    return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest
                                .withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.arrow_forward_rounded,
                                size: 18,
                                color: AppTheme.primaryColor,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  '${nameFor(s.fromUserId)} → ${nameFor(s.toUserId)}',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ),
                              Text(
                                '₹${s.amount.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            ],
                          ),
                        )
                        .animate()
                        .fadeIn(delay: (200 + index * 60).ms)
                        .slideX(begin: -0.05, end: 0);
                  }),
                  const SizedBox(height: 24),
                ],
                Text(
                  'members'.tr(),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ).animate().fadeIn(delay: 200.ms),

                const SizedBox(height: 12),

                ...List.generate(state.members.length, (index) {
                  final member = state.members[index];
                  final isYou = member['uid'] == currentUserId;
                  final isCreator = member['uid'] == group.createdBy;
                  final currentUserIsCreator = currentUserId == group.createdBy;

                  return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest
                              .withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: AppTheme.primaryColor.withValues(
                                alpha: 0.15,
                              ),
                              child: Text(
                                (member['name'] as String?)?.isNotEmpty == true
                                    ? (member['name'] as String)[0]
                                          .toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      isYou
                                          ? '${member['name'] ?? ''} (${'you'.tr()})'
                                          : (member['name'] ??
                                                member['email'] ??
                                                ''),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w500,
                                          ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (isCreator) ...[
                                    const SizedBox(width: 6),
                                    Icon(
                                      Icons.star_rounded,
                                      size: 14,
                                      color: Colors.amber[700],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            if (state.netBalances[member['uid']] != null)
                              Text(
                                '${state.netBalances[member['uid']]! >= 0 ? '+' : ''}₹${state.netBalances[member['uid']]!.toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: state.netBalances[member['uid']]! >= 0
                                      ? Colors.green
                                      : Colors.red,
                                ),
                              ),

                            if (currentUserIsCreator && !isYou && !isCreator)
                              IconButton(
                                icon: const Icon(
                                  Icons.person_remove_outlined,
                                  size: 18,
                                ),
                                onPressed: () => _confirmRemoveMember(
                                  context,
                                  group.id,
                                  member['uid'],
                                  member['name'] ?? '',
                                ),
                              ),
                          ],
                        ),
                      )
                      .animate()
                      .fadeIn(delay: (300 + index * 60).ms)
                      .slideX(begin: -0.05, end: 0);
                }),

                const SizedBox(height: 28),

                // ---------- Expenses ----------
                Text(
                  'expenses'.tr(),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ).animate().fadeIn(delay: 500.ms),

                const SizedBox(height: 12),

                if (state.expenses.isEmpty)
                  EmptyStateWidget(title: 'no_expenses_added'.tr(), size: 100)
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
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest
                              .withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withValues(
                                  alpha: 0.12,
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                ExpenseCategories.iconForId(expense.category),
                                color: AppTheme.primaryColor,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    expense.description,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    'paid_by_name'.tr(args: [payerName]),
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '₹${expense.amount.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(delay: (600 + index * 60).ms),
                    );
                  }),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
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
            icon: const Icon(Icons.add),
            label: Text('add_expense'.tr()),
          ).animate().scale(delay: 700.ms, curve: Curves.easeOutBack),
        );
      },
    );
  }

  void _confirmDeleteGroup(BuildContext context, String groupId) {
    final errorColor = Theme.of(context).colorScheme.error;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('delete_group'.tr()),
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
        title: Text('remove_member'.tr()),
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
        title: Text('leave_group'.tr()),
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
            },
            child: Text('leave'.tr(), style: TextStyle(color: errorColor)),
          ),
        ],
      ),
    );
  }
}
