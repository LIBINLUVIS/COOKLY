import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/auth_response.dart';
import '../models/service_response.dart';

/// Thrown for both business-logic failures (`success: false` in the
/// response body) and transport-level failures (can't reach the server,
/// bad/unexpected response), always carrying a message fit to show the
/// user directly.
class AuthApiException implements Exception {
  AuthApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class AuthApiService {
  AuthApiService._();

  static final AuthApiService instance = AuthApiService._();

  /// Calls `POST /api/auth/login` with the Google profile fields and
  /// returns the issued token on success, or throws [AuthApiException]
  /// carrying the backend's own message on failure.
  Future<AuthResponse> loginWithProfile({
    required String email,
    String? firstName,
    String? lastName,
    String? displayName,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/auth/login');

    final http.Response response;
    try {
      response = await http
          .post(
            uri,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({
              'email': email,
              'firstName': firstName,
              'lastName': lastName,
              'displayName': displayName,
            }),
          )
          .timeout(const Duration(seconds: 15));
    } on TimeoutException {
      throw AuthApiException(
        'The server took too long to respond. Is the API running at ${ApiConfig.baseUrl}?',
      );
    } on SocketException catch (e) {
      throw AuthApiException(
        'Could not reach the server at ${ApiConfig.baseUrl}: ${e.message}',
      );
    } on HandshakeException catch (e) {
      throw AuthApiException('TLS handshake with the server failed: ${e.message}');
    }

    Map<String, dynamic> body;
    try {
      body = jsonDecode(response.body) as Map<String, dynamic>;
    } on FormatException {
      throw AuthApiException(
        'Unexpected response from server (HTTP ${response.statusCode}).',
      );
    }

    if (response.statusCode != 200) {
      final message = body['message'] as String?;
      throw AuthApiException(
        message ?? 'Server returned HTTP ${response.statusCode}.',
      );
    }

    final serviceResponse = ServiceResponse<AuthResponse>.fromJson(
      body,
      (data) => data == null
          ? null
          : AuthResponse.fromJson(data as Map<String, dynamic>),
    );

    if (!serviceResponse.success || serviceResponse.data == null) {
      throw AuthApiException(serviceResponse.message ?? 'Login failed.');
    }

    return serviceResponse.data!;
  }
}
