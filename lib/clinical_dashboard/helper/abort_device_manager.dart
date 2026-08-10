import 'package:get_storage/get_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Why the device is cooling down, so the wait can be explained accurately.
enum CooldownReason {
  /// The previous test was cancelled or the device disconnected part-way.
  aborted,

  /// The previous reading completed normally.
  completed,
}

/// How long the device still needs before another test, and why.
class DeviceCooldown {
  const DeviceCooldown({required this.remainingSeconds, required this.reason});

  final int remainingSeconds;
  final CooldownReason reason;

  bool get isCoolingDown => remainingSeconds > 0;
}

/// The device needs a minute to cool down after a test before it can run
/// another, whether that test finished or was abandoned part-way.
///
/// The two cases are recorded separately — a cancel or disconnect writes
/// `cancel_or_disconnect_time`, a completed reading writes `last_reading_time`
/// — so both are consulted here and whichever leaves longer to wait wins.
/// Keeping the answer in one place is what lets every entry point show the same
/// cooling-down sheet, rather than one path showing a sheet and another a toast.
class AbortDeviceManager {
  static const int cooldownSeconds = 60;

  static Future<DeviceCooldown> getCooldown() async {
    final DateTime now = DateTime.now();

    int abortedRemaining = 0;
    final storedTimeStr = GetStorage().read('cancel_or_disconnect_time');
    if (storedTimeStr is String) {
      final storedTime = DateTime.tryParse(storedTimeStr);
      if (storedTime != null) {
        abortedRemaining =
            cooldownSeconds - now.difference(storedTime).inSeconds;
      }
    }

    int completedRemaining = 0;
    final prefs = await SharedPreferences.getInstance();
    final int? last = prefs.getInt('last_reading_time');
    if (last != null) {
      final lastTime = DateTime.fromMillisecondsSinceEpoch(last);
      completedRemaining = cooldownSeconds - now.difference(lastTime).inSeconds;
    }

    // Report the reason behind the wait the user is actually serving.
    if (abortedRemaining >= completedRemaining) {
      return DeviceCooldown(
        remainingSeconds: abortedRemaining > 0 ? abortedRemaining : 0,
        reason: CooldownReason.aborted,
      );
    }
    return DeviceCooldown(
      remainingSeconds: completedRemaining > 0 ? completedRemaining : 0,
      reason: CooldownReason.completed,
    );
  }

  static Future<bool> getAbortStatus() async =>
      (await getCooldown()).isCoolingDown;
}
