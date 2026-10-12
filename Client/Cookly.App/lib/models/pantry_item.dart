import '../utils/dates.dart';

/// Mirrors the backend's `Category` enum, which is serialized as its int value.
enum PantryCategory {
  vegetable(1, 'Vegetable', '🥦'),
  fruits(2, 'Fruits', '🍎'),
  dairy(3, 'Dairy', '🥛'),
  meats(4, 'Meats', '🍗'),
  condiments(5, 'Condiments', '🧂'),
  others(6, 'Others', '🧺');

  const PantryCategory(this.value, this.label, this.emoji);

  final int value;
  final String label;
  final String emoji;

  static PantryCategory? fromValue(Object? value) {
    for (final category in values) {
      if (category.value == value) return category;
    }
    return null;
  }
}

/// Mirrors the backend's `ListItems` DTO from `GET /api/inventory/list-item`.
class PantryItem {
  const PantryItem({
    required this.itemId,
    required this.name,
    required this.quantity,
    this.unit,
    this.purchasedAt,
    this.expiresAt,
    this.category,
  });

  factory PantryItem.fromJson(Map<String, dynamic> json) => PantryItem(
    itemId: (json['itemId'] as num).toInt(),
    name: json['itemName'] as String? ?? '',
    quantity: (json['quantity'] as num?)?.toInt() ?? 0,
    unit: json['unit'] as String?,
    purchasedAt: parseServerDate(json['purchasedAt']),
    expiresAt: parseServerDate(json['expiredAt']),
    category: PantryCategory.fromValue(json['category']),
  );

  final int itemId;
  final String name;
  final int quantity;
  final String? unit;
  final DateTime? purchasedAt;
  final DateTime? expiresAt;
  final PantryCategory? category;

  int? get daysUntilExpiry =>
      expiresAt == null ? null : calendarDaysFromToday(expiresAt!);

  bool get isExpiringSoon {
    final days = daysUntilExpiry;
    return days != null && days <= 3;
  }

  String get quantityLabel {
    final trimmedUnit = unit?.trim() ?? '';
    return trimmedUnit.isEmpty ? '$quantity' : '$quantity $trimmedUnit';
  }

  PantryItem copyWith({int? quantity, DateTime? expiresAt}) => PantryItem(
    itemId: itemId,
    name: name,
    quantity: quantity ?? this.quantity,
    unit: unit,
    purchasedAt: purchasedAt,
    expiresAt: expiresAt ?? this.expiresAt,
    category: category,
  );
}
