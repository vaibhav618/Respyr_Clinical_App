import 'package:get_storage/get_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The device needs a minute to cool down after a test, but the two ways a test
/// can end are surfaced differently.
///
/// An **aborted** test gets the cooling-down bottom sheet: it is an unusual
/// event and worth explaining. A **completed** reading just locks the Take Test
/// button for the remaining time, which stays out of the way of someone working
/// through a list of patients.
class AbortDeviceManager {
  static const int cooldownSeconds = 60;

  /// Seconds left after a cancelled or disconnected test.
  static int abortedRemainingSeconds() {
    final storedTimeStr = GetStorage().read('cancel_or_disconnect_time');
    if (storedTimeStr is! String) return 0;

    final storedTime = DateTime.tryParse(storedTimeStr);
    if (storedTime == null) return 0;

    final remaining =
        cooldownSeconds - DateTime.now().difference(storedTime).inSeconds;
    return remaining > 0 ? remaining : 0;
  }

  /// Seconds left after a reading that finished normally.
  static Future<int> completedRemainingSeconds() async {
    final prefs = await SharedPreferences.getInstance();
    final int? last = prefs.getInt('last_reading_time');
    if (last == null) return 0;

    final lastTime = DateTime.fromMillisecondsSinceEpoch(last);
    final remaining =
        cooldownSeconds - DateTime.now().difference(lastTime).inSeconds;
    return remaining > 0 ? remaining : 0;
  }

  /// Whichever wait is longer, for gating entry to a test.
  static Future<int> remainingSeconds() async {
    final aborted = abortedRemainingSeconds();
    final completed = await completedRemainingSeconds();
    return aborted > completed ? aborted : completed;
  }

  /// True only for a cancelled test — the case that gets the sheet.
  static Future<bool> getAbortStatus() async => abortedRemainingSeconds() > 0;
}
