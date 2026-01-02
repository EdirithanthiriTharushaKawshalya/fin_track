import 'package:cloud_firestore/cloud_firestore.dart';

class DebtModel {
  final String id;
  final String userId;
  final String personName;
  final double amount;
  final String type; // 'borrowed' (I owe) or 'lent' (Owed to me)
  final DateTime dueDate;

  DebtModel({
    required this.id,
    required this.userId,
    required this.personName,
    required this.amount,
    required this.type,
    required this.dueDate,
  });

  factory DebtModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return DebtModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      personName: data['personName'] ?? 'Unknown',
      amount: (data['amount'] ?? 0.0).toDouble(),
      type: data['type'] ?? 'borrowed',
      dueDate: (data['dueDate'] as Timestamp).toDate(),
    );
  }
}
