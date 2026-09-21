/// Basic profile details returned after a successful Google sign-in.
class CooklyGoogleUser {
  const CooklyGoogleUser({
    required this.email,
    required this.displayName,
    required this.firstName,
    required this.lastName,
    required this.idToken,
    this.photoUrl,
  });

  final String email;
  final String? displayName;
  final String? firstName;
  final String? lastName;
  final String? photoUrl;

  /// The Google ID token (JWT), kept so the backend can verify the sign-in
  /// once the server-side Google auth endpoint is ready.
  final String? idToken;

  @override
  String toString() =>
      'CooklyGoogleUser(email: $email, displayName: $displayName, '
      'firstName: $firstName, lastName: $lastName, photoUrl: $photoUrl)';
}
