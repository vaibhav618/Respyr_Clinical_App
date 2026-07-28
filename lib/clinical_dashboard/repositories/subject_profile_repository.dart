import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../model/subject_profile_model.dart';
import 'package:respyr_clinical/shared/urls.dart';

/// Parses the profile + score-history response on a background isolate —
/// a subject can have hundreds of tests, and parsing them on the UI thread
/// freezes the loading shimmer.
Map<String, dynamic> _parseProfile(String body) {
  final decoded = json.decode(body);
  if (decoded['success'] == true && decoded['data'].isNotEmpty) {
    final data = decoded['data'][0];
    return {
      "profile": SubjectProfileModel.fromJson(data['profile']),
      "scores": data['scores'],
    };
  }
  throw Exception("Failed to load profile");
}

class SubjectProfileRepository {
  Future<Map<String, dynamic>> fetchProfile(
    String clinicName,
    String profileId,
  ) async {
    final uri = Uri.parse(
      '${Urls.fetchSubjectProfile}clinic_name=$clinicName&subject_id=$profileId',
    );
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      return compute(_parseProfile, response.body);
    }
    throw Exception("Failed to load profile");
  }
}
