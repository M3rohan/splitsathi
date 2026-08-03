import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:splitsathi/features/notifications/models/notification_model.dart';

class NotificationRepository {
  final FirebaseFirestore _firestore;

  NotificationRepository({required FirebaseFirestore firestore})
    : _firestore = firestore;

  CollectionReference _notificationsRef(String userId) =>
      _firestore.collection('users').doc(userId).collection('notifications');

  Stream<List<NotificationModel>> watchNotifications(String userId) {
    return _notificationsRef(userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => NotificationModel.fromFirestore(doc))
              .toList(),
        );
  }

  Future<void> notifyNewExpense({
    required List<String> memberIds,
    required String excludeUserId,
    required String actorName,
    required String groupId,
    required String groupName,
    required String expenseId,
    required String description,
    required double amount,
  }) async {
    final recipients = memberIds.where((id) => id != excludeUserId).toList();
    if (recipients.isEmpty) return;

    final batch = _firestore.batch();
    for (final memberId in recipients) {
      final docRef = _notificationsRef(memberId).doc();
      batch.set(docRef, {
        'type': 'expense_added',
        'title': groupName,
        'body':
            '$actorName added ₹${amount.toStringAsFixed(0)} for $description',
        'groupId': groupId,
        'expenseId': expenseId,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  Future<void> markAsRead(String userId, String notificationId) async {
    await _notificationsRef(
      userId,
    ).doc(notificationId).update({'isRead': true});
  }

  Future<void> markAllAsRead(String userId) async {
    final snapshot = await _notificationsRef(
      userId,
    ).where('isRead', isEqualTo: false).get();
    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }
}
