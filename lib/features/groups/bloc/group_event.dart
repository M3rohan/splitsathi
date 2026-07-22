import 'package:equatable/equatable.dart';

abstract class GroupEvent extends Equatable {
  const GroupEvent();

  @override
  List<Object?> get props => [];
}

class GroupsSubscriptionRequested extends GroupEvent {
  final String userId;
  const GroupsSubscriptionRequested(this.userId);

  @override
  List<Object?> get props => [userId];
}

class GroupsUpdated extends GroupEvent {
  final List<dynamic> groups;
  const GroupsUpdated(this.groups);

  @override
  List<Object?> get props => [groups];
}

class GroupCreateRequested extends GroupEvent {
  final String name;
  final String createdBy;
  final List<String> memberIds;
  final String? emoji;

  const GroupCreateRequested({
    required this.name,
    required this.createdBy,
    required this.memberIds,
    this.emoji,
  });

  @override
  List<Object?> get props => [name, createdBy, memberIds, emoji];
}
