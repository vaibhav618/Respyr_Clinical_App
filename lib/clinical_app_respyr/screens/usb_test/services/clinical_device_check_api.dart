import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:respyr_clinical/clinical_app_respyr/screens/usb_test/services/clinical_usb_communication_services.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> clinicalDeviceCheckApi(String deviceId) async {
  final ClinicalUsbCommunicationServices usbService =
  ClinicalUsbCommunicationServices();

  final String url =
      'https://humorstech.com/humors_app/app_final/clinical/api/fetch/fetch_last_data_time2.php?hwid=$deviceId';

  final prefs = await SharedPreferences.getInstance();
  String signal = '{';

  try {
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final jsonObject = jsonDecode(response.body);

      // Get signal from API
      if (jsonObject.containsKey("signal")) {
        final String apiSignal = jsonObject["signal"].toString();
        if (apiSignal == '#' || apiSignal == '\$' || apiSignal == '{') {
          signal = apiSignal;
        }
      }

      // Optional values
      if (jsonObject.containsKey("timeDifferenceMinutes")) {
        await prefs.setInt(
          "timeDifferenceMinutes",
          int.tryParse(jsonObject["timeDifferenceMinutes"].toString()) ?? 0,
        );
      }

      if (jsonObject.containsKey("count")) {
        await prefs.setInt(
          "today_count",
          int.tryParse(jsonObject["count"].toString()) ?? 0,
        );
      }

      if (jsonObject.containsKey("lastDataTime")) {
        await prefs.setInt(
          "lastDataTime",
          int.tryParse(jsonObject["lastDataTime"].toString()) ?? 0,
        );
      }
    }
  } catch (e) {
    signal = '{';
  }

  // 🔥 CLEAN OLD SIGNAL BEFORE SAVING NEW ONE
  await prefs.remove("isFirstReading");

  // (optional cleanup if you want fully clean state)
  // await prefs.remove("timeDifferenceMinutes");
  // await prefs.remove("today_count");
  // await prefs.remove("lastDataTime");

  // ✅ SAVE FRESH VALUES
  await prefs.setString("isFirstReading", signal);
  await prefs.setBool("is_device_ready", true);

  // Send to device
  usbService.sendData(signal);
  usbService.sendData("%");
}
