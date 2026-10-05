import '../utils/jwt_payload.dart';

/// A persisted, signed-in session: the backend JWT plus enough profile
/// info to render the home screen without another network call.
class CooklySession {
  const CooklySession({
    required this.token,
    required this.tokenExpiry,
    required this.email,
    required this.displayName,
  });

  final String token;
  final DateTime tokenExpiry;
  final String email;
  final String? displayName;

  bool get isValid => tokenExpiry.isAfter(DateTime.now());

  /// The backend JWT's `name` claim ("First Last"), falling back to the
  /// Google display name, then the email's local part.
  String get fullName {
    final claim = decodeJwtPayload(token)['name'];
    final fromToken = claim is String ? claim.trim() : '';
    if (fromToken.isNotEmpty) return fromToken;
    final fromGoogle = displayName?.trim() ?? '';
    if (fromGoogle.isNotEmpty) return fromGoogle;
    return email.split('@').first;
  }

  String get firstName => fullName.split(RegExp(r'\s+')).first;

  Map<String, dynamic> toJson() => {
        'token': token,
        'tokenExpiry': tokenExpiry.toIso8601String(),
        'email': email,
        'displayName': displayName,
      };

  factory CooklySession.fromJson(Map<String, dynamic> json) => CooklySession(
        token: json['token'] as String,
        tokenExpiry: DateTime.parse(json['tokenExpiry'] as String),
        email: json['email'] as String,
        displayName: json['displayName'] as String?,
      );
}
