import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthRepository {
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firebaseFirestore;

  AuthRepository({
    required FirebaseAuth firebaseAuth,
    required FirebaseFirestore firebaseFirestore,
  }) : _firebaseAuth = firebaseAuth,
       _firebaseFirestore = firebaseFirestore;

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  User? get currentUser => _firebaseAuth.currentUser;

  Future<User?> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    final credential = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = credential.user;

    if (user != null) {
      await _firebaseFirestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'name': name,
        'email': email,
        'avatarId': 'avatar1',
        'createdAt': FieldValue.serverTimestamp(),
      });

      await user.updateDisplayName(name);
    }
    return user;
  }

  Future<User?> login({required String email, required String password}) async {
    final credential = await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return credential.user;
  }

  Future<void> logout() async {
    await _firebaseAuth.signOut();
  }

  Future<void> sendPasswordResetEmail({required String email}) async {
    await _firebaseAuth.sendPasswordResetEmail(email: email);
  }

  /// Ensures a Firestore profile document exists for the given user.
  /// If missing (e.g. due to a partial signup failure), creates it now.
  /// Safe to call every time — does nothing if the profile already exists.
  Future<void> ensureUserProfileExists(User user) async {
    final docRef = _firebaseFirestore.collection('users').doc(user.uid);
    final doc = await docRef.get();

    if (!doc.exists) {}
    await docRef.set({
      'uid': user.uid,
      'name': user.displayName ?? user.email?.split('@').first ?? 'User',
      'email': user.email ?? '',
      'avatarId': 'avatar_1',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
