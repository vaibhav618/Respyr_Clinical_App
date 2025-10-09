import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../log_manager/log_manager.dart';

class CreateProfileService {
  final String baseUrl = "https://humorstech.com/humors_app/app_final/clinical/api/insert/";
  final String endpoint = "create_user_profile.php";

  Future<Map<String, dynamic>> createProfile({
    required String clinicName,
    required String profileName,
    required String gender,
    required String age,
    required String height,
    required String weight,
    required String region,
    String? phone,
    String? email,
  }) async {
    final uri = Uri.parse('$baseUrl$endpoint');

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/x-www-form-urlencoded',
    };

    final body = {
      'clinic_name': clinicName,
      'profile_name': profileName,
      'gender': gender,
      'age': age,
      'height': height,
      'weight': weight,
      'region': region,
      'phone': "not_available",
      'email': "not_available",
    };

    // Log profile creation attempt
    LogManager().logEvent(
      event: 'CREATE_PROFILE_ATTEMPT',
      apiUrl: uri.toString(),
      status: 'ATTEMPT',
      details: 'Attempting to create profile: $profileName in clinic: $clinicName',
    );

    try {
      final response = await http.post(uri, headers: headers, body: body);

      print(response.statusCode);
      print(response.body);

      final decoded = json.decode(response.body);

      if (response.statusCode == 200) {
        // Log success or API-level error inside 200
        if (decoded is Map && (decoded['status'] == 'success' || decoded['status'] == 'SUCCESS')) {
          LogManager().logEvent(
            event: 'CREATE_PROFILE_SUCCESS',
            apiUrl: uri.toString(),
            status: 'SUCCESS',
            details: 'Profile created: $profileName in clinic: $clinicName',
          );
        } else {
          LogManager().logEvent(
            event: 'CREATE_PROFILE_API_ERROR',
            apiUrl: uri.toString(),
            status: 'FAILED',
            details: 'API error while creating $profileName: ${decoded['message'] ?? 'Unknown error'}',
          );
        }

        return {
          'status_code': response.statusCode,
          'body': decoded,
        };
      } else {
        // Log HTTP error but preserve backend error message
        LogManager().logEvent(
          event: 'CREATE_PROFILE_FAILED',
          apiUrl: uri.toString(),
          status: 'FAILED',
          details: decoded is Map
              ? 'API Error: ${decoded['message']}'
              : 'HTTP ${response.statusCode}: ${response.reasonPhrase ?? 'Unknown error'} for $profileName',
        );

        return {
          'status_code': response.statusCode,
          'body': decoded is Map
              ? decoded
              : {
            'status': 'error',
            'message': 'HTTP ${response.statusCode}: ${response.reasonPhrase ?? 'Unknown error'}',
          }
        };
      }
    } catch (e) {
      // Log exception
      LogManager().logEvent(
        event: 'CREATE_PROFILE_EXCEPTION',
        apiUrl: uri.toString(),
        status: 'EXCEPTION',
        details: 'Exception: $e while creating $profileName',
      );
      return {
        'status_code': 500,
        'body': {
          'status': 'error',
          'message': 'Exception: $e',
        }
      };
    }
  }
}

class CreateProfileResponse {
  final String status;
  final String message;
  final ProfileData data;

  CreateProfileResponse({
    required this.status,
    required this.message,
    required this.data,
  });

  factory CreateProfileResponse.fromJson(Map<String, dynamic> json) {
    LogManager().logEvent(
      event: 'CREATE_PROFILE_RESPONSE_PARSED',
      status: 'SUCCESS',
      details: 'Profile response parsed with status: ${json['status']} and message: ${json['message']}',
    );
    return CreateProfileResponse(
      status: json['status'],
      message: json['message'],
      data: ProfileData.fromJson(json['data']),
    );
  }
}

class ProfileData {
  final String subjectId;
  final String clinicName;
  final String profileName;
  final String gender;
  final int age;
  final double height;
  final double weight;
  final String region;
  final String dttm;

  ProfileData({
    required this.subjectId,
    required this.clinicName,
    required this.profileName,
    required this.gender,
    required this.age,
    required this.height,
    required this.weight,
    required this.region,
    required this.dttm,
  });

  factory ProfileData.fromJson(Map<String, dynamic> json) {
    return ProfileData(
      subjectId: json['subject_id'],
      clinicName: json['clinic_name'],
      profileName: json['profile_name'],
      gender: json['gender'],
      region: json['region'],
      age: json['age'] is int ? json['age'] : int.tryParse(json['age'].toString()) ?? 0,
      height: json['height'] is double
          ? json['height']
          : double.tryParse(json['height'].toString()) ?? 0.0,
      weight: json['weight'] is double
          ? json['weight']
          : double.tryParse(json['weight'].toString()) ?? 0.0,
      dttm: json['dttm'],
    );
  }
}
