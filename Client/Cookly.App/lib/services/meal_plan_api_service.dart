import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/meal_plan_event.dart';
import '../models/meal_type.dart';
import 'session_store.dart';

class MealPlanApiException implements Exception {
  MealPlanApiException(this.message, {this.isUnauthorized = false});

  final String message;
  final bool isUnauthorized;

  @override
  String toString() => message;
}

/// Client for the Server-Sent Events endpoints under `/meal-plan/stream`.
/// Cancelling the returned stream closes the connection, which stops the run server-side.
class MealPlanApiService {
  MealPlanApiService._();

  static final MealPlanApiService instance = MealPlanApiService._();

  static const _connectTimeout = Duration(seconds: 30);

  Stream<MealPlanEvent> start(MealType mealType) =>
      _stream('/meal-plan/stream/start', {'mealType': mealType.value}, mealType);

  Stream<MealPlanEvent> respond({
    required String runId,
    required String message,
    required MealType mealType,
  }) =>
      _stream('/meal-plan/stream/${Uri.encodeComponent(runId)}/respond', {'message': message}, mealType);

  Stream<MealPlanEvent> _stream(String path, Map<String, Object?> body, MealType mealType) {
    final client = http.Client();
    var isCancelled = false;
    late final StreamController<MealPlanEvent> controller;

    void fail(Object error) {
      if (!isCancelled && !controller.isClosed) controller.addError(error);
    }

    Future<void> run() async {
      try {
        final session = await SessionStore.instance.read();
        if (session == null) {
          throw MealPlanApiException('Your session has expired. Please sign in again.', isUnauthorized: true);
        }

        final request = http.Request('POST', Uri.parse('${ApiConfig.baseUrl}$path'))
          ..headers.addAll({
            'Authorization': 'Bearer ${session.token}',
            'Content-Type': 'application/json',
            'Accept': 'text/event-stream',
          })
          ..body = jsonEncode(body);

        final response = await client.send(request).timeout(_connectTimeout);
        if (response.statusCode == 401) {
          throw MealPlanApiException('Your session has expired. Please sign in again.', isUnauthorized: true);
        }
        if (response.statusCode != 200) {
          throw MealPlanApiException(_errorMessage(await response.stream.bytesToString(), response.statusCode));
        }

        String? eventType;
        final data = StringBuffer();
        final lines = response.stream.transform(utf8.decoder).transform(const LineSplitter());
        await for (final line in lines) {
          if (line.isEmpty) {
            if (eventType != null && data.isNotEmpty) {
              final json = jsonDecode(data.toString()) as Map<String, dynamic>;
              final event = MealPlanEvent.fromSse(eventType, json, mealType);
              if (event != null && !isCancelled) controller.add(event);
            }
            eventType = null;
            data.clear();
          } else if (line.startsWith('event:')) {
            eventType = line.substring(6).trim();
          } else if (line.startsWith('data:')) {
            if (data.isNotEmpty) data.write('\n');
            data.write(line.substring(5).trimLeft());
          }
        }
      } on MealPlanApiException catch (error) {
        fail(error);
      } on TimeoutException {
        fail(MealPlanApiException('The server took too long to respond. Is the API running at ${ApiConfig.baseUrl}?'));
      } on SocketException catch (error) {
        fail(MealPlanApiException('Could not reach the server: ${error.message}'));
      } on http.ClientException catch (error) {
        fail(MealPlanApiException('Connection to the server was lost: ${error.message}'));
      } on FormatException {
        fail(MealPlanApiException('Received an unexpected response from the server.'));
      } finally {
        client.close();
        if (!controller.isClosed) await controller.close();
      }
    }

    controller = StreamController<MealPlanEvent>(
      onListen: run,
      onCancel: () {
        isCancelled = true;
        client.close();
      },
    );
    return controller.stream;
  }

  String _errorMessage(String body, int statusCode) {
    try {
      final json = jsonDecode(body);
      if (json is Map && json['message'] is String) return json['message'] as String;
    } on FormatException {
      // Fall through to the generic message.
    }
    return 'Server returned HTTP $statusCode.';
  }
}
