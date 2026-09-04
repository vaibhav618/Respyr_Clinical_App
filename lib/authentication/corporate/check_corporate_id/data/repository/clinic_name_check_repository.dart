import 'dart:convert';
import 'package:http/http.dart' as http;

import '../response/clinic_name_check_response.dart';

class ClinicNameCheckRepository {
  final http.Client _client;
  final String endpointUrl;

  ClinicNameCheckRepository({
    http.Client? client,
    required this.endpointUrl,
  }) : _client = client ?? http.Client();

  Future<ClinicNameCheckResponse> checkClinicName(String clinicName) async {
    final uri = Uri.parse(endpointUrl);

    final res = await _client.post(
      uri,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"clinic_name": clinicName}),
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception("Check failed: ${res.statusCode}");
    }

    final body = res.body.trim();
    if (body.isEmpty) {
      throw Exception("Empty response from server");
    }

    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception("Invalid response format");
    }

    final parsed = ClinicNameCheckResponse.fromJson(decoded);

    if (!parsed.success) {
      throw Exception(parsed.message.isNotEmpty ? parsed.message : "Check failed");
    }

    return parsed;
  }
}
