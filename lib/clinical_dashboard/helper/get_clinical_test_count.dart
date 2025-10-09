import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

Future<Map<String, dynamic>?> getStoredClinicalTestData() async {
  final prefs = await SharedPreferences.getInstance();
  final jsonString = prefs.getString('clinical_test_data');

  if (jsonString != null) {
    try {
      final Map<String, dynamic> data = jsonDecode(jsonString);
      return data;
    } catch (e) {
      print('Error decoding clinical_test_data: $e');
      return null;
    }
  } else {
    print('No clinical_test_data found in SharedPreferences');
    return null;
  }
}
