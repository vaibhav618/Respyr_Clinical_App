import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:respyr_clinical/shared/urls.dart';

class LogManager {
  static final LogManager _instance = LogManager._internal();
  factory LogManager() => _instance;
  LogManager._internal();

  String logApiEndpoint = Urls.logger;
  String? userId;

  void setUserId(String id) => userId = id;

  Future<void> logEvent({
    required String event,
    String? apiUrl,
    String? status,
    String? details,
    Map<String, dynamic>? extra,
  }) async {
    final DateTime now = DateTime.now().toUtc();
    final logEntry = {
      'timestamp': now.toIso8601String(),
      'event': event,
      'userId': userId ?? '',
      'url': apiUrl ?? '',
      'status': status ?? '',
      'details': details ?? '',
      'extra': extra != null ? jsonEncode(extra) : '',
    };

    try {
      final response = await http.post(
        Uri.parse(logApiEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(logEntry),
      );

    } catch (e) {
      if (kDebugMode) {
        print('Failed to send log: $e');
      }
    }
  }
}
