import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:respyr_clinical/shared/urls.dart';

import '../model/clinical_details_model.dart';


class ClinicDetailsRepository{
  final String baseUrl = Urls.clinicFetch;

  Future<List<ClinicalDetailsModel>> fetchClinics({
    required String token,
    required String clinicName,
  }) async {
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {
        'clinic_name': clinicName,
      },
    );

    final decoded = jsonDecode(response.body);
    if (response.statusCode == 200 && decoded['status'] == 'success') {
      return List<ClinicalDetailsModel>.from(
        (decoded['data'] as List).map((e) => ClinicalDetailsModel.fromJson(e)),
      );
    } else {
      throw Exception('Failed to fetch clinics: ${decoded['message'] ?? ''}');
    }
  }
}
