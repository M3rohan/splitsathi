import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:splitsathi/features/groups/models/group_model.dart';
import 'package:splitsathi/features/groups/repository/group_repository.dart';

enum GroupDetailStatus { loading, loaded, notFound, error }

class GroupDetailState extends Equatable {
  final GroupDetailStatus status;
  final GroupModel? group;
  final List<Map<String, dynamic>> members;

  const GroupDetailState({
    this.status = GroupDetailStatus.loading,
    this.group,
    this.members = const [],
  });

  GroupDetailState copyWith({
    GroupDetailStatus? status,
    GroupModel? group,
    List<Map<String, dynamic>>? members,
  }) {
    return GroupDetailState(
      status: status ?? this.status,
      group: group ?? this.group,
      members: members ?? this.members,
    );
  }

  @override
  List<Object?> get props => [status, group, members];
}

class GroupDetailCubit extends Cubit<GroupDetailState> {
  final GroupRepository _groupRepository;
  StreamSubscription<GroupModel?>? _groupSubscription;

  GroupDetailCubit({required GroupRepository groupRepository})
    : _groupRepository = groupRepository,
      super(const GroupDetailState());

  void watchGroup(String groupId) {
    _groupSubscription?.cancel();
    _groupSubscription = _groupRepository
        .watchGroup(groupId)
        .listen(
          (group) async {
            if (group == null) {
              emit(state.copyWith(status: GroupDetailStatus.notFound));
              return;
            }

            final members = await _groupRepository.getMembersInfo(
              group.memberIds,
            );
            emit(
              state.copyWith(
                status: GroupDetailStatus.loaded,
                group: group,
                members: members,
              ),
            );
          },
          onError: (_) {
            emit(state.copyWith(status: GroupDetailStatus.error));
          },
        );
  }

  @override
  Future<void> close() {
    _groupSubscription?.cancel();
    return super.close();
  }
}
