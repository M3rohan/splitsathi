import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:go_router/go_router.dart';
import 'package:splitsathi/core/constants/group_icons.dart';
import 'package:splitsathi/core/di/service_locator.dart';
import 'package:splitsathi/core/router/app_routes.dart';
import 'package:splitsathi/features/auth/bloc/auth_bloc.dart';
import 'package:splitsathi/features/groups/bloc/group_bloc.dart';
import 'package:splitsathi/features/groups/bloc/group_event.dart';
import 'package:splitsathi/features/groups/bloc/group_state.dart';
import 'package:splitsathi/features/groups/cubit/create_group_form_cubit.dart';
import 'package:splitsathi/features/groups/cubit/create_group_form_state.dart';

class CreateGroupScreen extends StatelessWidget {
  const CreateGroupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<GroupBloc>.value(value: getIt<GroupBloc>()),
        BlocProvider<CreateGroupFormCubit>(
          create: (_) => getIt<CreateGroupFormCubit>(),
        ),
      ],
      child: const _CreateGroupView(),
    );
  }
}

class _CreateGroupView extends StatefulWidget {
  const _CreateGroupView();

  @override
  State<_CreateGroupView> createState() => _CreateGroupViewState();
}

class _CreateGroupViewState extends State<_CreateGroupView> {
  final _formKey = GlobalKey<FormBuilderState>();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = getIt<AuthBloc>().state.user;
    return Scaffold(
      appBar: AppBar(title: Text('create_group'.tr())),
      body: BlocConsumer<GroupBloc, GroupState>(
        listener: (context, state) {
          if (state.status == GroupStatus.created) {
            if (context.canPop()) {
              context.pop();
            } else {
              context.goNamed(AppRoutes.homeName);
            }
          } else if (state.status == GroupStatus.error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage ?? 'Something went wrong'),
              ),
            );
          }
        },
        builder: (context, state) {
          final isCreating = state.status == GroupStatus.creating;

          return SafeArea(
            child: Padding(
              padding: EdgeInsetsGeometry.all(20),
              child: FormBuilder(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'choose_emoji'.tr(),
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 12),

                    BlocBuilder<CreateGroupFormCubit, CreateGroupFormState>(
                      buildWhen: (prev, curr) =>
                          prev.selectedEmoji != curr.selectedEmoji,
                      builder: (context, formState) {
                        return SizedBox(
                          height: 56,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: GroupIcons.options.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 10),
                            itemBuilder: (context, index) {
                              final emoji = GroupIcons.options[index];
                              final isSelected =
                                  emoji == formState.selectedEmoji;
                              return GestureDetector(
                                onTap: () => context
                                    .read<CreateGroupFormCubit>()
                                    .selectEmoji(emoji),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? Theme.of(context).colorScheme.primary
                                              .withValues(alpha: 0.15)
                                        : Theme.of(context)
                                              .colorScheme
                                              .surfaceContainerHighest
                                              .withValues(alpha: 0.3),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isSelected
                                          ? Theme.of(
                                              context,
                                            ).colorScheme.primary
                                          : Colors.transparent,
                                      width: 2,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      emoji,
                                      style: const TextStyle(fontSize: 26),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    FormBuilderTextField(
                      name: 'groupName',
                      decoration: InputDecoration(
                        labelText: 'group_name'.tr(),
                        prefixIcon: const Icon(Icons.groups_rounded),
                      ),
                      validator: FormBuilderValidators.compose([
                        FormBuilderValidators.required(),
                        FormBuilderValidators.minLength(2),
                      ]),
                    ),

                    const SizedBox(height: 24),

                    Text(
                      'add_members'.tr(),
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 12),

                    BlocBuilder<CreateGroupFormCubit, CreateGroupFormState>(
                      builder: (context, formState) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _emailController,
                                    decoration: InputDecoration(
                                      hintText: 'member_email_hint'.tr(),
                                      prefixIcon: const Icon(
                                        Icons.email_outlined,
                                      ),
                                      errorText: formState.memberError,
                                    ),
                                    keyboardType: TextInputType.emailAddress,
                                    onSubmitted: (value) {
                                      context
                                          .read<CreateGroupFormCubit>()
                                          .addMemberByEmail(value);
                                      _emailController.clear();
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                formState.isAddingMember
                                    ? const Padding(
                                        padding: EdgeInsets.all(12),
                                        child: SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        ),
                                      )
                                    : IconButton.filled(
                                        onPressed: () {
                                          context
                                              .read<CreateGroupFormCubit>()
                                              .addMemberByEmail(
                                                _emailController.text,
                                              );
                                          _emailController.clear();
                                        },
                                        icon: const Icon(Icons.add),
                                      ),
                              ],
                            ),

                            const SizedBox(height: 12),

                            if (formState.memberEmails.isNotEmpty)
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: formState.memberEmails.map((email) {
                                  return Chip(
                                        label: Text(email),
                                        onDeleted: () => context
                                            .read<CreateGroupFormCubit>()
                                            .removeMember(email),
                                        avatar: const Icon(
                                          Icons.person,
                                          size: 18,
                                        ),
                                      )
                                      .animate()
                                      .fadeIn(duration: 250.ms)
                                      .scale(
                                        begin: const Offset(0.8, 0.8),
                                        end: const Offset(1, 1),
                                      );
                                }).toList(),
                              ),
                          ],
                        );
                      },
                    ),

                    const Spacer(),
                    ElevatedButton(
                      onPressed: isCreating
                          ? null
                          : () => _submit(context, currentUser?.uid),
                      child: isCreating
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text('create_group_button'.tr()),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _submit(BuildContext context, String? currentUserId) async {
    if (currentUserId == null) return;
    if (!(_formKey.currentState?.saveAndValidate() ?? false)) return;

    final groupName = _formKey.currentState!.value['groupName'] as String;
    final formCubit = context.read<CreateGroupFormCubit>();
    final selectedEmoji = formCubit.state.selectedEmoji;

    final memberIds = await formCubit.resolveMemberIds(currentUserId);

    if (!context.mounted) return;

    context.read<GroupBloc>().add(
      GroupCreateRequested(
        name: groupName,
        createdBy: currentUserId,
        memberIds: memberIds,
        emoji: selectedEmoji,
      ),
    );
  }
}
