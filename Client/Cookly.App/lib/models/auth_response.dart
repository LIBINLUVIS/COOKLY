/// Mirrors the backend's `AuthResponseDto` — the payload inside a
/// successful `ServiceResponse` from `POST /api/auth/login`.
class AuthResponse {
  const AuthResponse({required this.token, required this.tokenExpiry});

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      token: json['token'] as String,
      tokenExpiry: DateTime.parse(json['tokenExpiry'] as String),
    );
  }

  final String token;
  final DateTime tokenExpiry;
}
