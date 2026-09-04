import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:respyr_clinical/shared/nodeurl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../log_manager/log_manager.dart';
import '../../../../new_result/data/model/result_model.dart';

class ResultService {
  Future<NewResultModel> fetchResults({
    required String testdata,
    required String subjectId,
    required String gender,
    required String age,
    required String height,
    required String region,
    required String blowData,
  }) async {
    // 1. CLEAN THE DATA
    // This removes actual newlines (\n), carriage returns (\r), and tabs (\t)
    // ensuring the string is one continuous line exactly like Postman.
    final String sanitizedTestData =
        testdata.replaceAll(RegExp(r'\s+'), '').trim();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token') ?? '';

      final response = await http.post(
        Uri.parse(NodeUrls.resultAnalysis),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          'testdata': sanitizedTestData, // Use the cleaned string here
          'subid': subjectId,
          'gender': gender,
          'age': age,
          'height': height,
          'blow_region': region,
          'blow_raw_values': blowData,
        }),
      );

      // DEBUG: Verify the outgoing string matches Postman exactly
      print("SENDING TESTDATA: $sanitizedTestData");
      print("SERVER RESPONSE: ${response.body}");

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final obj = extractResultObject(json);
        if (obj != null) {
          return NewResultModel.fromJson(obj);
        }
        throw Exception(json is Map ? (json['message'] ?? 'API Error') : 'API Error');
      } else {
        throw Exception('Server Error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Request failed: $e');
    }
  }

  Future<NewResultModel> fetchHistory({
    required String loginId,
    required String profileId,
    required String id,
  }) async {
    // Log attempt
    LogManager().logEvent(
      event: 'FETCH_HISTORY_ATTEMPT',
      apiUrl: NodeUrls.fetchHistory,
      status: 'ATTEMPT',
      details: 'Fetching history for loginId: $loginId, profileId: $profileId',
    );

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token') ?? '';

      if (token.isEmpty) {
        // Log missing token
        LogManager().logEvent(
          event: 'FETCH_HISTORY_UNAUTHORIZED',
          apiUrl: NodeUrls.fetchHistory,
          status: 'FAILED',
          details: 'JWT token missing for history fetch loginId: $loginId',
        );
        throw Exception('Missing token');
      }

      final uri = Uri.parse(NodeUrls.fetchHistory);

      final response = await http.post(
        uri,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode({"login_id": loginId, "profile_id": profileId, "id": id}),
      );

      print("response:${response.body}");

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);

        final obj = extractResultObject(json);
        if (obj != null) {
          final model = NewResultModel.fromJson(obj);
          return model; // Return the fetched history
        } else {
          // Log API error
          LogManager().logEvent(
            event: 'FETCH_HISTORY_FAILED',
            apiUrl: uri.toString(),
            status: 'FAILED',
            details:
                'API error: ${json is Map ? (json['message'] ?? 'Unknown error') : 'Unknown error'} for loginId: $loginId',
          );
          throw Exception(json is Map ? (json['message'] ?? 'API responded with error') : 'API responded with error');
        }
      } else {
        // Log HTTP error
        LogManager().logEvent(
          event: 'FETCH_HISTORY_FAILED',
          apiUrl: uri.toString(),
          status: 'FAILED',
          details:
              'HTTP ${response.statusCode}: ${response.reasonPhrase ?? 'Unknown error'} for loginId: $loginId',
        );
        throw Exception(
          'HTTP ${response.statusCode}: ${response.reasonPhrase ?? 'Unknown error'}',
        );
      }
    } catch (e) {
      // Log exception
      LogManager().logEvent(
        event: 'FETCH_HISTORY_EXCEPTION',
        apiUrl: NodeUrls.fetchHistory,
        status: 'EXCEPTION',
        details: 'Exception: $e for loginId: $loginId',
      );
      throw Exception('Exception: ${e.toString()}');
    }
  }

  Future<NewResultModel> fetchResults1({
    required String testdata,
    required String subjectId,
    required String gender,
    required String age,
    required String height,
    required String region,
    required String blowData,
  }) async {
    // 1. CLEAN THE DATA
    // This removes actual newlines (\n), carriage returns (\r), and tabs (\t)
    // ensuring the string is one continuous line exactly like Postman.
    final String sanitizedTestData =
        testdata.replaceAll(RegExp(r'\s+'), '').trim();

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token') ?? '';

    final uri = Uri.parse(NodeUrls.resultAnalysis2);
    final headers = {
      "Authorization": "Bearer $token",
      "Content-Type": "application/json",
    };
    final body = jsonEncode({
      'testdata': sanitizedTestData, // Use the cleaned string here
      'subid': subjectId,
      'gender': gender,
      'age': age,
      'height': height,
      'blow_region': region,
      'blow_raw_values': blowData,
    });

    // Auto-retry transient connectivity failures (e.g. the data bearer briefly
    // switching during a phone call / Wi-Fi handoff, or Android suspending the
    // socket while the app is backgrounded) so the captured reading isn't lost
    // to a momentary blip. Non-transient errors (API rejection, non-200) fail
    // fast without retrying.
    //
    // Instead of a small fixed attempt count, keep retrying for a generous time
    // BUDGET with a capped growing backoff. This covers the common case where
    // the app is minimized mid-call: the network stays dead while backgrounded,
    // then recovers the moment the user reopens the app — as long as this loop
    // is still alive it will succeed on the next attempt. The foreground service
    // (GenerationForegroundService) keeps this loop's process alive meanwhile.
    const Duration requestTimeout = Duration(seconds: 20);
    const Duration retryBudget = Duration(seconds: 90);
    const Duration maxBackoff = Duration(seconds: 5);

    final DateTime deadline = DateTime.now().add(retryBudget);
    Object lastError = Exception('Request failed');
    int attempt = 0;
    while (true) {
      attempt++;
      try {
        final response = await http
            .post(uri, headers: headers, body: body)
            .timeout(requestTimeout);

        // DEBUG: Verify the outgoing string matches Postman exactly
        print("SENDING TESTDATA: $sanitizedTestData");
        print("SERVER RESPONSE: ${response.body}");

        if (response.statusCode == 200) {
          final json = jsonDecode(response.body);
          final obj = extractResultObject(json);
          if (obj != null) {
            return NewResultModel.fromJson(obj);
          }
          // Server was reached and rejected the request — retrying won't help.
          throw Exception(json is Map ? (json['message'] ?? 'API Error') : 'API Error');
        } else {
          // Non-200 from a reachable server — not a transient network blip.
          throw Exception('Server Error: ${response.statusCode}');
        }
      } catch (e) {
        lastError = e;

        final bool transient = _isTransientNetworkError(e);
        final bool timeLeft = DateTime.now().isBefore(deadline);
        if (transient && timeLeft) {
          // Grow the wait with each failure but cap it so we keep probing
          // frequently once the network is likely back.
          final int backoffSeconds =
              attempt < maxBackoff.inSeconds ? attempt : maxBackoff.inSeconds;
          final Duration retryDelay = Duration(seconds: backoffSeconds);
          print(
            "fetchResults1: transient network error on attempt $attempt, "
            "retrying in ${retryDelay.inMilliseconds}ms. Error: $e",
          );
          await Future.delayed(retryDelay);
          continue;
        }

        // Exhausted the retry budget: wrap so the caller's network-error
        // detection still matches. Non-transient errors propagate unchanged.
        if (transient) {
          throw Exception('Request failed: $e');
        }
        rethrow;
      }
    }
    // ignore: dead_code
    throw Exception('Request failed: $lastError');
  }

  /// Whether [error] is a transient connectivity failure worth retrying
  /// (as opposed to an API/server rejection, which won't improve on retry).
  bool _isTransientNetworkError(Object error) {
    if (error is TimeoutException) return true;
    if (error is http.ClientException) return true;

    final m = error.toString().toLowerCase();
    return m.contains("socketexception") ||
        m.contains("failed host lookup") ||
        m.contains("no address associated") ||
        m.contains("network is unreachable") ||
        m.contains("connection refused") ||
        m.contains("connection closed") ||
        m.contains("connection reset") ||
        // Android tearing down the socket when the app is backgrounded.
        m.contains("software caused connection abort") ||
        m.contains("connection abort") ||
        m.contains("broken pipe") ||
        m.contains("connection timed out") ||
        // TLS handshake interrupted by the same backgrounding/network drop.
        m.contains("handshakeexception") ||
        m.contains("timeoutexception") ||
        m.contains("clientexception");
  }
}
