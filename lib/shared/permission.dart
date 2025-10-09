import 'dart:io';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

Future<void> requestSmsPermissions(BuildContext context) async {
  // Request SMS permission
  PermissionStatus smsPermissionStatus = await Permission.sms.request();

  if (Platform.isAndroid) {
    // Check if permission is granted
    if (smsPermissionStatus.isGranted) {
      // Permission is granted, you can now access SMS features
      print('SMS permission granted');
    } else if (smsPermissionStatus.isDenied) {
      // Permission is denied by the user
      print('SMS permission denied');
      _showPermissionDeniedDialog(context); // Pass context to the dialog
    } else if (smsPermissionStatus.isPermanentlyDenied) {
      // Permission is permanently denied, handle accordingly
      print(
          'SMS permission permanently denied. Please enable it from settings.');
      // Optionally, open the app settings to let the user enable the permission
      openAppSettings();
    }
  } else if(Platform.isIOS){
    debugPrint('No SMS permission is required for iOS');
  }
}

void _showPermissionDeniedDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Permission Required'),
        content: const Text(
            'SMS permission is required to autofill OTP. Please enable it in settings.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close the dialog
            },
            child: const Text('OK'),
          ),
        ],
      );
    },
  );
}
