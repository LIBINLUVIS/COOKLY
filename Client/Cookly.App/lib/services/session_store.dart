import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/cookly_session.dart';

/// Persists the signed-in session (JWT + expiry + basic profile) in the
/// platform Keychain/Keystore via `flutter_secure_storage`, so it survives
/// app restarts without storing the token in plaintext.
class SessionStore {
  SessionStore._();

  static final SessionStore instance = SessionStore._();

  static const _sessionKey = 'cookly_session';

  final _storage = const FlutterSecureStorage();

  Future<void> save(CooklySession session) {
    return _storage.write(
      key: _sessionKey,
      value: jsonEncode(session.toJson()),
    );
  }

  /// Returns the stored session, or null if none is stored, it's corrupt,
  /// or its token has expired (in which case it's also cleared).
  Future<CooklySession?> read() async {
    final raw = await _storage.read(key: _sessionKey);
    if (raw == null) return null;

    final CooklySession session;
    try {
      session = CooklySession.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } on FormatException {
      await clear();
      return null;
    }

    if (!session.isValid) {
      await clear();
      return null;
    }

    return session;
  }

  Future<void> clear() => _storage.delete(key: _sessionKey);
}
