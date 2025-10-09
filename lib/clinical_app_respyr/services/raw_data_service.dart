import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:async';

class RawDataService {
  final String baseUrl;

  RawDataService(this.baseUrl);

  Future<String> fetchRawData({
    required String bFlag2,
    required String deviceRawData,
    required String loginId,
    required String profileId,
    required String gender,
    required int aboutCounter,
  }) async {
    String exractedRawData =
        deviceRawData.split('\n').map((line) => line.trim()).join();

    final uri = Uri.parse(baseUrl).replace(queryParameters: {
      'bflag': bFlag2,
      'bpm': '78',
      'testdata': exractedRawData,
      'subid': '$loginId\$$profileId',
      'sp': '0',
      'dp': '0',
      'abortcounter': aboutCounter.toString(),
      'spo2': '120',
      'gender': gender,
    });

    if (kDebugMode) {
      print("Final raw Data URL: $uri");
      print("bflag: $bFlag2");
      print("deviceRawData: $deviceRawData");
      print("exractedRawData: $exractedRawData");
      print("aboutCounter: $aboutCounter");
      print("gender: $gender");
    }

    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        if (kDebugMode) {
          print("Request successful. Response: ${response.body}");
        }
        return response.body;
      } else {
        if (kDebugMode) {
          print("Request failed with status: ${response.statusCode}");
        }
        throw Exception("Failed to fetch data: ${response.statusCode}");
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error occurred: $e");
      }
      throw Exception("Error occurred while fetching data");
    }
  }

  List<Map<String, String>> parseJsonData(String jsonString) {
    try {
      final decodedJson = json.decode(jsonString);

      if (decodedJson is Map<String, dynamic> &&
          decodedJson.containsKey('data')) {
        final List<dynamic> dataList = decodedJson['data'];

        return dataList.map((item) {
          final Map<String, String> parsedItem = {};

          item.forEach((key, value) {
            try {
              // Safely parse values and handle various data types.
              if (value is double || value is int) {
                parsedItem[key] = value.toString();
              } else if (value is String) {
                final parsedDouble = double.tryParse(value);
                parsedItem[key] = parsedDouble?.toString() ?? value;
              } else {
                parsedItem[key] = value?.toString() ?? 'null';
              }
            } catch (e) {
              if (kDebugMode) {
                print("Error parsing value for key '$key': $e");
              }
              parsedItem[key] = 'null'; // Default value for invalid entries.
            }
          });

          return parsedItem;
        }).toList();
      } else {
        throw Exception("Invalid JSON format or missing 'data' key");
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error while parsing JSON: $e");
      }
      if (!jsonString.trim().startsWith("{") &&
          !jsonString.trim().startsWith("[")) {
        throw Exception("Non-JSON response received: $jsonString");
      }
      if (kDebugMode) {
        print("Malformed JSON: $jsonString");
      }
      throw Exception("Error while parsing JSON");
    }
  }
}
