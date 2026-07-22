import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:splitsathi/features/groups/bloc/group_event.dart';
import 'package:splitsathi/features/groups/bloc/group_state.dart';
import 'package:splitsathi/features/groups/models/group_model.dart';
import 'package:splitsathi/features/groups/repository/group_repository.dart';

class GroupBloc extends Bloc<GroupEvent, GroupState> {
  final GroupRepository _groupRepository;
  StreamSubscription<List<GroupModel>>? _groupsSubscription;

  GroupBloc({required GroupRepository groupRepository})
    : _groupRepository = groupRepository,
      super(const GroupState()) {
    on<GroupsSubscriptionRequested>(_onSubscriptionRequested);
    on<GroupsUpdated>(_onGroupsUpdated);
    on<GroupCreateRequested>(_onCreateRequested);
  }

  Future<void> _onSubscriptionRequested(
    GroupsSubscriptionRequested event,
    Emitter<GroupState> emit,
  ) async {
    emit(state.copyWith(status: GroupStatus.loading));

    await _groupsSubscription?.cancel();
    _groupsSubscription = _groupRepository
        .getUserGroups(event.userId)
        .listen(
          (groups) => add(GroupsUpdated(groups)),
          onError: (_) => emit(state.copyWith(status: GroupStatus.error)),
        );
  }

  void _onGroupsUpdated(GroupsUpdated event, Emitter<GroupState> emit) {
    emit(
      state.copyWith(
        status: GroupStatus.loaded,
        groups: event.groups.cast<GroupModel>(),
      ),
    );
  }

  Future<void> _onCreateRequested(
    GroupCreateRequested event,
    Emitter<GroupState> emit,
  ) async {
    emit(state.copyWith(status: GroupStatus.creating));

    try {
      await _groupRepository.createGroup(
        name: event.name,
        createdBy: event.createdBy,
        memberIds: event.memberIds,
        emoji: event.emoji,
      );
      emit(state.copyWith(status: GroupStatus.created));
    } catch (e) {
      emit(
        state.copyWith(
          status: GroupStatus.error,
          errorMessage: 'Failed to create group. Please try again.',
        ),
      );
    }
  }

  @override
  Future<void> close() {
    _groupsSubscription?.cancel();
    return super.close();
  }
}
