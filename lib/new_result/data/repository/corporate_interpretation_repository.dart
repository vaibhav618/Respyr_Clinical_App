import 'dart:convert';
import 'package:http/http.dart' as http;

import '../model/corporate_interpretation.dart';

class CorporateInterpretationRepository {
  final http.Client _client;
  final String baseUrl;

  CorporateInterpretationRepository({
    http.Client? client,
    required this.baseUrl,
  }) : _client = client ?? http.Client();

  Future<CorporateInterpretation> fetchInterpretation({
    required double energyUtilization,
    required double digestiveBalance,
    required double breathingEfficiency,
    required double metabolicLoad,
  }) async {
    final uri = Uri.parse(baseUrl);

    final body = {
      "energy_utilization": energyUtilization,
      "digestive_balance": digestiveBalance,
      "breathing_efficiency": breathingEfficiency,
      "metabolic_load": metabolicLoad,
    };

    final response = await _client.post(
      uri,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception("API error: ${response.statusCode} - ${response.body}");
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    return CorporateInterpretation.fromJson(decoded);
  }
}
