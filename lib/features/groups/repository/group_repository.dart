import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:splitsathi/core/constants/group_icons.dart';
import 'package:splitsathi/features/groups/models/group_model.dart';

class GroupRepository {
  final FirebaseFirestore _firestore;
  GroupRepository({required FirebaseFirestore firestore})
    : _firestore = firestore;

  CollectionReference get _groupsRef => _firestore.collection('groups');

  Stream<List<GroupModel>> getUserGroups(String userId) {
    return _groupsRef
        .where('memberIds', arrayContains: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => GroupModel.fromFireStore(doc))
              .toList(),
        );
  }

  Future<GroupModel> createGroup({
    required String name,
    required String createdBy,
    required List<String> memberIds,
    String? emoji,
  }) async {
    final docRef = await _groupsRef.add({
      'name': name,
      'createdBy': createdBy,
      'memberIds': memberIds,
      'createdAt': FieldValue.serverTimestamp(),
      'emoji': emoji ?? GroupIcons.defaultIcon,
    });

    final doc = await docRef.get();
    return GroupModel.fromFireStore(doc);
  }

  Future<GroupModel?> getGroupById(String groupId) async {
    final doc = await _groupsRef.doc(groupId).get();
    if (!doc.exists) return null;

    return GroupModel.fromFireStore(doc);
  }

  Future<String?> findUserIdByEmail(String email) async {
    final query = await _firestore
        .collection('users')
        .where('email', isEqualTo: email.trim().toLowerCase())
        .limit(1)
        .get();

    if (query.docs.isEmpty) return null;
    return query.docs.first.id;
  }

  Future<void> addMemberToGroup(String groupId, String userId) async {
    await _groupsRef.doc(groupId).update({
      'memberIds': FieldValue.arrayUnion([userId]),
    });
  }

  Future<void> removeMemberFromGroup(String groupId, String userId) async {
    await _groupsRef.doc(groupId).update({
      'memberIds': FieldValue.arrayRemove([userId]),
    });
  }

  Future<void> deleteGroup(String groupId) async {
    await _groupsRef.doc(groupId).delete();
  }

  // Real-time stream of a single group's data (reflects member changes, name edits, etc.)
  Stream<GroupModel?> watchGroup(String groupId) {
    return _groupsRef.doc(groupId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return GroupModel.fromFireStore(doc);
    });
  }

  // Fetch member profile info (name, avatar) for a list of UIDs — needed to display member list
  Future<List<Map<String, dynamic>>> getMembersInfo(
    List<String> memberIds,
  ) async {
    if (memberIds.isEmpty) return [];
    final snapshot = await _firestore
        .collection('users')
        .where(FieldPath.documentId, whereIn: memberIds)
        .get();

    return snapshot.docs.map((doc) => {'uid': doc.id, ...doc.data()}).toList();
  }
}
