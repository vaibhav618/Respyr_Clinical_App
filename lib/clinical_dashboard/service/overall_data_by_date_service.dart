import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../log_manager/log_manager.dart';
import '../model/OverallDataByDateModel.dart';
import 'package:respyr_clinical/shared/nodeurl.dart';

class OverallDataByDateService {
  final String url = NodeUrls.fetchOverallDataByDate;

  Future<OverallDataByDateModel> fetchOverallData({
    required String loginId,
    required String date,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    if (token == null || token.isEmpty) {
      // Log missing JWT
      LogManager().logEvent(
        event: 'FETCH_OVER_ALL_DATA_JWT_MISSING',
        apiUrl: url,
        status: 'FAILED',
        details: 'JWT token not found for user $loginId on $date',
      );
      throw Exception("JWT token not found. Please login again.");
    }

    // Log attempt
    LogManager().logEvent(
      event: 'FETCH_OVER_ALL_DATA_ATTEMPT',
      apiUrl: url,
      status: 'ATTEMPT',
      details: 'Requesting data for $loginId on $date',
    );

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'login_id': loginId,
          'date': date,
        }),
      );
      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);




        // Log success (no PHI!)
        LogManager().logEvent(
          event: 'FETCH_OVER_ALL_DATA_SUCCESS',
          apiUrl: url,
          status: 'SUCCESS',
          details: 'Loaded overall data for $loginId on $date',
        );

        return OverallDataByDateModel.fromJson(jsonResponse);
      } else {
        // Log API failure
        LogManager().logEvent(
          event: 'FETCH_OVER_ALL_DATA_FAILED',
          apiUrl: url,
          status: 'FAILED',
          details: 'Status ${response.statusCode} for $loginId on $date',
        );
        throw Exception('Failed to load data: ${response.statusCode}');
      }
    } catch (e) {
      // Log exception
      LogManager().logEvent(
        event: 'FETCH_OVER_ALL_DATA_EXCEPTION',
        apiUrl: url,
        status: 'EXCEPTION',
        details: 'Error: $e for $loginId on $date',
      );
      rethrow;
    }
  }
}
