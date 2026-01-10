import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../new_result/data/model/result_model.dart';


class CorporateResultHistoryService {


  Future<NewResultModel> fetchSingleResult({
    required int id,
    required String loginId,
    required String profileId,
  }) async {
    final response = await http.post(
      Uri.parse("https://humorstech.com/humors_app/app_final/clinical/fetch_corporate_history.php"),
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {
        'id': id.toString(),
        'login_id': loginId,
        'profile_id': profileId,
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Server error: ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body);

    if (decoded == null || decoded['status'] != 'success') {
      throw Exception(decoded['message'] ?? 'Unknown error');
    }

    final data = decoded['data'];
    if (data == null || data is! Map<String, dynamic>) {
      throw Exception('Invalid response format');
    }

    return NewResultModel.fromJson(data);
  }
}
