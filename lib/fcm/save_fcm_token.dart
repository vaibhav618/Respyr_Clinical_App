import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:respyr_clinical/shared/urls.dart';

class FCMManager{

  Future<void> saveFcmToken({
    required String loginId,
    required String fcmToken,
    String? deviceId,
  }) async {
    const String url = Urls.saveFcmToken;

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
