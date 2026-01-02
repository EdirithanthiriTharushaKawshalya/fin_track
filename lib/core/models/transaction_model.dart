import 'package:cloud_firestore/cloud_firestore.dart';

class TransactionModel {
  final String id;
  final String userId;
  final double amount;
  final String type; // 'income' or 'expense'
  final String category; // e.g., 'Food', 'Salary', 'Rent'
  final DateTime date;
  final String? note;
  final String? accountId; // NEW: Added accountId field

  TransactionModel({
    required this.id,
    required this.userId,
    required this.amount,
    required this.type,
    required this.category,
    required this.date,
    this.note,
    this.accountId, // NEW: Added accountId parameter
  });

  // Convert Firebase Document to Dart Object
  factory TransactionModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return TransactionModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      amount: (data['amount'] ?? 0.0).toDouble(),
      type: data['type'] ?? 'expense',
      category: data['category'] ?? 'General',
      date: (data['date'] as Timestamp).toDate(),
      note: data['note'],
      accountId: data['accountId'], // NEW: Include accountId from Firestore
    );
  }

  // Convert Dart Object to Firebase Map
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'amount': amount,
      'type': type,
      'category': category,
      'date': Timestamp.fromDate(date),
      'note': note,
      'accountId': accountId, // NEW: Include accountId in toMap
    };
  }
}
