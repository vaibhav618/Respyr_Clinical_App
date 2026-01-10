import 'dart:convert';
import 'package:http/http.dart' as http;
import '../model/corporate_profile_tests_response.dart';

class CorporateProfileTestsRepository {
  final String endpointUrl;
  final http.Client _client;

  CorporateProfileTestsRepository({
    required this.endpointUrl,
    http.Client? client,
  }) : _client = client ?? http.Client();

  Future<CorporateProfileTestsResponse> fetchTests({
    required String loginId,
    required String profileId,
    String? date, // MM/DD/YYYY
  }) async {
    final res = await _client.post(
      Uri.parse(endpointUrl),
      headers: {"Content-Type": "application/x-www-form-urlencoded"},
      body: {
        "login_id": loginId,
        "profile_id": profileId,
        if (date != null && date.isNotEmpty) "date": date,
      },
    );

    if (res.statusCode != 200) {
      throw Exception("Server error ${res.statusCode}");
    }

    final decoded = jsonDecode(res.body);
    final parsed = CorporateProfileTestsResponse.fromJson(decoded);

    if (!parsed.success) {
      throw Exception(parsed.message);
    }

    // ✅ CORRECT: read latest_of_date
    final latest = parsed.data?.latestOfDate;

    if (latest == null) {
      print("✅ latest_of_date: EMPTY for date=$date");
    } else {
      print(
        "✅ latest_of_date for date=$date -> "
            "dttm=${latest.dttm}, "
            "Db=${latest.dbScore}, "
            "Gut=${latest.gutScorePer}, "
            "Liver=${latest.liverScore}, "
            "Blow=${latest.blowScore}",
      );

      // Raw debug (full object)
      // print("RAW latest_of_date => ${jsonEncode(latest.toJson())}");
    }

    return parsed;
  }
}
