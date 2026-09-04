import 'dart:convert';
import 'package:http/http.dart' as http;

import '../response/corporate_login_response.dart';

class CorporateLoginRepository {
  final http.Client _client;
  final String endpointUrl;

  CorporateLoginRepository({
    http.Client? client,
    required this.endpointUrl,
  }) : _client = client ?? http.Client();

  Future<CorporateLoginResponse> login({
    required String email,
    required String password,
  }) async {
    final uri = Uri.parse(endpointUrl);

    final res = await _client.post(
      uri,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "email": email.trim(),
        "password": password,
      }),
    );

    final body = res.body.trim();

    print(res.body);

    // Your API returns 401 on invalid login — handle that too
    if (res.statusCode != 200) {
      if (body.isNotEmpty) {
        try {
          final decoded = jsonDecode(body);
          if (decoded is Map<String, dynamic>) {
            final msg = (decoded["message"] ?? "Login failed").toString();
            throw Exception(msg);
          }
        } catch (_) {}
      }
      throw Exception("Login failed (${res.statusCode})");
    }

    if (body.isEmpty) {
      throw Exception("Empty response from server");
    }

    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception("Invalid response format");
    }

    final parsed = CorporateLoginResponse.fromJson(decoded);

    if (parsed.success != true) {
      throw Exception(parsed.message.isNotEmpty ? parsed.message : "Login failed");
    }

    if (parsed.data == null) {
      throw Exception("Login failed: missing user data");
    }

    return parsed;
  }
}
