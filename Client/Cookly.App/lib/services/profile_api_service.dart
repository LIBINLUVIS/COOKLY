import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/service_response.dart';
import '../models/user_profile.dart';
import 'session_store.dart';

class ProfileApiException implements Exception {
  ProfileApiException(this.message, {this.isUnauthorized = false});

  final String message;
  final bool isUnauthorized;

  @override
  String toString() => message;
}

/// Client for `/api/profile`.
class ProfileApiService {
  ProfileApiService._();

  static final ProfileApiService instance = ProfileApiService._();

  Future<UserProfile> getProfile() => _send('GET', '/api/profile');

  /// Saves the goal and taste preferences that NutritionAgent plans meals around.
  Future<UserProfile> updatePreferences({String? goal, String? preference}) =>
      _send(
        'PUT',
        '/api/profile/preferences',
        body: {'goal': goal, 'preference': preference},
      );

  Future<UserProfile> _send(
    String method,
    String path, {
    Map<String, Object?>? body,
  }) async {
    final session = await SessionStore.instance.read();
    if (session == null) {
      throw ProfileApiException(
        'Your session has expired. Please sign in again.',
        isUnauthorized: true,
      );
    }

    final request = http.Request(method, Uri.parse('${ApiConfig.baseUrl}$path'))
      ..headers['Authorization'] = 'Bearer ${session.token}';
    if (body != null) {
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode(body);
    }

    final http.Response response;
    try {
      response = await request
          .send()
          .then(http.Response.fromStream)
          .timeout(const Duration(seconds: 15));
    } on TimeoutException {
      throw ProfileApiException('The server took too long to respond.');
    } on SocketException catch (e) {
      throw ProfileApiException('Could not reach the server: ${e.message}');
    } on http.ClientException catch (e) {
      throw ProfileApiException('Could not reach the server: ${e.message}');
    }

    if (response.statusCode == 401) {
      throw ProfileApiException(
        'Your session has expired. Please sign in again.',
        isUnauthorized: true,
      );
    }

    final Map<String, dynamic> json;
    try {
      json = jsonDecode(response.body) as Map<String, dynamic>;
    } on FormatException {
      throw ProfileApiException(
        'Unexpected response from server (HTTP ${response.statusCode}).',
      );
    }

    if (response.statusCode == 400) {
      final errors = json['errors'];
      final messages = errors is Map
          ? errors.values.expand((v) => v is List ? v : [v])
          : const [];
      throw ProfileApiException(
        messages.isEmpty
            ? 'Please check the details and try again.'
            : messages.join(' '),
      );
    }

    final result = ServiceResponse<UserProfile>.fromJson(
      json,
      (data) =>
          data is Map<String, dynamic> ? UserProfile.fromJson(data) : null,
    );
    if (!result.success || result.data == null) {
      throw ProfileApiException(
        result.message ?? result.messageKey ?? 'Could not load your profile.',
      );
    }
    return result.data!;
  }
}
