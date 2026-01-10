import 'dart:convert';
import 'package:http/http.dart' as http;

class ClinicalDiabeticScore {
  static const String baseUrl =
      'https://humorstech.com/humors/json_curl/all_clinic_score.php';

  Future<Map<String, dynamic>> processDiabeticScore({
    required double acetone,
    required double ethnol,
    required double blow,
    required int age,
    required String profileId,
    required String gender,
    required double h2,
    required String loginId,
    required String hardwareId,
  }) async {
    try {
      final params = {
        'acetone': acetone.toString(),
        'ethnol': ethnol.toString(),
        'blow': blow.toString(),
        'age': age.toString(),
        'login': loginId,
        'profile': profileId,
        'gender': gender,
        'hwid': hardwareId,
        'h2': h2.toString(),
      };

      final uri = Uri.parse(baseUrl).replace(queryParameters: params);
      final response = await http.get(uri);

      print(response.body.toString());

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);

        if (decoded is Map<String, dynamic>) {
          return decoded;
        } else {
          throw Exception(
              'Unexpected response format. Expected Map, got: ${decoded.runtimeType}');
        }
      } else {
        throw Exception(
            'API error [${response.statusCode}]: ${response.reasonPhrase}');
      }
    } catch (e) {
      throw Exception('Failed to fetch scores: $e');
    }
  }
}
