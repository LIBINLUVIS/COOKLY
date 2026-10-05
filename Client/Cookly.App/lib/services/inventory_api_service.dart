import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/pantry_item.dart';
import '../models/service_response.dart';
import 'session_store.dart';

/// Carries a message fit to show the user. [isUnauthorized] means the
/// stored token is missing or was rejected, so the user must sign in again.
class InventoryApiException implements Exception {
  InventoryApiException(this.message, {this.isUnauthorized = false});

  final String message;
  final bool isUnauthorized;

  @override
  String toString() => message;
}

/// Client for the authorized `/api/inventory` endpoints.
class InventoryApiService {
  InventoryApiService._();

  static final InventoryApiService instance = InventoryApiService._();

  static const _timeout = Duration(seconds: 15);

  Future<List<PantryItem>> listItems() async {
    final body = await _send('GET', '/api/inventory/list-item');
    final response = ServiceResponse<List<PantryItem>>.fromJson(
      body,
      (data) => data is List
          ? data
              .map((item) => PantryItem.fromJson(item as Map<String, dynamic>))
              .toList()
          : null,
    );
    if (!response.success) {
      throw InventoryApiException(_messageOf(response, 'Could not load your pantry.'));
    }
    return response.data ?? <PantryItem>[];
  }

  Future<void> addItem({
    required String name,
    required int quantity,
    required String unit,
    required PantryCategory category,
    DateTime? expiresAt,
  }) async {
    final body = await _send('POST', '/api/inventory/add-item', body: {
      'itemName': name,
      'quantity': quantity,
      'unit': unit,
      'category': category.value,
      'expiredAt': expiresAt?.toUtc().toIso8601String(),
    });
    _ensureSuccess(body, 'Could not add the item.');
  }

  Future<void> deleteItem(int itemId) async {
    final body = await _send('DELETE', '/api/inventory/delete-item/$itemId');
    _ensureSuccess(body, 'Could not delete the item.');
  }

  /// Applies a signed [change] and returns the server-confirmed quantity.
  Future<int?> updateQuantity({required int itemId, required int change}) async {
    final body = await _send('PATCH', '/api/inventory/update-quantity', body: {
      'itemId': itemId,
      'quantityChange': change,
    });
    final response = ServiceResponse<String>.fromJson(body, (data) => data?.toString());
    if (!response.success) {
      throw InventoryApiException(_messageOf(response, 'Could not update the quantity.'));
    }
    return int.tryParse(response.data ?? '');
  }

  void _ensureSuccess(Map<String, dynamic> body, String fallback) {
    final response = ServiceResponse<Object?>.fromJson(body, (data) => data);
    if (!response.success) throw InventoryApiException(_messageOf(response, fallback));
  }

  String _messageOf(ServiceResponse<Object?> response, String fallback) =>
      response.message ?? response.messageKey ?? fallback;

  Future<Map<String, dynamic>> _send(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final session = await SessionStore.instance.read();
    if (session == null) {
      throw InventoryApiException(
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
      response = await request.send().then(http.Response.fromStream).timeout(_timeout);
    } on TimeoutException {
      throw InventoryApiException(
        'The server took too long to respond. Is the API running at ${ApiConfig.baseUrl}?',
      );
    } on SocketException catch (e) {
      throw InventoryApiException('Could not reach the server: ${e.message}');
    } on http.ClientException catch (e) {
      throw InventoryApiException('Could not reach the server: ${e.message}');
    }

    if (response.statusCode == 401) {
      throw InventoryApiException(
        'Your session has expired. Please sign in again.',
        isUnauthorized: true,
      );
    }

    final Map<String, dynamic> json;
    try {
      json = jsonDecode(response.body) as Map<String, dynamic>;
    } on FormatException {
      throw InventoryApiException(
        'Unexpected response from server (HTTP ${response.statusCode}).',
      );
    }

    if (response.statusCode == 400) throw InventoryApiException(_validationMessage(json));
    if (response.statusCode != 200) {
      throw InventoryApiException(
        json['message'] as String? ?? 'Server returned HTTP ${response.statusCode}.',
      );
    }
    return json;
  }

  /// Flattens an ASP.NET Core `ValidationProblem` body into one line.
  String _validationMessage(Map<String, dynamic> json) {
    final errors = json['errors'];
    if (errors is Map) {
      final messages = errors.values.expand((value) => value is List ? value : [value]);
      if (messages.isNotEmpty) return messages.join(' ');
    }
    return json['title'] as String? ?? 'Please check the details and try again.';
  }
}
