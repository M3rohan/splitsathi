import 'package:cloud_firestore/cloud_firestore.dart';

class ExpenseModel {
  final String id;
  final String groupId;
  final String description;
  final double amount;
  final String paidBy;
  final List<String> splitBetween;
  final String splitType;
  final Map<String, double>? customSplits;
  final String category;
  final DateTime? createdAt;

  ExpenseModel({
    required this.id,
    required this.groupId,
    required this.description,
    required this.amount,
    required this.paidBy,
    required this.splitBetween,
    this.splitType = 'equal',
    this.customSplits,
    this.category = 'general',
    this.createdAt,
  });

  factory ExpenseModel.fromFireStore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ExpenseModel(
      id: doc.id,
      groupId: data['groupId'] ?? '',
      description: data['description'] ?? '',
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      paidBy: data['paidBy'] ?? '',
      splitBetween: List<String>.from(data['splitBetween'] ?? []),
      splitType: data['splitType'] ?? 'equal',
      customSplits: data['customSplits'] != null
          ? Map<String, double>.from(
              (data['customSplits'] as Map).map(
                (k, v) => MapEntry(k, (v as num).toDouble()),
              ),
            )
          : null,
      category: data['category'] ?? 'general',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'groupId': groupId,
      'description': description,
      'amount': amount,
      'paidBy': paidBy,
      'splitBetween': splitBetween,
      'splitType': splitType,
      'customSplits': customSplits,
      'category': category,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  /// Amount each person owes for this specific expense
  double amountPerPerson(String userId) {
    if (splitType == 'custom' && customSplits != null) {
      return customSplits![userId] ?? 0.0;
    }
    if (splitBetween.isEmpty) return 0.0;
    return amount / splitBetween.length;
  }
}
