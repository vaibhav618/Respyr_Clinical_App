import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:respyr_clinical/shared/nodeurl.dart';

import '../../new_result/data/model/result_profile_data_model.dart';

class ClinicalProfileApi {
  static Future<List<ResultProfileDataModel>> fetchProfiles(
    String clinicalName,
  ) async {
    final response = await http.post(
      Uri.parse(NodeUrls.fetchClinicSubjectsProfile),
      headers: {"Content-Type": "application/json"},
      body: json.encode({"clinic_name": clinicalName}),
    );

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
