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

  static IconData getIconData(int code) {
    // List of all possible category icons used in the app
    const List<IconData> categoryIcons = [
      Icons.fastfood,
      Icons.directions_car,
      Icons.shopping_bag,
      Icons.home,
      Icons.medical_services,
      Icons.sports_esports,
      Icons.school,
      Icons.pets,
      Icons.work,
      Icons.monetization_on,
      Icons.flight,
      Icons.build,
      Icons.category,
    ];

    for (final icon in categoryIcons) {
      if (icon.codePoint == code) return icon;
    }
    return Icons.category;
  }

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
