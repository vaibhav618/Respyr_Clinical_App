import 'dart:convert';

import 'package:http/http.dart' as http;

Future<String> fetchDeviceLastDataTime(String hwid) async {
  const String baseUrl = 'https://humorstech.com/humors_app/app_final/fetch_last_data_time2.php';

  // Add query parameters
  final Uri uri = Uri.parse(baseUrl).replace(queryParameters: {'hwid': hwid});

  try {
    // Send a GET request
    final response = await http.get(uri);

    // Check the status code and return the response body as a string
    if (response.statusCode == 200) {
      return response.body; // Return response as a string
    } else {
      return 'Error: Failed with status code ${response.statusCode}';
    }
  } catch (e) {
    return 'Error: $e';
  }
}


String getDeviceStartSignal(String response) {
  try {
    // Parse the JSON response
    final jsonObject = jsonDecode(response);

    // Extract and parse 'count'
    int count = int.tryParse(jsonObject['count'].toString()) ?? 0;

    // Extract and parse 'lastDataTime'
    int lastDataTime = int.tryParse(jsonObject['lastDataTime'].toString()) ?? 0;

    // Initialize signal
    String signal = (count == 0) ? "{" : "#";

    if (count > 0) {
      // Get the current timestamp in seconds
      int currentTimestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      // Calculate time difference in seconds
      int timeDifferenceSeconds = currentTimestamp - lastDataTime;

      // Determine the signal based on the time difference
      if (timeDifferenceSeconds <= (10 * 60)) {
        signal = "#"; // Less than or equal to 10 minutes
      } else if (timeDifferenceSeconds > (10 * 60) && timeDifferenceSeconds < (3600)) {
        signal = "\$"; // Greater than 10 minutes and less than 1 hour
      } else {
        signal = "{"; // Greater than or equal to 1 hour
      }
    }

    return signal;
  } catch (e) {
    return "{";
  }
}