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
        .map((snapshot) => snapshot.docs.map((doc) => AccountModel.fromFirestore(doc)).toList());
  }

  Future<void> deleteAccount(String id) async {
    await _db.collection('accounts').doc(id).delete();
  }

  // --- TRANSACTION LOGIC ---
  Future<void> addTransactionWithAccount({
    required double amount,
    required String type,
    required String category,
    required DateTime date,
    required String accountId,
    String? note,
  }) async {
    final batch = _db.batch();
    final transactionRef = _db.collection('transactions').doc();
    
    batch.set(transactionRef, {
      'userId': _userId,
      'amount': amount,
      'type': type,
      'category': category,
      'date': Timestamp.fromDate(date),
      'accountId': accountId,
      'note': note ?? "",
      'createdAt': FieldValue.serverTimestamp(),
    });

    final accountRef = _db.collection('accounts').doc(accountId);
    batch.update(accountRef, {
      'currentBalance': FieldValue.increment(type == 'income' ? amount : -amount),
    });

    await batch.commit();
  }

  Stream<List<TransactionModel>> getTransactions() {
    return _db
        .collection('transactions')
        .where('userId', isEqualTo: _userId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => TransactionModel.fromFirestore(doc)).toList());
  }

  Future<void> updateTransaction({
    required TransactionModel transaction,
    required double amount,
    required String type,
    required String category,
    required String accountId,
    String? note,
  }) async {
    final batch = _db.batch();
    
    // 1. Reverse the effect of the old transaction on the old account
    if (transaction.accountId != null) {
      final oldAccountRef = _db.collection('accounts').doc(transaction.accountId);
      batch.update(oldAccountRef, {
        'currentBalance': FieldValue.increment(transaction.type == 'income' ? -transaction.amount : transaction.amount),
      });
    }

    // 2. Apply the effect of the new transaction values on the new account
    final newAccountRef = _db.collection('accounts').doc(accountId);
    batch.update(newAccountRef, {
      'currentBalance': FieldValue.increment(type == 'income' ? amount : -amount),
    });

    // 3. Update the transaction document
    final transactionRef = _db.collection('transactions').doc(transaction.id);
    batch.update(transactionRef, {
      'amount': amount,
      'type': type,
      'category': category,
      'accountId': accountId,
      'note': note ?? "",
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  Future<void> deleteTransaction(TransactionModel transaction) async {
    final batch = _db.batch();
    batch.delete(_db.collection('transactions').doc(transaction.id));

    if (transaction.type == 'transfer') {
      // Reverse transfer: Add (amount + fee) back to source, deduct amount from destination
      if (transaction.fromAccountId != null) {
        batch.update(_db.collection('accounts').doc(transaction.fromAccountId), {
          'currentBalance': FieldValue.increment(transaction.amount + transaction.fee),
        });
      }
      if (transaction.toAccountId != null) {
        batch.update(_db.collection('accounts').doc(transaction.toAccountId), {
          'currentBalance': FieldValue.increment(-transaction.amount),
        });
      }
    } else if (transaction.accountId != null && transaction.accountId!.isNotEmpty) {
      // Standard income/expense reversal
      final accountRef = _db.collection('accounts').doc(transaction.accountId);
      batch.update(accountRef, {
        'currentBalance': FieldValue.increment(transaction.type == 'income' ? -transaction.amount : transaction.amount),
      });
    }
    await batch.commit();
  }

  // --- TRANSFER LOGIC ---
  Future<void> transferMoney({
    required String fromAccountId,
    required String toAccountId,
    required double amount,
    double fee = 0.0,
  }) async {
    final batch = _db.batch();
    
    // Deduct amount + fee from source account
    batch.update(_db.collection('accounts').doc(fromAccountId), {
      'currentBalance': FieldValue.increment(-(amount + fee))
    });
    
    // Add only amount to destination account
    batch.update(_db.collection('accounts').doc(toAccountId), {
      'currentBalance': FieldValue.increment(amount)
    });

    batch.set(_db.collection('transactions').doc(), {
      'userId': _userId,
      'amount': amount,
      'fee': fee,
      'type': 'transfer',
      'category': 'Transfer',
      'date': Timestamp.now(),
      'note': fee > 0 ? 'Internal Transfer (Fee: Rs $fee)' : 'Internal Transfer',
      'fromAccountId': fromAccountId,
      'toAccountId': toAccountId,
      'createdAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

  // --- GOALS, DEBTS, CATEGORIES (Existing Implementations) ---
  Future<void> addGoal({required String title, required double targetAmount, required DateTime deadline}) async {
    await _db.collection('goals').add({
      'userId': _userId, 'title': title, 'targetAmount': targetAmount, 'savedAmount': 0.0,
      'deadline': Timestamp.fromDate(deadline), 'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateGoalProgress(String goalId, double newSavedAmount) async {
    await _db.collection('goals').doc(goalId).update({'savedAmount': newSavedAmount});
  }

  Future<void> deleteGoal(String goalId) async {
    await _db.collection('goals').doc(goalId).delete();
  }

  Stream<List<GoalModel>> getGoals() {
    return _db.collection('goals').where('userId', isEqualTo: _userId).snapshots()
        .map((s) => s.docs.map((doc) => GoalModel.fromFirestore(doc)).toList());
  }

  Future<void> addDebt({required String personName, required double amount, required String type, required DateTime dueDate}) async {
    await _db.collection('debts').add({
      'userId': _userId, 'personName': personName, 'amount': amount, 'type': type,
      'dueDate': Timestamp.fromDate(dueDate), 'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteDebt(String id) async { await _db.collection('debts').doc(id).delete(); }

  Stream<List<DebtModel>> getDebts() {
    return _db.collection('debts').where('userId', isEqualTo: _userId).orderBy('dueDate', descending: false).snapshots()
        .map((s) => s.docs.map((doc) => DebtModel.fromFirestore(doc)).toList());
  }

  Future<void> addCategory({required String name, required String type, required int iconCode, required int colorCode}) async {
    await _db.collection('categories').add({
      'userId': _userId, 'name': name, 'type': type, 'iconCode': iconCode, 'colorCode': colorCode,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteCategory(String id) async { await _db.collection('categories').doc(id).delete(); }

  Stream<List<CategoryModel>> getCategories() {
    return _db.collection('categories').where('userId', isEqualTo: _userId).snapshots()
        .map((s) => s.docs.map((doc) => CategoryModel.fromFirestore(doc)).toList());
  }
}