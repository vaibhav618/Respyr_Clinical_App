import 'package:get_storage/get_storage.dart';

class AbortDeviceManager{

  static Future<bool> getAbortStatus() async {
    final storage = GetStorage();
    final storedTimeStr = storage.read('cancel_or_disconnect_time');

    if (storedTimeStr != null) {
      final storedTime = DateTime.tryParse(storedTimeStr);
      if (storedTime != null) {
        final now = DateTime.now();
        final diff = now.difference(storedTime).inSeconds;
        final remaining = 60 - diff;
        if (remaining > 0) {
          return true;
        } else {
          return false;
        }
      }
    }

    return false;
  }
}