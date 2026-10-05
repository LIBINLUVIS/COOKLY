import 'dart:convert';

/// Decodes a JWT's payload segment without verifying its signature. Only
/// for reading display claims client-side; the server verifies tokens.
Map<String, dynamic> decodeJwtPayload(String token) {
  final parts = token.split('.');
  if (parts.length != 3) return const <String, dynamic>{};

  try {
    final payload = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
    final decoded = jsonDecode(payload);
    return decoded is Map<String, dynamic> ? decoded : const <String, dynamic>{};
  } on FormatException {
    return const <String, dynamic>{};
  }
}
