import 'dart:convert';

import 'package:http/http.dart' as http;

class ClinicalIdGeneratingApi {
  static const String _baseUrl =
      "https://humorstech.com/humors_app/app_final/get_clinical_id.php";

  Future<Map<String, dynamic>> fetchClinicalIdApi(String phoneNumber) async {
    try {
      final Uri url = Uri.parse("$_baseUrl?phone_no=$phoneNumber");
      final response = await http.get(url);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {
          "status": "error",
          "message": "server responded with ${response.statusCode}",
        };
      }
    } catch (e) {
      return {"status": "error", "message": "something went wrong: $e"};
    }
  }
}
