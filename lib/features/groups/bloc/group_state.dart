import 'package:equatable/equatable.dart';
import 'package:splitsathi/features/groups/models/group_model.dart';

enum GroupStatus { initial, loading, loaded, creating, created, error }

class GroupState extends Equatable {
  final GroupStatus status;
  final List<GroupModel> groups;
  final String? errorMessage;

  const GroupState({
    this.status = GroupStatus.initial,
    this.groups = const [],
    this.errorMessage,
  });

  GroupState copyWith({
    GroupStatus? status,
    List<GroupModel>? groups,
    String? errorMessage,
  }) {
    return GroupState(
      status: status ?? this.status,
      groups: groups ?? this.groups,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, groups, errorMessage];
}
