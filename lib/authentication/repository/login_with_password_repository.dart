import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:respyr_clinical/shared/nodeurl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/login_with_password_response.dart';

class LoginWithPasswordRepository {
  Future<LoginWithPasswordResponse> login(String adminId, String password) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    final response = await http.post(
      Uri.parse(NodeUrls.validateLoginWithPassword),
      headers: {
        "Content-Type": "application/json",
        if (token != null && token.isNotEmpty) "Authorization": "Bearer $token",
      },
      body: jsonEncode({
        "input": adminId,
        "password": password,
      }),
    );



    final Map<String, dynamic> json = jsonDecode(response.body);

    return LoginWithPasswordResponse(
      status: json['status'],
      message: json['message'],
      count: json['count'] ?? 0,
      data: json['data'] != null
          ? List<UserData>.from(json['data'].map((x) => UserData.fromJson(x)))
          : [],
    );
  }
}



