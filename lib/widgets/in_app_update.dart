import 'dart:io';
import 'package:in_app_update/in_app_update.dart';

Future<void> checkForUpdate() async {
  try {
    // 1. Skip if no internet
    final result = await InternetAddress.lookup(
      'google.com',
    ).timeout(Duration(seconds: 3), onTimeout: () => []);
    if (result.isEmpty || result.first.rawAddress.isEmpty) {
      print("checkForUpdate: Skipped - No internet connection");
      return;
    }

    // 2. Try checking for update
    final AppUpdateInfo updateInfo = await InAppUpdate.checkForUpdate();

    if (updateInfo.updateAvailability == UpdateAvailability.updateAvailable) {
      // Flexible update
      if (!updateInfo.immediateUpdateAllowed &&
          updateInfo.flexibleUpdateAllowed) {
        try {
          await InAppUpdate.startFlexibleUpdate();
          await InAppUpdate.completeFlexibleUpdate();
        } catch (e) {
          print("checkForUpdate: Flexible update failed - $e");
        }
      }
      // Immediate update
      else if (updateInfo.immediateUpdateAllowed) {
        try {
          await InAppUpdate.performImmediateUpdate();
        } catch (e) {
          print("checkForUpdate: Immediate update failed - $e");
        }
      }
    }
  } catch (e) {
    // Catch specific Play Core "app not owned" error or other exceptions
    print("checkForUpdate: Error - $e");
  }
}
