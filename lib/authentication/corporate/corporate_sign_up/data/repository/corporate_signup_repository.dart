import 'dart:convert';
import 'package:http/http.dart' as http;

import '../data/corporate_signup_request.dart';

class CorporateSignUpRepository {
  final http.Client _client;
  final String endpointUrl;

  CorporateSignUpRepository({
    http.Client? client,
    required this.endpointUrl,
  }) : _client = client ?? http.Client();

  Future<Map<String, dynamic>> submitCorporateSignUp(
      CorporateSignUpRequest request,
      ) async {
    final uri = Uri.parse(endpointUrl);

    final res = await _client.post(
      uri,
      headers: {"Content-Type": "application/x-www-form-urlencoded"},
      body: request.toJson().map((k, v) => MapEntry(k, v.toString())),
    );

    print(res.body);

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception("Signup failed: ${res.statusCode}");
    }

    final body = res.body.trim();
    if (body.isEmpty) return {};

    final decoded = jsonDecode(body);

    if (decoded is Map<String, dynamic>) {
      if (decoded["success"] == false) {
        throw Exception(decoded["message"] ?? "Signup failed");
      }
      return decoded;
    }

    return {};
  }
}
