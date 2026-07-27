import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:respyr_clinical/shared/urls.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/score_response_model.dart';

class ScoreApiException implements Exception {
  final String message;
  final int statusCode;

  ScoreApiException({required this.message, required this.statusCode});

  @override
  String toString() => 'ScoreApiException ($statusCode): $message';
}

class ScoreService {
  final String apiUrl = Urls.fetchRaphacureResult;

  Future<ScoreResponseModel> fetchScores(Map<String, dynamic> postData) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: postData,
    );

    try {
      final jsonResponse = jsonDecode(response.body);

      if (response.statusCode == 200 && jsonResponse['status'] == 1) {
        return ScoreResponseModel.fromJson(jsonResponse);
      } else {
        throw ScoreApiException(
          message: jsonResponse['message'] ?? 'Unknown error occurred',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      throw ScoreApiException(
        message: 'Failed to parse response or fetch data',
        statusCode: response.statusCode,
      );
    }
  }
}
