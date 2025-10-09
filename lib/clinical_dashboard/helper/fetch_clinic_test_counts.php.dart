import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../log_manager/log_manager.dart';

const String statusKey = 'status';
const String successValue = 'success';
const String sharedPrefsKey = 'clinical_data';

Future<({
int statusCode,
Map<String, dynamic> data,
})> fetchClinicalDetails({
  required String loginId,
}) async {
  final url = Uri.parse(
    'https://humorstech.com/humors_app/app_final/clinical/api/fetch/check_test_counts.php',
  );

  try {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    if (token == null) {
      // Log unauthorized access
      LogManager().logEvent(
        event: 'FETCH_CLINICAL_DETAILS_UNAUTHORIZED',
        apiUrl: url.toString(),
        status: 'FAILED',
        details: 'JWT token missing for $loginId',
      );
      return (
      statusCode: 401,
      data: {'status': 'error', 'message': 'Unauthorized'}
      );
    }

    // Log API call attempt
    LogManager().logEvent(
      event: 'FETCH_CLINICAL_DETAILS_ATTEMPT',
      apiUrl: url.toString(),
      status: 'ATTEMPT',
      details: 'Fetching clinical details for $loginId',
    );

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {
        'login_id': loginId,
      },
    );

    final decoded = jsonDecode(response.body);

    if (response.statusCode == 200 && decoded is Map<String, dynamic>) {
      // Log success
      LogManager().logEvent(
        event: 'FETCH_CLINICAL_DETAILS_SUCCESS',
        apiUrl: url.toString(),
        status: 'SUCCESS',
        details: 'Clinical details fetched for $loginId',
      );
      return (
      statusCode: response.statusCode,
      data: decoded
      );
    } else {
      // Log invalid response
      LogManager().logEvent(
        event: 'FETCH_CLINICAL_DETAILS_FAILED',
        apiUrl: url.toString(),
        status: 'FAILED',
        details: 'Invalid response or status ${response.statusCode} for $loginId',
      );
      return (
      statusCode: response.statusCode,
      data: {'message': 'Invalid response'}
      );
    }
  } catch (e) {
    // Log exception
    LogManager().logEvent(
      event: 'FETCH_CLINICAL_DETAILS_EXCEPTION',
      apiUrl: url.toString(),
      status: 'EXCEPTION',
      details: 'Network error: $e for $loginId',
    );
    return (
    statusCode: 500,
    data: {'status': 'error', 'message': 'Network error: $e'}
    );
  }
}
