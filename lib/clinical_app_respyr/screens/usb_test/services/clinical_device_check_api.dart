import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:respyr_clinical/clinical_app_respyr/screens/usb_test/services/clinical_usb_communication_services.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> clinicalDeviceCheckApi(String deviceId) async {

  final ClinicalUsbCommunicationServices usbService =
  ClinicalUsbCommunicationServices();

  final String url =
      'https://humorstech.com/humors_app/app_final/clinical/api/fetch/fetch_last_data_time2.php?hwid=$deviceId';

  try {
    final response = await http.get(Uri.parse(url));

    String signal = '{';

    final prefs = await SharedPreferences.getInstance();

    if (response.statusCode == 200) {
      final jsonObject = jsonDecode(response.body);

      if (jsonObject.containsKey("count") &&
          jsonObject.containsKey("lastDataTime")) {
        final int count = int.tryParse(jsonObject['count'].toString()) ?? 0;
        final int lastDataTime =
            int.tryParse(jsonObject["lastDataTime"].toString()) ?? 0;


        if (count > 0) {
          final int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
          final int diff = now - lastDataTime;


          if (diff <= 600) {
            signal = '#';
          } else if (diff <= 3600) {
            signal = '\$';
          } else {
            signal = '{';
          }
        }

        final int lastAbortTime =
            prefs.getInt("last_abort_time_full_test") ?? 0;
        final int counter = prefs.getInt("abort_counter") ?? 0;


        if (signal == '{' && lastAbortTime != 0 && counter != 0) {
          final int nowMillis = DateTime.now().millisecondsSinceEpoch;
          final double timeDiffMinutes =
              (nowMillis - lastAbortTime) / 60000.0;
          if (timeDiffMinutes > 10) {
            signal = '\$';
          } else {
            signal = '#';
          }
        }
      }
    }

    await prefs.setString("isFirstReading", signal);
    await prefs.setBool("is_device_ready", true);

    usbService.sendData(signal);
    usbService.sendData("%");

  } catch (e) {

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("is_first_reading", "{");
    await prefs.setBool("is_device_ready", true);


    usbService.sendData("{");
    usbService.sendData("%");
  }
}
