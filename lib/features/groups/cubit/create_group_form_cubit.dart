import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:splitsathi/features/groups/cubit/create_group_form_state.dart';
import 'package:splitsathi/features/groups/repository/group_repository.dart';

class CreateGroupFormCubit extends Cubit<CreateGroupFormState> {
  final GroupRepository _groupRepository;

  CreateGroupFormCubit({required GroupRepository groupRepository})
    : _groupRepository = groupRepository,
      super(const CreateGroupFormState());

  void selectEmoji(String emoji) {
    emit(state.copyWith(selectedEmoji: emoji));
  }

  Future<void> addMemberByEmail(String rawEmail) async {
    final email = rawEmail.trim();
    if (email.isEmpty) return;

    emit(state.copyWith(isAddingMember: true, memberError: null));

    if (state.memberEmails.contains(email)) {
      emit(state.copyWith(isAddingMember: false, memberError: 'Already added'));
      return;
    }

    final userId = await _groupRepository.findUserIdByEmail(email);

    if (userId == null) {
      emit(
        state.copyWith(
          isAddingMember: false,
          memberError: 'No user found with this email',
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        isAddingMember: false,
        memberEmails: [...state.memberEmails, email],
        memberError: null,
      ),
    );
  }

  void removeMember(String email) {
    emit(
      state.copyWith(
        memberEmails: state.memberEmails.where((e) => e != email).toList(),
      ),
    );
  }

  Future<List<String>> resolveMemberIds(String currentUserId) async {
    final memberIds = <String>{currentUserId};
    for (final email in state.memberEmails) {
      final uid = await _groupRepository.findUserIdByEmail(email);
      if (uid != null) memberIds.add(uid);
    }
    return memberIds.toList();
  }

  void reset() {
    emit(const CreateGroupFormState());
  }
}
