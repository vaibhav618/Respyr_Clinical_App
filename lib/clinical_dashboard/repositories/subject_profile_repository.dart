import 'dart:convert';
import 'package:http/http.dart' as http;

import '../model/subject_profile_model.dart';
import '../utils/urls.dart';


class SubjectProfileRepository {
  Future<Map<String, dynamic>> fetchProfile(String clinicName, String profileId) async {
    final uri = Uri.parse(
      '${Urls.fetchSubjectProfile}clinic_name=$clinicName&subject_id=$profileId',
    );
    final response = await http.get(uri);


    print(uri);
    print(response.body);
    print(response.statusCode.toString());
    if (response.statusCode == 200) {
      final body = json.decode(response.body);
      if (body['success'] == true && body['data'].isNotEmpty) {
        final data = body['data'][0];
        return {
          "profile": SubjectProfileModel.fromJson(data['profile']),
          "scores": data['scores']
        };
      }
    }
    throw Exception("Failed to load profile");
  }
}
