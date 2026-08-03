import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:go_router/go_router.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('add_expense'.tr())),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: FormBuilder(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FormBuilderTextField(
                    name: 'description',
                    decoration: InputDecoration(
                      labelText: 'description'.tr(),
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
                      prefixIcon: const Icon(Icons.currency_rupee_rounded),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: FormBuilderValidators.compose([
                      FormBuilderValidators.required(),
                      FormBuilderValidators.numeric(),
                      FormBuilderValidators.min(0.01),
                    ]),
                  ),
                  const SizedBox(height: 24),

                  Text(
                    'category'.tr(),
                    style: Theme.of(context).textTheme.titleSmall,
                  ),

                  const SizedBox(height: 12),

                  BlocBuilder<AddExpenseFormCubit, AddExpenseFormState>(
                    buildWhen: (p, c) => p.category != c.category,
                    builder: (context, formState) {
                      return SizedBox(
                        height: 76,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: ExpenseCategories.all.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 10),
                          itemBuilder: (context, index) {
                            final cat = ExpenseCategories.all[index];
                            final isSelected = cat.id == formState.category;

                            return GestureDetector(
                              onTap: () => context
                                  .read<AddExpenseFormCubit>()
                                  .selectCategory(cat.id),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 68,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppTheme.primaryColor.withValues(
                                          alpha: 0.15,
                                        )
                                      : Theme.of(context)
                                            .colorScheme
                                            .surfaceContainerHighest
                                            .withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppTheme.primaryColor
                                        : Colors.transparent,
                                    width: 2,
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      cat.icon,
                                      color: isSelected
                                          ? AppTheme.primaryColor
                                          : Theme.of(
                                              context,
                                            ).colorScheme.onSurface,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'category_${cat.id}'.tr(),
                                      style: const TextStyle(fontSize: 10),
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 24),

                  Text(
                    'paid_by'.tr(),
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 12),

                  BlocBuilder<AddExpenseFormCubit, AddExpenseFormState>(
                    buildWhen: (p, c) => p.paidBy != c.paidBy,
                    builder: (context, formState) {
                      return Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: widget.members.map((m) {
                          final uid = m['uid'] as String;
                          final isSelected = uid == formState.paidBy;
                          return ChoiceChip(
                            label: Text(_nameFor(uid)),
                            selected: isSelected,
                            onSelected: (_) => context
                                .read<AddExpenseFormCubit>()
                                .selectPaidBy(uid),
                          );
                        }).toList(),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'split_between'.tr(),
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 12),

                  BlocBuilder<AddExpenseFormCubit, AddExpenseFormState>(
                    buildWhen: (p, c) => p.splitBetween != c.splitBetween,
                    builder: (context, formState) {
                      return Column(
                        children: widget.members.map((m) {
                          final uid = m['uid'] as String;
                          final isChecked = formState.splitBetween.contains(
                            uid,
                          );

                          return CheckboxListTile(
                            value: isChecked,
                            onChanged: (_) => context
                                .read<AddExpenseFormCubit>()
                                .toggleSplitMember(uid),
                            title: Text(_nameFor(uid)),
                            contentPadding: EdgeInsets.zero,
                            controlAffinity: ListTileControlAffinity.leading,
                          );
                        }).toList(),
                      );
                    },
                  ),

                  const SizedBox(height: 12),

                  BlocBuilder<AddExpenseFormCubit, AddExpenseFormState>(
                    buildWhen: (p, c) => p.splitBetween != c.splitBetween,
                    builder: (context, formState) {
                      if (formState.splitBetween.isEmpty)
                        return const SizedBox.shrink();
                      return Text(
                        'split_hint'.tr(
                          args: [formState.splitBetween.length.toString()],
                        ),
                        style: Theme.of(context).textTheme.bodySmall,
                      );
                    },
                  ),

                  const SizedBox(height: 32),

                  BlocConsumer<AddExpenseFormCubit, AddExpenseFormState>(
                    listenWhen: (p, c) => p.errorMessage != c.errorMessage,
                    listener: (context, formState) {
                      if (formState.errorMessage != null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(formState.errorMessage!)),
                        );
                      }
                    },
                    builder: (context, formState) {
                      return ElevatedButton(
                        onPressed: formState.isSubmitting
                            ? null
                            : () => _submit(context),
                        child: formState.isSubmitting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text('save_expense'.tr()),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
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
      if (context.canPop()) {
        context.pop();
      }
    }
  }
}
