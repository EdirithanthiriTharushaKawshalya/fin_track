import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/transaction_model.dart';

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
}
