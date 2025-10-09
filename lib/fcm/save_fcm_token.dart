import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class FCMManager{

  Future<void> saveFcmToken({
    required String loginId,
    required String fcmToken,
    String? deviceId,
  }) async {
    const String url = 'https://humorstech.com/humors_app/app_final/clinical/api/insert/save_fcm_token.php';

    try {
       await http.post(
        Uri.parse(url),
        body: {
          'login_id': loginId,
          'fcm_token': fcmToken,
          if (deviceId != null) 'device_id': deviceId,
        },
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error saving FCM token: $e');
      }
    }
  }
}
