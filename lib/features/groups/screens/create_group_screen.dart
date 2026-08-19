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
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 20,
        title: Text(
          'create_group'.tr(),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
      ),
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
            child: LayoutBuilder(
              builder: (context, constraints) {
                return FormBuilder(
                  key: _formKey,
                  child: SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: EdgeInsets.fromLTRB(
                      20,
                      8,
                      20,
                      MediaQuery.of(context).viewInsets.bottom + 24,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight - 16,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                                width: double.infinity,
                                padding: const EdgeInsets.fromLTRB(
                                  18,
                                  18,
                                  18,
                                  16,
                                ),
                                decoration: BoxDecoration(
                                  color: colorScheme.primary.withValues(
                                    alpha: 0.08,
                                  ),
                                  borderRadius: BorderRadius.circular(22),
                                  border: Border.all(
                                    color: colorScheme.primary.withValues(
                                      alpha: 0.10,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: colorScheme.primary.withValues(
                                          alpha: 0.14,
                                        ),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.groups_rounded,
                                        color: colorScheme.primary,
                                        size: 25,
                                      ),
                                    ),
                                    const SizedBox(width: 13),
                                    Expanded(
                                      child: Text(
                                        'create_group'.tr(),
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w800,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                              .animate()
                              .fadeIn(duration: 450.ms, curve: Curves.easeOut)
                              .slideY(
                                begin: -0.06,
                                end: 0,
                                duration: 450.ms,
                                curve: Curves.easeOutCubic,
                              ),

                          const SizedBox(height: 24),

                          Text(
                            'choose_emoji'.tr(),
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 10),

                          BlocBuilder<
                            CreateGroupFormCubit,
                            CreateGroupFormState
                          >(
                            buildWhen: (prev, curr) =>
                                prev.selectedEmoji != curr.selectedEmoji,
                            builder: (context, formState) {
                              return Container(
                                    height: 74,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 9,
                                      vertical: 9,
                                    ),
                                    decoration: BoxDecoration(
                                      color: colorScheme.surface,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: colorScheme.outlineVariant
                                            .withValues(alpha: 0.35),
                                      ),
                                    ),
                                    child: ListView.separated(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: GroupIcons.options.length,
                                      separatorBuilder: (_, __) =>
                                          const SizedBox(width: 7),
                                      itemBuilder: (context, index) {
                                        final emoji = GroupIcons.options[index];
                                        final isSelected =
                                            emoji == formState.selectedEmoji;
                                        return GestureDetector(
                                          onTap: () => context
                                              .read<CreateGroupFormCubit>()
                                              .selectEmoji(emoji),
                                          child: AnimatedScale(
                                            scale: isSelected ? 1.04 : 1,
                                            duration: const Duration(
                                              milliseconds: 180,
                                            ),
                                            curve: Curves.easeOutBack,
                                            child: AnimatedContainer(
                                              duration: const Duration(
                                                milliseconds: 220,
                                              ),
                                              curve: Curves.easeOutCubic,
                                              width: 56,
                                              height: 56,
                                              decoration: BoxDecoration(
                                                color: isSelected
                                                    ? colorScheme.primary
                                                          .withValues(
                                                            alpha: 0.15,
                                                          )
                                                    : colorScheme
                                                          .surfaceContainerHighest
                                                          .withValues(
                                                            alpha: 0.45,
                                                          ),
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                                border: Border.all(
                                                  color: isSelected
                                                      ? colorScheme.primary
                                                      : Colors.transparent,
                                                  width: 2,
                                                ),
                                                boxShadow: isSelected
                                                    ? [
                                                        BoxShadow(
                                                          color: colorScheme
                                                              .primary
                                                              .withValues(
                                                                alpha: 0.16,
                                                              ),
                                                          blurRadius: 10,
                                                          offset: const Offset(
                                                            0,
                                                            4,
                                                          ),
                                                        ),
                                                      ]
                                                    : null,
                                              ),
                                              child: Center(
                                                child: Text(
                                                  emoji,
                                                  style: const TextStyle(
                                                    fontSize: 26,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  )
                                  .animate()
                                  .fadeIn(delay: 150.ms, duration: 450.ms)
                                  .slideX(
                                    begin: 0.06,
                                    end: 0,
                                    delay: 150.ms,
                                    duration: 450.ms,
                                    curve: Curves.easeOutCubic,
                                  );
                            },
                          ),
                          const SizedBox(height: 24),
                          FormBuilderTextField(
                                name: 'groupName',
                                textCapitalization: TextCapitalization.words,
                                decoration: InputDecoration(
                                  labelText: 'group_name'.tr(),
                                  prefixIcon: const Icon(
                                    Icons.drive_file_rename_outline,
                                  ),
                                  filled: true,
                                  fillColor: colorScheme.surfaceContainerHighest
                                      .withValues(alpha: 0.35),
                                ),
                                validator: FormBuilderValidators.compose([
                                  FormBuilderValidators.required(),
                                  FormBuilderValidators.minLength(2),
                                ]),
                              )
                              .animate()
                              .fadeIn(delay: 250.ms, duration: 450.ms)
                              .slideY(
                                begin: 0.06,
                                end: 0,
                                delay: 250.ms,
                                duration: 450.ms,
                                curve: Curves.easeOutCubic,
                              ),

                          const SizedBox(height: 26),

                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'add_members'.tr(),
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 9,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: colorScheme.primary.withValues(
                                    alpha: 0.09,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Icon(
                                  Icons.person_add_alt_1_rounded,
                                  size: 16,
                                  color: colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          BlocBuilder<
                            CreateGroupFormCubit,
                            CreateGroupFormState
                          >(
                            builder: (context, formState) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          controller: _emailController,
                                          textInputAction: TextInputAction.done,
                                          decoration: InputDecoration(
                                            hintText: 'member_email_hint'.tr(),
                                            prefixIcon: const Icon(
                                              Icons.email_outlined,
                                            ),
                                            errorText: formState.memberError,
                                            filled: true,
                                            fillColor: colorScheme
                                                .surfaceContainerHighest
                                                .withValues(alpha: 0.35),
                                          ),
                                          keyboardType:
                                              TextInputType.emailAddress,
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
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                    ),
                                              ),
                                            )
                                          : IconButton.filled(
                                              tooltip: 'Add member',
                                              style: IconButton.styleFrom(
                                                minimumSize: const Size(52, 52),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(16),
                                                ),
                                              ),
                                              onPressed: () {
                                                context
                                                    .read<
                                                      CreateGroupFormCubit
                                                    >()
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
                                      children: formState.memberEmails.map((
                                        email,
                                      ) {
                                        return InputChip(
                                              label: Text(
                                                email,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              onDeleted: () => context
                                                  .read<CreateGroupFormCubit>()
                                                  .removeMember(email),
                                              avatar: const Icon(
                                                Icons.person_rounded,
                                                size: 17,
                                              ),
                                              deleteIcon: const Icon(
                                                Icons.close_rounded,
                                                size: 17,
                                              ),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 4,
                                                    vertical: 5,
                                                  ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(14),
                                              ),
                                              side: BorderSide(
                                                color: colorScheme
                                                    .outlineVariant
                                                    .withValues(alpha: 0.45),
                                              ),
                                              backgroundColor:
                                                  colorScheme.surface,
                                            )
                                            .animate()
                                            .fadeIn(
                                              duration: 300.ms,
                                              curve: Curves.easeOut,
                                            )
                                            .slideX(
                                              begin: -0.04,
                                              end: 0,
                                              duration: 300.ms,
                                              curve: Curves.easeOutCubic,
                                            )
                                            .scale(
                                              begin: const Offset(0.88, 0.88),
                                              end: const Offset(1, 1),
                                              duration: 300.ms,
                                              curve: Curves.easeOutBack,
                                            );
                                      }).toList(),
                                    ),
                                ],
                              );
                            },
                          ),

                          const SizedBox(height: 28),
                          SizedBox(
                                width: double.infinity,
                                height: 54,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(17),
                                    ),
                                  ),
                                  onPressed: isCreating
                                      ? null
                                      : () =>
                                            _submit(context, currentUser?.uid),
                                  child: isCreating
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : Text(
                                          'create_group_button'.tr(),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 15,
                                          ),
                                        ),
                                ),
                              )
                              .animate()
                              .fadeIn(delay: 400.ms, duration: 450.ms)
                              .slideY(
                                begin: 0.12,
                                end: 0,
                                delay: 400.ms,
                                duration: 500.ms,
                                curve: Curves.easeOutBack,
                              )
                              .scale(
                                begin: const Offset(0.97, 0.97),
                                end: const Offset(1, 1),
                                delay: 400.ms,
                                duration: 500.ms,
                                curve: Curves.easeOutCubic,
                              ),
                        ],
                      ),
                    ),
                  ),
                );
              },
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
