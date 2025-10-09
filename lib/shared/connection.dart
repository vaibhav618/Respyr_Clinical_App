import 'dart:io';

import 'package:respyr_clinical/shared/print_app.dart';

class Connection {
  static Future<bool> isConnected() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        return true;
      }
    } on SocketException catch (_) {
      appPrint(message: "Internet not Connected !!!!");
      return false;
    }
    appPrint(message: 'last statement of connection');
    return true;
  }
}
