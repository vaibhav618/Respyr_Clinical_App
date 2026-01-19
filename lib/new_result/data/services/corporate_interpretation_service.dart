import 'dart:convert';
import 'package:http/http.dart' as http;

import '../model/corporate_interpretation.dart';

class CorporateInterpretationService {
  final String apiUrl;

  CorporateInterpretationService({required this.apiUrl});

  Future<CorporateInterpretation> fetchCorporateInterpretation({
    required double energyUtilization,
    required double digestiveBalance,
    required double breathingEfficiency,
    required double metabolicLoad,
  }) async {
    final uri = Uri.parse(apiUrl);

    final requestBody = {
      "energy_utilization": energyUtilization,
      "digestive_balance": digestiveBalance,
      "breathing_efficiency": breathingEfficiency,
      "metabolic_load": metabolicLoad,
    };

    final response = await http.post(
      uri,
      headers: const {
        "Content-Type": "application/json",
      },
      body: jsonEncode(requestBody),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        "Failed to fetch interpretation (${response.statusCode})",
      );
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;

    return CorporateInterpretation.fromJson(decoded);
  }
}
