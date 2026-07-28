import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:splitsathi/features/expenses/models/expense_model.dart';

class ExpenseRepository {
  final FirebaseFirestore _firebaseFirestore;

  const ExpenseRepository({required FirebaseFirestore firestore})
    : _firebaseFirestore = firestore;

  CollectionReference _expensesRef(String groupId) => _firebaseFirestore
      .collection('groups')
      .doc(groupId)
      .collection('expenses');

  Stream<List<ExpenseModel>> watchExpenses(String groupId) {
    return _expensesRef(groupId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ExpenseModel.fromFireStore(doc))
              .toList(),
        );
  }

  Future<void> addExpense(ExpenseModel expense) async {
    await _expensesRef(expense.groupId).add(expense.toFirestore());
  }

  Future<void> deleteExpense(String groupId, String expenseId) async {
    await _expensesRef(groupId).doc(expenseId).delete();
  }
}
