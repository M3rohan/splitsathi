import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:splitsathi/core/constants/group_icons.dart';

class GroupModel {
  final String id;
  final String name;
  final String createdBy;
  final List<String> memberIds;
  final DateTime? createdAt;
  final String? emoji;

  GroupModel({
    required this.id,
    required this.name,
    required this.createdBy,
    required this.memberIds,
    this.createdAt,
    this.emoji,
  });

  factory GroupModel.fromFireStore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return GroupModel(
      id: doc.id,
      name: data['name'] ?? '',
      createdBy: data['createdBy'] ?? '',
      memberIds: List<String>.from(data['memberIds'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      emoji: data['emoji'] ?? GroupIcons.defaultIcon,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'createdBy': createdBy,
      'memberIds': memberIds,
      'createdAt': FieldValue.serverTimestamp(),
      'emoji': emoji ?? GroupIcons.defaultIcon,
    };
  }
}
