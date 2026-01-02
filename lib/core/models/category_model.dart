import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CategoryModel {
  final String id;
  final String userId;
  final String name;
  final String type; // 'income' or 'expense'
  final int iconCode; // We store the IconData code point (e.g., 0xe57a)
  final int colorCode;

  CategoryModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.type,
    required this.iconCode,
    required this.colorCode,
  });

  factory CategoryModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return CategoryModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      name: data['name'] ?? 'General',
      type: data['type'] ?? 'expense',
      iconCode: data['iconCode'] ?? Icons.category.codePoint,
      colorCode: data['colorCode'] ?? 0xFF9E9E9E,
    );
  }
}
