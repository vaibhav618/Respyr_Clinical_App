import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:respyr_clinical/shared/urls.dart';

import '../../new_result/data/model/result_profile_data_model.dart';

class ClinicalProfileApi {
  static Future<List<ResultProfileDataModel>> fetchProfiles(
    String clinicalName,
  ) async {
    final String baseUrl =
        '${Urls.fetchClinicSubjectsProfile}?clinic_name=$clinicalName';
    final response = await http.get(Uri.parse(baseUrl));

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);

      return data
          .map((json) => ResultProfileDataModel.fromJson(json))
          .toList();
    } else {
      throw Exception("Failed to load Clinical profiles");
    }
  }
}
