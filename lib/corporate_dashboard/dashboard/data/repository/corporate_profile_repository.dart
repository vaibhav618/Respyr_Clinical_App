import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../../../authentication/corporate/corporate_login/data/response/corporate_login_response.dart';

class CorporateProfileRepository {
  final http.Client _client;
  final String endpointUrl;

  CorporateProfileRepository({
    http.Client? client,
    required this.endpointUrl,
  }) : _client = client ?? http.Client();

  Future<CorporateLoginResponse> fetchProfileByEmail(String email) async {
    final uri = Uri.parse(endpointUrl);

    final res = await _client.post(
      uri,
      headers: {"Content-Type": "application/x-www-form-urlencoded"},
      body: {"email": email.trim()},
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception("Fetch failed: ${res.statusCode}");
    }

    final raw = res.body.trim();
    if (raw.isEmpty) {
      throw Exception("Empty response from server");
    }

    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      throw Exception("Invalid response format");
    }

    final parsed = CorporateLoginResponse.fromJson(decoded);

    if (!parsed.success) {
      throw Exception(parsed.message.isNotEmpty ? parsed.message : "Fetch failed");
    }

    if (parsed.data == null) {
      throw Exception("No profile data returned");
    }

    return parsed;
  }

  void dispose() {
    _client.close();
  }
}
