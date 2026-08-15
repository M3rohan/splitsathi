import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/group_model.dart';
import '../repository/group_repository.dart';
import 'group_event.dart';
import 'group_state.dart';

class GroupBloc extends Bloc<GroupEvent, GroupState> {
  final GroupRepository _groupRepository;
  StreamSubscription<List<GroupModel>>? _groupsSubscription;

  GroupBloc({required GroupRepository groupRepository})
    : _groupRepository = groupRepository,
      super(const GroupState()) {
    on<GroupsSubscriptionRequested>(_onSubscriptionRequested);
    on<GroupsUpdated>(_onGroupsUpdated);
    on<GroupsErrorOccurred>(_onErrorOccurred);
    on<GroupsResetRequested>(_onResetRequested);
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
          onError: (_) => add(
            const GroupsErrorOccurred(),
          ), // dispatch event, don't emit directly
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

  void _onErrorOccurred(GroupsErrorOccurred event, Emitter<GroupState> emit) {
    emit(state.copyWith(status: GroupStatus.error));
  }

  void _onResetRequested(GroupsResetRequested event, Emitter<GroupState> emit) {
    emit(const GroupState());
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

  /// Called on logout to stop listening before the auth session is gone
  Future<void> resetSubscription() async {
    await _groupsSubscription?.cancel();
    _groupsSubscription = null;
    add(const GroupsResetRequested());
  }

  @override
  Future<void> close() {
    _groupsSubscription?.cancel();
    return super.close();
  }
}
