import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:respyr_clinical/shared/nodeurl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/profile_model.dart';

/// One page of profiles plus whether more pages remain on the server.
typedef ProfilePage = ({List<ProfileModel> profiles, bool hasMore, int total});

class ProfileRepository {
  final String apiUrl = NodeUrls.getSubjects; // migrated to Node backend

  /// Fetches a single page of subjects for [clinicName].
  ///
  /// [page] is 1-based, [limit] rows per page. When [search] is non-empty the
  /// server filters by profile name / subject id, so search still spans the
  /// whole clinic even though only a page is returned at a time.
  Future<ProfilePage> fetchProfiles(
    String clinicName, {
    int page = 1,
    int limit = 20,
    String search = '',
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'clinic_name': clinicName,
        'page': '$page',
        'limit': '$limit',
        if (search.isNotEmpty) 'search': search,
      }),
    );

    final jsonData = json.decode(response.body);

    if (response.statusCode == 200 && jsonData['status'] == 'success') {
      final list = (jsonData['data'] as List?) ?? [];
      final profiles =
          list.map((e) => ProfileModel.fromJson(e)).toList();
      return (
        profiles: profiles,
        hasMore: jsonData['hasMore'] == true,
        total: (jsonData['total'] as int?) ?? profiles.length,
      );
    } else {
      throw Exception(jsonData['message'] ?? 'Failed to load profiles');
    }
  }
}
