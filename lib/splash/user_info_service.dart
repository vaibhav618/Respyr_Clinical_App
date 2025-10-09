import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:respyr_clinical/splash/user_info_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/urls.dart';


class UserInfoService {
  static const String baseUrl = Urls.fetchUserdata;

  /// High-level method for simplified use
  static Future<List<UserInfoModel>> fetchUserData(String input, String loginId) async {
    final response = await fetchRawResponse(input, loginId);

    if (response.statusCode == 200 && response.data['status'] == 'success') {
      List dataList = response.data['data'];
      return dataList.map((e) => UserInfoModel.fromJson(e)).toList();
    } else {
      throw Exception(response.data['message'] ?? 'Failed to load data');
    }
  }

  /// Full control for detailed error/status handling
  static Future<ApiResponseWrapper> fetchRawResponse(String input, String loginId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    if(token==null){
      return ApiResponseWrapper(
        statusCode: 401,
        data: null,
      );
    }

    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {
        'input': input,
        'login_id': loginId,
      },
    );


    final decoded = json.decode(response.body);

    return ApiResponseWrapper(
      statusCode: response.statusCode,
      data: decoded,
    );
  }
}

/// Response wrapper with code + data
class ApiResponseWrapper {
  final int statusCode;
  final dynamic data;

  ApiResponseWrapper({required this.statusCode, required this.data});
}
