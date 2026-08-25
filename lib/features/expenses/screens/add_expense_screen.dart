import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:splitsathi/core/constants/expense_categories.dart';
import 'package:splitsathi/core/di/service_locator.dart';
import 'package:splitsathi/core/theme/app_theme.dart';
import 'package:splitsathi/features/auth/bloc/auth_bloc.dart';
import 'package:splitsathi/features/expenses/bloc/expense_bloc.dart';
import 'package:splitsathi/features/expenses/cubit/add_expense_form_cubit.dart';
import 'package:splitsathi/features/expenses/cubit/add_expense_form_state.dart';

class AddExpenseScreen extends StatelessWidget {
  final String groupId;
  final String groupName;
  final List<Map<String, dynamic>> members;
  final String currentUserId;

  const AddExpenseScreen({
    super.key,
    required this.groupId,
    required this.groupName,
    required this.members,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ExpenseBloc>.value(value: getIt<ExpenseBloc>()),
        BlocProvider<AddExpenseFormCubit>(
          create: (_) => getIt<AddExpenseFormCubit>()
            ..initWithMembers(
              members.map((m) => m['uid'] as String).toList(),
              currentUserId,
            ),
        ),
      ],
      child: _AddExpenseView(
        groupId: groupId,
        members: members,
        groupName: groupName,
      ),
    );
  }
}

class _AddExpenseView extends StatefulWidget {
  final String groupId;
  final String groupName;
  final List<Map<String, dynamic>> members;

  const _AddExpenseView({
    required this.groupId,
    required this.members,
    required this.groupName,
  });

  @override
  State<_AddExpenseView> createState() => _AddExpenseViewState();
}

class _AddExpenseViewState extends State<_AddExpenseView> {
  final _formKey = GlobalKey<FormBuilderState>();

  String _nameFor(String uid) {
    final member = widget.members.firstWhere(
      (m) => m['uid'] == uid,
      orElse: () => {'name': 'Unknown'},
    );

    return (member['name'] as String?)?.isNotEmpty == true
        ? member['name']
        : (member['email'] ?? 'Unknown');
  }

  String _initialFor(String uid) {
    final name = _nameFor(uid).trim();

    if (name.isEmpty) {
      return '?';
    }

    return name.substring(0, 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final appColors = theme.extension<AppColors>()!;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        elevation: 0,
        titleSpacing: 20,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'add_expense'.tr(),
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              widget.groupName,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: FormBuilder(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle(
                        context,
                        icon: Icons.receipt_long_rounded,
                        title: 'expense_details'.tr(),
                      ),
                      const SizedBox(height: 12),

                      _buildCard(
                        context,
                        child: Column(
                          children: [
                            FormBuilderTextField(
                              name: 'description',
                              decoration: InputDecoration(
                                labelText: 'description'.tr(),
                                hintText: 'enter_description'.tr(),
                                prefixIcon: const Icon(Icons.notes_rounded),
                              ),
                              validator: FormBuilderValidators.compose([
                                FormBuilderValidators.required(),
                              ]),
                            ),
                            const SizedBox(height: 16),
                            FormBuilderTextField(
                              name: 'amount',
                              decoration: InputDecoration(
                                labelText: 'amount'.tr(),
                                hintText: '0.00',
                                prefixIcon: const Icon(
                                  Icons.currency_rupee_rounded,
                                ),
                              ),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              validator: FormBuilderValidators.compose([
                                FormBuilderValidators.required(),
                                FormBuilderValidators.numeric(),
                                FormBuilderValidators.min(0.01),
                              ]),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 28),

                      _buildSectionTitle(
                        context,
                        icon: Icons.category_rounded,
                        title: 'category'.tr(),
                      ),
                      const SizedBox(height: 12),

                      BlocBuilder<AddExpenseFormCubit, AddExpenseFormState>(
                        buildWhen: (p, c) => p.category != c.category,
                        builder: (context, formState) {
                          return SizedBox(
                            height: 92,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: ExpenseCategories.all.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: 10),
                              itemBuilder: (context, index) {
                                final cat = ExpenseCategories.all[index];
                                final isSelected = cat.id == formState.category;

                                return _CategoryItem(
                                  icon: cat.icon,
                                  label: 'category_${cat.id}'.tr(),
                                  isSelected: isSelected,
                                  onTap: () {
                                    context
                                        .read<AddExpenseFormCubit>()
                                        .selectCategory(cat.id);
                                  },
                                );
                              },
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 28),

                      _buildSectionTitle(
                        context,
                        icon: Icons.person_rounded,
                        title: 'paid_by'.tr(),
                      ),
                      const SizedBox(height: 12),

                      _buildCard(
                        context,
                        child:
                            BlocBuilder<
                              AddExpenseFormCubit,
                              AddExpenseFormState
                            >(
                              buildWhen: (p, c) => p.paidBy != c.paidBy,
                              builder: (context, formState) {
                                return Wrap(
                                  spacing: 10,
                                  runSpacing: 10,
                                  children: widget.members.map((member) {
                                    final uid = member['uid'] as String;
                                    final isSelected = uid == formState.paidBy;

                                    return _MemberChip(
                                      name: _nameFor(uid),
                                      initial: _initialFor(uid),
                                      selected: isSelected,
                                      onTap: () {
                                        context
                                            .read<AddExpenseFormCubit>()
                                            .selectPaidBy(uid);
                                      },
                                    );
                                  }).toList(),
                                );
                              },
                            ),
                      ),

                      const SizedBox(height: 28),

                      _buildSectionTitle(
                        context,
                        icon: Icons.call_split_rounded,
                        title: 'split_between'.tr(),
                      ),
                      const SizedBox(height: 12),

                      _buildCard(
                        context,
                        child: Column(
                          children: [
                            BlocBuilder<
                              AddExpenseFormCubit,
                              AddExpenseFormState
                            >(
                              buildWhen: (p, c) => p.splitType != c.splitType,
                              builder: (context, formState) {
                                return SizedBox(
                                  width: double.infinity,
                                  child: SegmentedButton<String>(
                                    segments: [
                                      ButtonSegment(
                                        value: 'equal',
                                        icon: const Icon(Icons.balance_rounded),
                                        label: Text('split_equally'.tr()),
                                      ),
                                      ButtonSegment(
                                        value: 'custom',
                                        icon: const Icon(Icons.tune_rounded),
                                        label: Text('split_custom'.tr()),
                                      ),
                                    ],
                                    selected: {formState.splitType},
                                    onSelectionChanged: (selection) {
                                      context
                                          .read<AddExpenseFormCubit>()
                                          .setSplitType(selection.first);
                                    },
                                  ),
                                );
                              },
                            ),

                            const SizedBox(height: 18),

                            BlocBuilder<
                              AddExpenseFormCubit,
                              AddExpenseFormState
                            >(
                              builder: (context, formState) {
                                if (formState.splitType == 'equal') {
                                  return Column(
                                    children: widget.members.map((member) {
                                      final uid = member['uid'] as String;
                                      final isChecked = formState.splitBetween
                                          .contains(uid);

                                      return Container(
                                        margin: const EdgeInsets.only(
                                          bottom: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isChecked
                                              ? colorScheme.primary.withValues(
                                                  alpha: 0.08,
                                                )
                                              : colorScheme
                                                    .surfaceContainerHighest
                                                    .withValues(alpha: 0.35),
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                        ),
                                        child: CheckboxListTile(
                                          value: isChecked,
                                          onChanged: (_) {
                                            context
                                                .read<AddExpenseFormCubit>()
                                                .toggleSplitMember(uid);
                                          },
                                          title: Text(
                                            _nameFor(uid),
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          secondary: CircleAvatar(
                                            radius: 18,
                                            child: Text(_initialFor(uid)),
                                          ),
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                horizontal: 12,
                                              ),
                                          controlAffinity:
                                              ListTileControlAffinity.trailing,
                                        ),
                                      );
                                    }).toList(),
                                  );
                                }

                                final amountValue =
                                    double.tryParse(
                                      _formKey
                                              .currentState
                                              ?.fields['amount']
                                              ?.value
                                              ?.toString() ??
                                          '',
                                    ) ??
                                    0.0;

                                final cubit = context
                                    .read<AddExpenseFormCubit>();

                                final enteredSum = cubit.customSplitsSum;

                                final remaining = amountValue - enteredSum;

                                final isBalanced = remaining.abs() < 0.01;

                                return Column(
                                  children: [
                                    ...widget.members.map((member) {
                                      final uid = member['uid'] as String;

                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 10,
                                        ),
                                        child: Row(
                                          children: [
                                            CircleAvatar(
                                              radius: 18,
                                              child: Text(_initialFor(uid)),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                _nameFor(uid),
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                            SizedBox(
                                              width: 115,
                                              child: TextFormField(
                                                decoration:
                                                    const InputDecoration(
                                                      prefixText: '₹ ',
                                                      hintText: '0.00',
                                                      isDense: true,
                                                    ),
                                                keyboardType:
                                                    const TextInputType.numberWithOptions(
                                                      decimal: true,
                                                    ),
                                                onChanged: (value) {
                                                  final parsed =
                                                      double.tryParse(value) ??
                                                      0.0;

                                                  cubit.setCustomSplitAmount(
                                                    uid,
                                                    parsed,
                                                  );

                                                  setState(() {});
                                                },
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }),

                                    const SizedBox(height: 8),

                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isBalanced
                                            ? appColors.positive.withValues(
                                                alpha: 0.10,
                                              )
                                            : appColors.warning.withValues(
                                                alpha: 0.10,
                                              ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(
                                                isBalanced
                                                    ? Icons.check_circle_rounded
                                                    : Icons.info_rounded,
                                                size: 18,
                                                color: isBalanced
                                                    ? appColors.positive
                                                    : appColors.warning,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                'remaining'.tr(),
                                                style: theme
                                                    .textTheme
                                                    .bodyMedium
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                              ),
                                            ],
                                          ),
                                          Text(
                                            '₹${remaining.toStringAsFixed(2)}',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: isBalanced
                                                  ? appColors.positive
                                                  : appColors.warning,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 28),

                      _buildSectionTitle(
                        context,
                        icon: Icons.repeat_rounded,
                        title: 'recurring_expense'.tr(),
                      ),
                      const SizedBox(height: 12),

                      _buildCard(
                        context,
                        child:
                            BlocBuilder<
                              AddExpenseFormCubit,
                              AddExpenseFormState
                            >(
                              buildWhen: (p, c) =>
                                  p.isRecurring != c.isRecurring ||
                                  p.recurrenceFrequency !=
                                      c.recurrenceFrequency,
                              builder: (context, formState) {
                                return Column(
                                  children: [
                                    SwitchListTile(
                                      value: formState.isRecurring,
                                      onChanged: (value) {
                                        context
                                            .read<AddExpenseFormCubit>()
                                            .toggleRecurring(value);
                                      },
                                      title: Text(
                                        'make_recurring'.tr(),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      subtitle: Text('recurring_hint'.tr()),
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                    if (formState.isRecurring) ...[
                                      const SizedBox(height: 10),
                                      SizedBox(
                                        width: double.infinity,
                                        child: SegmentedButton<String>(
                                          segments: [
                                            ButtonSegment(
                                              value: 'weekly',
                                              icon: const Icon(
                                                Icons.view_week_rounded,
                                              ),
                                              label: Text('weekly'.tr()),
                                            ),
                                            ButtonSegment(
                                              value: 'monthly',
                                              icon: const Icon(
                                                Icons.calendar_month_rounded,
                                              ),
                                              label: Text('monthly'.tr()),
                                            ),
                                          ],
                                          selected: {
                                            formState.recurrenceFrequency,
                                          },
                                          onSelectionChanged: (selection) {
                                            context
                                                .read<AddExpenseFormCubit>()
                                                .selectRecurrenceFrequency(
                                                  selection.first,
                                                );
                                          },
                                        ),
                                      ),
                                    ],
                                  ],
                                );
                              },
                            ),
                      ),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),

              _buildBottomAction(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(
    BuildContext context, {
    required IconData icon,
    required String title,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: colorScheme.primary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, size: 18, color: colorScheme.primary),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }

  Widget _buildCard(BuildContext context, {required Widget child}) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      child: child,
    );
  }

  Widget _buildBottomAction(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            blurRadius: 14,
            offset: const Offset(0, -4),
            color: colorScheme.shadow.withValues(alpha: 0.08),
          ),
        ],
      ),
      child: BlocConsumer<AddExpenseFormCubit, AddExpenseFormState>(
        listenWhen: (p, c) => p.errorMessage != c.errorMessage,
        listener: (context, formState) {
          if (formState.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                behavior: SnackBarBehavior.floating,
                content: Text(formState.errorMessage!),
              ),
            );
          }
        },
        builder: (context, formState) {
          return SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: formState.isSubmitting ? null : () => _submit(context),
              child: formState.isSubmitting
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: Colors.white,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_rounded),
                        const SizedBox(width: 8),
                        Text(
                          'save_expense'.tr(),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _submit(BuildContext context) async {
    if (!(_formKey.currentState?.saveAndValidate() ?? false)) return;

    final values = _formKey.currentState!.value;
    final description = values['description'] as String;
    final amount = double.parse(values['amount'].toString());

    final currentUser = getIt<AuthBloc>().state.user;
    final actorName = currentUser?.displayName ?? 'Someone';

    final success = await context.read<AddExpenseFormCubit>().submit(
      groupId: widget.groupId,
      groupName: widget.groupName,
      description: description,
      amount: amount,
      allMemberIds: widget.members.map((m) => m['uid'] as String).toList(),
      actorName: actorName,
      actorUserId: currentUser?.uid ?? '',
    );

    if (success && context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: SizedBox(
              height: 300,
              child: Lottie.asset(
                'assets/animations/success.json',
                repeat: false,
                onLoaded: (composition) {
                  Future.delayed(composition.duration, () {
                    if (dialogContext.mounted) {
                      Navigator.of(dialogContext).pop();
                    }
                  });
                },
              ),
            ),
          );
        },
      ).then((_) {
        if (context.mounted && context.canPop()) {
          context.pop();
        }
      });
    }
  }
}

class _CategoryItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 76,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primary.withValues(alpha: 0.12)
              : colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? colorScheme.primary
                : colorScheme.outlineVariant.withValues(alpha: 0.35),
            width: isSelected ? 1.8 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 25,
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? colorScheme.primary : colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _MemberChip extends StatelessWidget {
  final String name;
  final String initial;
  final bool selected;
  final VoidCallback onTap;

  const _MemberChip({
    required this.name,
    required this.initial,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? colorScheme.primary.withValues(alpha: 0.12)
              : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: selected
                ? colorScheme.primary
                : colorScheme.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: selected
                  ? colorScheme.primary
                  : colorScheme.primaryContainer,
              child: Text(
                initial,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: selected
                      ? colorScheme.onPrimary
                      : colorScheme.onPrimaryContainer,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              name,
              style: TextStyle(
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            if (selected) ...[
              const SizedBox(width: 6),
              Icon(
                Icons.check_circle_rounded,
                size: 18,
                color: colorScheme.primary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
