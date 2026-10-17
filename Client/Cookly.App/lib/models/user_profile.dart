import '../utils/dates.dart';

/// Mirrors the backend's `ProfileDto` from `GET /api/profile`.
class UserProfile {
  const UserProfile({
    required this.email,
    required this.dishesCount,
    required this.pantryItemsCount,
    this.firstName,
    this.lastName,
    this.displayName,
    this.memberSince,
    this.goal,
    this.preference,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    email: json['email'] as String? ?? '',
    firstName: json['firstName'] as String?,
    lastName: json['lastName'] as String?,
    displayName: json['displayName'] as String?,
    memberSince: parseServerDate(json['memberSince']),
    goal: json['goal'] as String?,
    preference: json['preference'] as String?,
    dishesCount: (json['dishesCount'] as num?)?.toInt() ?? 0,
    pantryItemsCount: (json['pantryItemsCount'] as num?)?.toInt() ?? 0,
  );

  final String email;
  final String? firstName;
  final String? lastName;
  final String? displayName;
  final DateTime? memberSince;
  final String? goal;
  final String? preference;
  final int dishesCount;
  final int pantryItemsCount;

  String get fullName {
    final name = [
      firstName,
      lastName,
    ].where((p) => p?.trim().isNotEmpty ?? false).join(' ');
    if (name.isNotEmpty) return name;
    if (displayName?.trim().isNotEmpty ?? false) return displayName!.trim();
    return email.split('@').first;
  }
}
