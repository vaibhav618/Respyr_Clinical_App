import 'package:flutter/foundation.dart';

class LogManager {
  static final LogManager _instance = LogManager._internal();
  factory LogManager() => _instance;
  LogManager._internal();

  String? userId;

  void setUserId(String id) => userId = id;

  /// Server-side event logging is disabled for now — this no-ops the network
  /// call, so nothing is sent to the logger endpoint. Every caller across the
  /// app keeps working; in debug builds the event is still printed locally.
  Future<void> logEvent({
    required String event,
    String? apiUrl,
    String? status,
    String? details,
    Map<String, dynamic>? extra,
  }) async {
    if (kDebugMode) {
      print('[log] $event  ${status ?? ''}  ${details ?? ''}');
    }
  }
}
