import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:respyr_clinical/shared/urls.dart';

Future<String> fetchDeviceLastDataTime(String hwid) async {
  const String baseUrl = Urls.fetchLastDataTime;

  final Uri uri = Uri.parse(baseUrl).replace(queryParameters: {'hwid': hwid});

  try {
    debugPrint("➡️ fetchDeviceLastDataTime | HWID: $hwid");
    debugPrint("➡️ Request URL: $uri");

    final response = await http.get(uri);

    debugPrint("⬅️ Response Status Code: ${response.statusCode}");
    debugPrint("⬅️ Raw Response Body: ${response.body}");

    if (response.statusCode == 200) {
      return response.body;
    } else {
      debugPrint("❌ API Error: ${response.statusCode}");
      return 'Error: Failed with status code ${response.statusCode}';
    }
  } catch (e) {
    debugPrint("❌ Exception in fetchDeviceLastDataTime: $e");
    return 'Error: $e';
  }
}

String getDeviceStartSignal(String response) {
  try {
    debugPrint("➡️ getDeviceStartSignal | Raw Response: $response");

    final jsonObject = jsonDecode(response);

    debugPrint("📦 Decoded JSON: $jsonObject");

    if (jsonObject.containsKey("signal")) {
      final String apiSignal = jsonObject["signal"].toString();

      debugPrint("✅ Signal received from API: $apiSignal");

      if (apiSignal == "#" || apiSignal == "\$" || apiSignal == "{") {
        return apiSignal;
      } else {
        debugPrint("⚠️ Invalid signal value received");
      }
    } else {
      debugPrint("⚠️ 'signal' key not found in API response");
    }

    return "{";
  } catch (e) {
    debugPrint("❌ Exception in getDeviceStartSignal: $e");
    return "{";
  }
}
