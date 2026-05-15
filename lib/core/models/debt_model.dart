import 'package:cloud_firestore/cloud_firestore.dart';

class DebtModel {
  final String id;
  final String userId;
  final String personName;
  final double amount;
  final double paidAmount; // Added for installments
  final String type; // 'borrowed' (I owe) or 'lent' (Owed to me)
  final DateTime dueDate;
  final String? accountId;

  DebtModel({
    required this.id,
    required this.userId,
    required this.personName,
    required this.amount,
    this.paidAmount = 0.0,
    required this.type,
    required this.dueDate,
    this.accountId,
  });

  double get remainingAmount => amount - paidAmount;
  bool get isSettled => paidAmount >= amount;

  factory DebtModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return DebtModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      personName: data['personName'] ?? 'Unknown',
      amount: (data['amount'] ?? 0.0).toDouble(),
      paidAmount: (data['paidAmount'] ?? 0.0).toDouble(),
      type: data['type'] ?? 'borrowed',
      dueDate: (data['dueDate'] as Timestamp).toDate(),
      accountId: data['accountId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'personName': personName,
      'amount': amount,
      'paidAmount': paidAmount,
      'type': type,
      'dueDate': Timestamp.fromDate(dueDate),
      'accountId': accountId,
    };
  }
}
