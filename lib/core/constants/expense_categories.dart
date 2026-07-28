import 'package:flutter/material.dart';

class ExpenseCategory {
  final String id;
  final IconData icon;

  const ExpenseCategory({required this.id, required this.icon});
}

class ExpenseCategories {
  ExpenseCategories._();

  static const List<ExpenseCategory> all = [
    ExpenseCategory(id: 'general', icon: Icons.receipt_long_rounded),
    ExpenseCategory(id: 'food', icon: Icons.restaurant_rounded),
    ExpenseCategory(id: 'travel', icon: Icons.flight_rounded),
    ExpenseCategory(id: 'transport', icon: Icons.directions_car_rounded),
    ExpenseCategory(id: 'accommodation', icon: Icons.hotel_rounded),
    ExpenseCategory(id: 'shopping', icon: Icons.shopping_bag_rounded),
    ExpenseCategory(id: 'entertainment', icon: Icons.movie_rounded),
    ExpenseCategory(id: 'utilities', icon: Icons.bolt_rounded),
  ];

  static IconData iconForId(String id) {
    return all.firstWhere((e) => e.id == id, orElse: () => all.first).icon;
  }
}
