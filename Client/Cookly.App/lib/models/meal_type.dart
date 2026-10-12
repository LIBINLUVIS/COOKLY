import 'package:flutter/material.dart';

/// Mirrors the backend's `Meal` enum.
enum MealType {
  breakfast(1, 'Breakfast', Icons.wb_twilight),
  lunch(2, 'Lunch', Icons.wb_sunny_outlined),
  dinner(3, 'Dinner', Icons.nights_stay_outlined);

  const MealType(this.value, this.label, this.icon);

  final int value;
  final String label;
  final IconData icon;

  static MealType? fromValue(Object? value) {
    for (final meal in values) {
      if (meal.value == value) return meal;
    }
    return null;
  }

  static MealType? fromName(Object? name) {
    for (final meal in values) {
      if (meal.label.toLowerCase() == name?.toString().toLowerCase()) {
        return meal;
      }
    }
    return null;
  }
}
