import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../model/subject_profile_model.dart';
import 'package:respyr_clinical/shared/nodeurl.dart';

/// Parses the profile + a page of score-history on a background isolate — a
/// subject can have hundreds of tests, and parsing them on the UI thread
/// freezes the loading shimmer.
Map<String, dynamic> _parseProfile(String body) {
  final decoded = json.decode(body);
  if (decoded['success'] == true && (decoded['data'] as List).isNotEmpty) {
    final data = decoded['data'][0];
    return {
      "profile": SubjectProfileModel.fromJson(data['profile']),
      "scores": data['scores'] as List<dynamic>,
      "hasMore": decoded['hasMore'] == true,
    };
  }
  throw Exception("Failed to load profile");
}

class SubjectProfileRepository {
  /// Fetches [profileId]'s profile + one page of its test history.
  /// [page] is 1-based; [limit] rows per page.
  Future<Map<String, dynamic>> fetchProfile(
    String clinicName,
    String profileId, {
    int page = 1,
    int limit = 15,
  }) async {
    final uri = Uri.parse(NodeUrls.fetchSubjectProfile);
    final response = await http.post(
      uri,
      headers: {"Content-Type": "application/json"},
      body: json.encode({
        "clinic_name": clinicName,
        "subject_id": profileId,
        "page": page,
        "limit": limit,
      }),
    );

    if (response.statusCode == 200) {
      return compute(_parseProfile, response.body);
    }
    throw Exception("Failed to load profile");
  }
}
