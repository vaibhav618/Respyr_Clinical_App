import 'dart:convert';
import 'package:http/http.dart' as http;

import '../model/set_password_request.dart';

class SetPasswordRepository {
  final String endpointUrl;
  final http.Client _client;

  SetPasswordRepository({
    required this.endpointUrl,
    http.Client? client,
  }) : _client = client ?? http.Client();

  Future<Map<String, dynamic>> setPassword(SetPasswordRequest request) async {
    final uri = Uri.parse(endpointUrl);

    final res = await _client.post(
      uri,
      headers: {
        "Content-Type": "application/x-www-form-urlencoded",
        "Accept": "application/json",
      },
      body: request.toFormData(),
    );

    final body = res.body.trim();
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception("Server error: ${res.statusCode}");
    }

    if (body.isEmpty) {
      throw Exception("Empty response from server");
    }

    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception("Invalid response format");
    }

    final success = decoded["success"] == true;
    if (!success) {
      throw Exception(decoded["message"] ?? "Failed to set password");
    }

    return decoded;
  }
}
