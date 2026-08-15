import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileRepository {
  final FirebaseFirestore _firestore;

  ProfileRepository({required FirebaseFirestore firestore})
    : _firestore = firestore;

  Stream<Map<String, dynamic>?> watchProfile(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((doc) => doc.data());
  }

  Future<void> updateAvatar(String userId, String avatarId) async {
    await _firestore.collection('users').doc(userId).update({
      'avatarId': avatarId,
    });
  }

  Future<void> updateName(String userId, String name) async {
    await _firestore.collection('users').doc(userId).update({'name': name});
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null && currentUser.uid == userId) {
      await currentUser.updateDisplayName(name);
    }
  }
}
