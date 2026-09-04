import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:respyr_clinical/shared/nodeurl.dart';

class UserUpdateRegionService {
  Future<Map<String, dynamic>> updateRegion({
    required String loginId,
    required String profileId,
    required String region,
  }) async {
    final url = Uri.parse(NodeUrls.updateUserRegion);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    if (token == null) {
      return {
        'status_code': 401,
        'body': "Invalid or expired token: Expired token",
      };
    }

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'login_id': loginId, 'profile_id': profileId, 'region': region}),
    );

    final decodedBody = jsonDecode(response.body);

    print("decodedBody :${response.body}");

    return {'status_code': response.statusCode, 'body': decodedBody};
  }
}
