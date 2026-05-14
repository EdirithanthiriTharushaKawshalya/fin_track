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
      final bool oldActsAsIncome = transaction.type == 'income' || 
                                    transaction.type == 'debt_borrowed' || 
                                    transaction.type == 'debt_repayment_received';
                                    
      final oldAccountRef = _db.collection('accounts').doc(transaction.accountId);
      batch.update(oldAccountRef, {
        'currentBalance': FieldValue.increment(oldActsAsIncome ? -transaction.amount : transaction.amount),
      });
    }

    // 2. Apply the effect of the new transaction values on the new account
    final bool newActsAsIncome = type == 'income' || 
                                  type == 'debt_borrowed' || 
                                  type == 'debt_repayment_received';
                                  
    final newAccountRef = _db.collection('accounts').doc(accountId);
    batch.update(newAccountRef, {
      'currentBalance': FieldValue.increment(newActsAsIncome ? amount : -amount),
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
      // Determine if this transaction increased or decreased the balance
      final bool actsAsIncome = transaction.type == 'income' || 
                                 transaction.type == 'debt_borrowed' || 
                                 transaction.type == 'debt_repayment_received';
      
      final accountRef = _db.collection('accounts').doc(transaction.accountId);
      batch.update(accountRef, {
        'currentBalance': FieldValue.increment(actsAsIncome ? -transaction.amount : transaction.amount),
      });

      // Professional Cleanup: If we delete the initial debt transaction, we should also remove the debt record
      // to maintain system integrity.
      if ((transaction.type == 'debt_lent' || transaction.type == 'debt_borrowed') && transaction.relatedId != null) {
        batch.delete(_db.collection('debts').doc(transaction.relatedId));
      }
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

  Future<void> addDebt({
    required String personName,
    required double amount,
    required String type,
    required DateTime dueDate,
    String? accountId,
  }) async {
    final batch = _db.batch();
    final debtRef = _db.collection('debts').doc();
    
    batch.set(debtRef, {
      'userId': _userId,
      'personName': personName,
      'amount': amount,
      'type': type,
      'dueDate': Timestamp.fromDate(dueDate),
      'accountId': accountId,
      'createdAt': FieldValue.serverTimestamp(),
    });

    if (accountId != null && accountId.isNotEmpty) {
      final accountRef = _db.collection('accounts').doc(accountId);
      // If lent (giving money), deduct from account. If borrowed (receiving money), add to account.
      batch.update(accountRef, {
        'currentBalance': FieldValue.increment(type == 'lent' ? -amount : amount),
      });

      // Add a transaction record for the homepage
      final transactionRef = _db.collection('transactions').doc();
      batch.set(transactionRef, {
        'userId': _userId,
        'amount': amount,
        'type': type == 'lent' ? 'debt_lent' : 'debt_borrowed',
        'category': type == 'lent' ? 'Money Lent' : 'Money Borrowed',
        'date': Timestamp.now(),
        'accountId': accountId,
        'note': type == 'lent' ? 'Lent money to $personName' : 'Borrowed money from $personName',
        'relatedId': debtRef.id, // LINKED HERE
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }

  Future<void> settleDebt({
    required DebtModel debt,
    required String accountId,
  }) async {
    final batch = _db.batch();
    
    // 1. Delete the debt
    batch.delete(_db.collection('debts').doc(debt.id));

    // 2. Update account balance
    // If it was lent, receiving it back adds to balance.
    // If it was borrowed, paying it back deducts from balance.
    final accountRef = _db.collection('accounts').doc(accountId);
    batch.update(accountRef, {
      'currentBalance': FieldValue.increment(debt.type == 'lent' ? debt.amount : -debt.amount),
    });

    // 3. Record repayment transaction
    final transactionRef = _db.collection('transactions').doc();
    batch.set(transactionRef, {
      'userId': _userId,
      'amount': debt.amount,
      'type': debt.type == 'lent' ? 'debt_repayment_received' : 'debt_repayment_paid',
      'category': debt.type == 'lent' ? 'Debt Repayment' : 'Debt Paid',
      'date': Timestamp.now(),
      'accountId': accountId,
      'note': debt.type == 'lent' ? 'Received repayment from ${debt.personName}' : 'Repaid debt to ${debt.personName}',
      'relatedId': debt.id, // LINKED HERE
      'createdAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
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