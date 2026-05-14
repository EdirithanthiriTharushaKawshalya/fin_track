import 'package:cloud_firestore/cloud_firestore.dart';

class TransactionModel {
  final String id;
  final String userId;
  final double amount;
  final double fee; // NEW: Added fee field
  final String type; // 'income', 'expense', or 'transfer'
  final String category; // e.g., 'Food', 'Salary', 'Rent'
  final DateTime date;
  final String? note;
  final String? accountId; 
  final String? fromAccountId; // NEW: Added for transfers
  final String? toAccountId;   // NEW: Added for transfers
  final String? relatedId;     // NEW: Link to Debt or other entities

  TransactionModel({
    required this.id,
    required this.userId,
    required this.amount,
    this.fee = 0.0, // Default to 0.0
    required this.type,
    required this.category,
    required this.date,
    this.note,
    this.accountId,
    this.fromAccountId,
    this.toAccountId,
    this.relatedId,
  });

  // Convert Firebase Document to Dart Object
  factory TransactionModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return TransactionModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      amount: (data['amount'] ?? 0.0).toDouble(),
      fee: (data['fee'] ?? 0.0).toDouble(), // NEW: Include fee
      type: data['type'] ?? 'expense',
      category: data['category'] ?? 'General',
      date: (data['date'] as Timestamp).toDate(),
      note: data['note'],
      accountId: data['accountId'],
      fromAccountId: data['fromAccountId'], // NEW: Include fromAccountId
      toAccountId: data['toAccountId'],     // NEW: Include toAccountId
      relatedId: data['relatedId'],         // NEW: Include relatedId
    );
  }

  // Convert Dart Object to Firebase Map
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'amount': amount,
      'fee': fee, // NEW: Include fee
      'type': type,
      'category': category,
      'date': Timestamp.fromDate(date),
      'note': note,
      'accountId': accountId,
      'fromAccountId': fromAccountId, // NEW: Include fromAccountId
      'toAccountId': toAccountId,     // NEW: Include toAccountId
      'relatedId': relatedId,         // NEW: Include relatedId
    };
  }
}
