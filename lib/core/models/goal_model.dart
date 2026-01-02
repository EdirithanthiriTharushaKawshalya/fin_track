import 'package:cloud_firestore/cloud_firestore.dart';

class GoalModel {
  final String id;
  final String userId;
  final String title;
  final double targetAmount;
  final double savedAmount;
  final DateTime deadline;

  GoalModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.targetAmount,
    required this.savedAmount,
    required this.deadline,
  });

  factory GoalModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return GoalModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? 'New Goal',
      targetAmount: (data['targetAmount'] ?? 0.0).toDouble(),
      savedAmount: (data['savedAmount'] ?? 0.0).toDouble(),
      deadline: (data['deadline'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'targetAmount': targetAmount,
      'savedAmount': savedAmount,
      'deadline': Timestamp.fromDate(deadline),
    };
  }
}
