import 'package:google_sign_in/google_sign_in.dart';

import '../config/google_auth_config.dart';
import '../models/cookly_google_user.dart';
import '../utils/jwt_payload.dart';

/// Thrown when the user dismisses the Google account picker instead of
/// completing sign-in.
class GoogleSignInCancelled implements Exception {}

/// Wraps `google_sign_in` v7's singleton API and maps its result onto
/// [CooklyGoogleUser], decoding the ID token for the given/family name
/// claims the plugin doesn't expose directly.
class GoogleAuthService {
  GoogleAuthService._();

  static final GoogleAuthService instance = GoogleAuthService._();

  bool _initialized = false;

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    await GoogleSignIn.instance.initialize(
      clientId: GoogleAuthConfig.iosClientId,
      serverClientId: GoogleAuthConfig.serverClientId,
    );
    _initialized = true;
  }

  Future<CooklyGoogleUser> signIn() async {
    await _ensureInitialized();

    final GoogleSignInAccount account;
    try {
      account = await GoogleSignIn.instance.authenticate();
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        throw GoogleSignInCancelled();
      }
      rethrow;
    }

    final idToken = account.authentication.idToken;
    final claims = idToken == null ? const <String, dynamic>{} : decodeJwtPayload(idToken);

    return CooklyGoogleUser(
      email: account.email,
      displayName: account.displayName ?? claims['name'] as String?,
      firstName: claims['given_name'] as String?,
      lastName: claims['family_name'] as String?,
      photoUrl: account.photoUrl ?? claims['picture'] as String?,
      idToken: idToken,
    );
  }

  Future<void> signOut() async {
    await _ensureInitialized();
    await GoogleSignIn.instance.signOut();
  }
}
