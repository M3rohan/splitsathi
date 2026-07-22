import 'package:equatable/equatable.dart';
import 'package:splitsathi/core/constants/group_icons.dart';

class CreateGroupFormState extends Equatable {
  final String selectedEmoji;
  final List<String> memberEmails;
  final String? memberError;
  final bool isAddingMember;

  const CreateGroupFormState({
    this.selectedEmoji = GroupIcons.defaultIcon,
    this.memberEmails = const [],
    this.memberError,
    this.isAddingMember = false,
  });

  CreateGroupFormState copyWith({
    String? selectedEmoji,
    List<String>? memberEmails,
    String? memberError,
    bool? isAddingMember,
  }) {
    return CreateGroupFormState(
      selectedEmoji: selectedEmoji ?? this.selectedEmoji,
      memberEmails: memberEmails ?? this.memberEmails,
      memberError: memberError ?? this.memberError,
      isAddingMember: isAddingMember ?? this.isAddingMember,
    );
  }

  @override
  List<Object?> get props => [
    selectedEmoji,
    memberEmails,
    memberError,
    isAddingMember,
  ];
}
