import 'dart:convert';
import 'dart:developer' as dev;
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
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
    final String sanitizedTestData = testdata.replaceAll(RegExp(r'\s+'), '').trim();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token') ?? '';

      final response = await http.post(
        Uri.parse("https://humorstech.com/humors_app/app_final/clinical/api/fetch/result_analysis.php"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/x-www-form-urlencoded",
        },
        body: {
          'testdata': sanitizedTestData, // Use the cleaned string here
          'subid': subjectId,
          'gender': gender,
          'age': age,
          'height': height,
          'blow_region': region,
          'blow_raw_values': blowData,
        },
      );

      // DEBUG: Verify the outgoing string matches Postman exactly
      print("SENDING TESTDATA: $sanitizedTestData");
      print("SERVER RESPONSE: ${response.body}");

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['status'] == 'success') {
          return NewResultModel.fromJson(json['data']);
        } else {
          throw Exception(json['message'] ?? 'API Error');
        }
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
      apiUrl: "https://humorstech.com/humors_app/app_final/clinical/api/fetch/fetch_history.php",
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
          apiUrl: "https://humorstech.com/humors_app/app_final/clinical/api/fetch/fetch_history.php",
          status: 'FAILED',
          details: 'JWT token missing for history fetch loginId: $loginId',
        );
        throw Exception('Missing token');
      }

      final uri = Uri.parse(
        "https://humorstech.com/humors_app/app_final/clinical/api/fetch/fetch_history.php",
      );

      final response = await http.post(
        uri,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/x-www-form-urlencoded",
        },
        body: {
          "login_id": loginId,
          "profile_id": profileId,
          "id": id,
        },
      );


      print( "response:" + response.body.toString());

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);

        if (json['status'] == 'success') {
          final model = NewResultModel.fromJson(json['data']);
          return model;  // Return the fetched history
        } else {
          // Log API error
          LogManager().logEvent(
            event: 'FETCH_HISTORY_FAILED',
            apiUrl: uri.toString(),
            status: 'FAILED',
            details: 'API error: ${json['message'] ?? 'Unknown error'} for loginId: $loginId',
          );
          throw Exception(json['message'] ?? 'API responded with error');
        }
      } else {
        // Log HTTP error
        LogManager().logEvent(
          event: 'FETCH_HISTORY_FAILED',
          apiUrl: uri.toString(),
          status: 'FAILED',
          details: 'HTTP ${response.statusCode}: ${response.reasonPhrase ?? 'Unknown error'} for loginId: $loginId',
        );
        throw Exception(
          'HTTP ${response.statusCode}: ${response.reasonPhrase ?? 'Unknown error'}',
        );
      }
    } catch (e) {
      // Log exception
      LogManager().logEvent(
        event: 'FETCH_HISTORY_EXCEPTION',
        apiUrl: "https://humorstech.com/humors_app/app_final/clinical/api/fetch/fetch_history.php",
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
    final String sanitizedTestData = testdata.replaceAll(RegExp(r'\s+'), '').trim();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token') ?? '';

      final response = await http.post(
        Uri.parse("https://humorstech.com/humors_app/app_final/clinical/api/fetch/result_analysis2.php"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/x-www-form-urlencoded",
        },
        body: {
          'testdata': sanitizedTestData, // Use the cleaned string here
          'subid': subjectId,
          'gender': gender,
          'age': age,
          'height': height,
          'blow_region': region,
          'blow_raw_values': blowData,
        },
      );

      // DEBUG: Verify the outgoing string matches Postman exactly
      print("SENDING TESTDATA: $sanitizedTestData");
      print("SERVER RESPONSE: ${response.body}");

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['status'] == 'success') {
          return NewResultModel.fromJson(json['data']);
        } else {
          throw Exception(json['message'] ?? 'API Error');
        }
      } else {
        throw Exception('Server Error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Request failed: $e');
    }
  }

}
