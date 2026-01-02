import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/transaction_model.dart';
import '../models/goal_model.dart';
import '../models/debt_model.dart';
import '../models/account_model.dart';
import '../models/category_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID
  String get _userId => _auth.currentUser!.uid;

  // --- ACCOUNTS SECTION ---

  Future<void> addAccount({
    required String name,
    required double initialBalance,
    required String type,
    required int colorCode,
  }) async {
    await _db.collection('accounts').add({
      'userId': _userId,
      'name': name,
      'currentBalance': initialBalance,
      'type': type,
      'colorCode': colorCode,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<AccountModel>> getAccounts() {
    return _db
        .collection('accounts')
        .where('userId', isEqualTo: _userId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => AccountModel.fromFirestore(doc))
              .toList(),
        );
  }

  // DELETE ACCOUNT
  Future<void> deleteAccount(String id) async {
    await _db.collection('accounts').doc(id).delete();
  }

  // --- UPDATED TRANSACTION LOGIC (CRITICAL) ---

  // We overwrite the old addTransaction to handle Account Balances
  Future<void> addTransactionWithAccount({
    required double amount,
    required String type, // 'income' or 'expense'
    required String category,
    required DateTime date,
    required String accountId, // NEW: Which account?
    String? note,
  }) async {
    final batch = _db
        .batch(); // Use a Batch to ensure both happen or neither happens

    // 1. Create the Transaction Ref
    final transactionRef = _db.collection('transactions').doc();
    batch.set(transactionRef, {
      'userId': _userId,
      'amount': amount,
      'type': type,
      'category': category,
      'date': Timestamp.fromDate(date),
      'accountId': accountId, // Link it
      'note': note,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // 2. Update the Account Balance Ref
    final accountRef = _db.collection('accounts').doc(accountId);
    if (type == 'income') {
      batch.update(accountRef, {
        'currentBalance': FieldValue.increment(amount),
      });
    } else {
      batch.update(accountRef, {
        'currentBalance': FieldValue.increment(-amount),
      });
    }

    await batch.commit(); // Run both updates instantly
  }

  // Original addTransaction method (keep for backward compatibility if needed)
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

  // --- TRANSACTIONS (Advanced Logic) ---

  // DELETE TRANSACTION (With Refund Logic)
  Future<void> deleteTransaction(TransactionModel transaction) async {
    final batch = _db.batch();

    // 1. Delete the transaction record
    final transactionRef = _db.collection('transactions').doc(transaction.id);
    batch.delete(transactionRef);

    // 2. Reverse the money (Refund the account)
    if (transaction.accountId != null && transaction.accountId!.isNotEmpty) {
      final accountRef = _db.collection('accounts').doc(transaction.accountId);

      if (transaction.type == 'income') {
        // If we delete an INCOME, we SUBTRACT money from account
        batch.update(accountRef, {
          'currentBalance': FieldValue.increment(-transaction.amount),
        });
      } else {
        // If we delete an EXPENSE, we ADD money back to account
        batch.update(accountRef, {
          'currentBalance': FieldValue.increment(transaction.amount),
        });
      }
    }

    await batch.commit();
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

  // --- CATEGORIES SECTION ---

  Future<void> addCategory({
    required String name,
    required String type,
    required int iconCode,
    required int colorCode,
  }) async {
    await _db.collection('categories').add({
      'userId': _userId,
      'name': name,
      'type': type,
      'iconCode': iconCode,
      'colorCode': colorCode,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteCategory(String id) async {
    await _db.collection('categories').doc(id).delete();
  }

  Stream<List<CategoryModel>> getCategories() {
    return _db
        .collection('categories')
        .where('userId', isEqualTo: _userId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => CategoryModel.fromFirestore(doc))
              .toList(),
        );
  }
}
