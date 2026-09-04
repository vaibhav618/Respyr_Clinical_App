import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:respyr_clinical/shared/nodeurl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../log_manager/log_manager.dart';

class JwtApiHelper {
  /// Fetch and store JWT token via POST
  static Future<ApiResult> fetchAndStoreJwtToken({
    required String loginId,
  }) async {
    final url = Uri.parse(
      NodeUrls.generateJwtToken,
    );

    // Log the API call attempt
    LogManager().logEvent(
      event: 'JWT_FETCH_ATTEMPT',
      apiUrl: url.toString(),
      status: 'ATTEMPT',
      details: 'Attempting to fetch JWT for loginId=$loginId',
    );

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({'login_id': loginId}),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['token'] != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('jwt_token', data['token']);

        // Log success (never log the full token for security)
        LogManager().logEvent(
          event: 'JWT_FETCH_SUCCESS',
          apiUrl: url.toString(),
          status: 'SUCCESS',
          details: 'Token fetched. Token (truncated): ${data['token'].toString().substring(0, 8)}...',
        );

        return ApiResult(success: true, message: "Token fetched", data: data);
      } else {
        // Log failure
        LogManager().logEvent(
          event: 'JWT_FETCH_FAILED',
          apiUrl: url.toString(),
          status: 'FAILED',
          details: data['error'] ?? "Unknown token error",
        );

        return ApiResult(
          success: false,
          message: data['error'] ?? "Unknown token error",
        );
      }
    } catch (e) {
      // Log exception
      LogManager().logEvent(
        event: 'JWT_FETCH_EXCEPTION',
        apiUrl: url.toString(),
        status: 'EXCEPTION',
        details: e.toString(),
      );

      return ApiResult(success: false, message: "Exception: ${e.toString()}");
    }
  }
}

class ApiResult {
  final bool success;
  final String? message;
  final dynamic data;

  ApiResult({required this.success, this.message, this.data});
}
