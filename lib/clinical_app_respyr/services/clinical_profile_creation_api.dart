import 'dart:convert';

import 'package:http/http.dart' as http;

class ClinicalPatientProfileApi {
  final String baseUrl =
      'https://humorstech.com/humors_app/app_final/create_patient_profile.php';
  Future<Map<String, dynamic>> clinicalProfileInfo({
    required String clinicalName,
    required String profileName,
    required String gender,
    required int age,
    required int height,
    required int weight,
  }) async {
    try {
      final params = {
        'clinic_name': clinicalName,
        'profile_name': profileName,
        'gender': gender,
        'age': age.toString(),
        'height': height.toString(),
        'weight': weight.toString(),
      };

      final uri = Uri.parse(baseUrl).replace(queryParameters: params);
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        if (decoded is Map<String, dynamic>) {
          return decoded;
        } else {
          throw Exception(
              'Unexpected response format. Expected Map, got: ${decoded.runtimeType}');
        }
      } else {
        throw Exception(
            'Api Error Occured [${response.statusCode}]: ${response.reasonPhrase}');
      }
    } catch (e) {
      throw Exception('Failed to fetch Data: $e');
    }
  }
}
