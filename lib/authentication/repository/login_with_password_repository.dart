import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../model/login_with_password_response.dart';

class LoginWithPasswordRepository {
  Future<LoginWithPasswordResponse> login(String adminId, String password) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    final response = await http.post(
      Uri.parse("https://humorstech.com/humors_app/app_final/clinical/api/fetch/validate_login_with_password.php"),
      headers: {
        "Content-Type": "application/x-www-form-urlencoded",
        if (token != null && token.isNotEmpty) "Authorization": "Bearer $token",
      },
      body: {
        "input": adminId,
        "password": password,
      },
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



