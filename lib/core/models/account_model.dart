import 'package:cloud_firestore/cloud_firestore.dart';

class AccountModel {
  final String id;
  final String userId;
  final String name; // e.g., "HNB Bank", "Commercial Bank", "Wallet"
  final double currentBalance;
  final String type; // 'bank', 'wallet', 'card'
  final int colorCode; // Store color as int (e.g., 0xFF00FF00)

  AccountModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.currentBalance,
    required this.type,
    required this.colorCode,
  });

  factory AccountModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return AccountModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      name: data['name'] ?? 'Unknown Account',
      currentBalance: (data['currentBalance'] ?? 0.0).toDouble(),
      type: data['type'] ?? 'bank',
      colorCode: data['colorCode'] ?? 0xFFBB86FC,
    );
  }
}
