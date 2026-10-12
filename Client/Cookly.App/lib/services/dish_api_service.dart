import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/recipe.dart';
import '../models/service_response.dart';
import 'session_store.dart';

class DishApiException implements Exception {
  DishApiException(this.message, {this.isUnauthorized = false});

  final String message;
  final bool isUnauthorized;

  @override
  String toString() => message;
}

/// Client for `/api/dishes` (the user's suggested-meal history).
class DishApiService {
  DishApiService._();

  static final DishApiService instance = DishApiService._();

  /// Every dish suggested to the user, newest first.
  Future<List<Recipe>> history() async {
    final session = await SessionStore.instance.read();
    if (session == null) {
      throw DishApiException(
        'Your session has expired. Please sign in again.',
        isUnauthorized: true,
      );
    }

    final http.Response response;
    try {
      response = await http
          .get(
            Uri.parse('${ApiConfig.baseUrl}/api/dishes/history'),
            headers: {'Authorization': 'Bearer ${session.token}'},
          )
          .timeout(const Duration(seconds: 15));
    } on TimeoutException {
      throw DishApiException('The server took too long to respond.');
    } on SocketException catch (e) {
      throw DishApiException('Could not reach the server: ${e.message}');
    } on http.ClientException catch (e) {
      throw DishApiException('Could not reach the server: ${e.message}');
    }

    if (response.statusCode == 401) {
      throw DishApiException(
        'Your session has expired. Please sign in again.',
        isUnauthorized: true,
      );
    }

    final Map<String, dynamic> json;
    try {
      json = jsonDecode(response.body) as Map<String, dynamic>;
    } on FormatException {
      throw DishApiException(
        'Unexpected response from server (HTTP ${response.statusCode}).',
      );
    }

    final result = ServiceResponse<List<Recipe>>.fromJson(
      json,
      (data) => data is List
          ? [
              for (final dish in data)
                Recipe.fromHistoryJson(dish as Map<String, dynamic>),
            ]
          : null,
    );
    if (!result.success) {
      throw DishApiException(
        result.message ?? result.messageKey ?? 'Could not load your dishes.',
      );
    }
    return result.data ?? [];
  }
}
