import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../log_manager/log_manager.dart';
import '../model/OverallDataByDateModel.dart';
import 'package:respyr_clinical/shared/urls.dart';

class OverallDataByDateService {
  final String url = Urls.fetchOverallDataByDate;

  static String _cacheKey(String loginId, String date) =>
      'overall_data_cache_${loginId}_$date';

  /// Last successful response for this clinic+date, if any. Used to paint the
  /// dashboard instantly on relaunch (OEM battery managers kill the app in
  /// the background) while fresh data loads behind it.
  Future<OverallDataByDateModel?> readCached({
    required String loginId,
    required String date,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? raw = prefs.getString(_cacheKey(loginId, date));
      if (raw == null) return null;
      return OverallDataByDateModel.fromJson(json.decode(raw));
    } catch (_) {
      return null; // Corrupt/outdated cache is never fatal — just refetch.
    }
  }

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
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'login_id': loginId,
          'date': date,
        },
      );
      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);

        // Keep the raw payload so the next launch can paint immediately.
        await prefs.setString(_cacheKey(loginId, date), response.body);

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
