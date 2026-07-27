import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:respyr_clinical/shared/urls.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/profile_model.dart';

class ProfileRepository {
  final String apiUrl = Urls.getSubjects; // Replace with your actual endpoint

  Future<List<ProfileModel>> fetchProfiles(String clinicName) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/x-www-form-urlencoded'
      },
      body: {'clinic_name': clinicName},
    );

    final jsonData = json.decode(response.body);

    if (response.statusCode == 200 && jsonData['status'] == 'success') {
      if (jsonData.containsKey('data')) {
        return (jsonData['data'] as List)
            .map((e) => ProfileModel.fromJson(e))
            .toList();
      } else {
        return [];
      }
    } else {
      throw Exception(jsonData['message'] ?? 'Failed to load profiles');
    }
  }

}
