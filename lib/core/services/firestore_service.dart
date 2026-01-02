import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/transaction_model.dart';
import '../models/goal_model.dart';
import '../models/debt_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID
  String get _userId => _auth.currentUser!.uid;

  // Add a Transaction
  Future<void> addTransaction({
    required double amount,
    required String type,
    required String category,
    required DateTime date,
    String? note,
  }) async {
    try {
      await _db.collection('transactions').add({
        'userId': _userId, // IMPORTANT: Link data to the user
        'amount': amount,
        'type': type,
        'category': category,
        'date': Timestamp.fromDate(date),
        'note': note,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to add transaction: $e');
    }
  }

  // Stream of Transactions (Real-time updates)
  Stream<List<TransactionModel>> getTransactions() {
    return _db
        .collection('transactions')
        .where('userId', isEqualTo: _userId) // SECURITY: Only get MY data
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => TransactionModel.fromFirestore(doc))
              .toList(),
        );
  }

  // Delete a Transaction
  Future<void> deleteTransaction(String id) async {
    try {
      await _db.collection('transactions').doc(id).delete();
    } catch (e) {
      throw Exception('Failed to delete transaction: $e');
    }
  }

  // --- GOALS SECTION ---

  // Add a Goal
  Future<void> addGoal({
    required String title,
    required double targetAmount,
    required DateTime deadline,
  }) async {
    await _db.collection('goals').add({
      'userId': _userId,
      'title': title,
      'targetAmount': targetAmount,
      'savedAmount': 0.0, // Start with 0
      'deadline': Timestamp.fromDate(deadline),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Update Saved Amount (Deposit money into goal)
  Future<void> updateGoalProgress(String goalId, double newSavedAmount) async {
    await _db.collection('goals').doc(goalId).update({
      'savedAmount': newSavedAmount,
    });
  }

  // Delete Goal
  Future<void> deleteGoal(String goalId) async {
    await _db.collection('goals').doc(goalId).delete();
  }

  // Stream Goals
  Stream<List<GoalModel>> getGoals() {
    return _db
        .collection('goals')
        .where('userId', isEqualTo: _userId)
        .orderBy('deadline', descending: false) // Soonest deadline first
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => GoalModel.fromFirestore(doc)).toList(),
        );
  }

  // --- DEBTS SECTION ---

  Future<void> addDebt({
    required String personName,
    required double amount,
    required String type, // 'borrowed' or 'lent'
    required DateTime dueDate,
  }) async {
    await _db.collection('debts').add({
      'userId': _userId,
      'personName': personName,
      'amount': amount,
      'type': type,
      'dueDate': Timestamp.fromDate(dueDate),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteDebt(String id) async {
    await _db.collection('debts').doc(id).delete();
  }

  Stream<List<DebtModel>> getDebts() {
    return _db
        .collection('debts')
        .where('userId', isEqualTo: _userId)
        .orderBy('dueDate', descending: false) // Soonest due first
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => DebtModel.fromFirestore(doc)).toList(),
        );
  }
}
