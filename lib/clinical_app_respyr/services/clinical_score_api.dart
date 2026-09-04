import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:respyr_clinical/shared/nodeurl.dart';

class ClinicalDiabeticScore {
  static const String baseUrl = NodeUrls.allClinicScore;

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

      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {"Content-Type": "application/json"},
        body: json.encode(params),
      );

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
