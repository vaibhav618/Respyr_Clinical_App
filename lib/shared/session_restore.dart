import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Remembers which screen the user was last on, so a process death (OEM
/// battery managers kill backgrounded apps aggressively — see MIUI) doesn't
/// dump them back on the dashboard. On relaunch the app rebuilds that screen,
/// making the kill invisible.
///
/// Only "safe to resume" screens are recorded: read-only views the user can
/// land on cold with no side effects. Test-taking flows are deliberately NOT
/// restored — a reading cannot survive a process death, and resuming into the
/// middle of one would be misleading in a clinical app.
class SessionRestore {
  static const String _key = 'last_screen_v1';

  /// Screen identifiers. Keep these stable — they're persisted.
  static const String screenDashboard = 'dashboard';
  static const String screenTestLog = 'test_log';
  static const String screenSubjectProfile = 'subject_profile';

  /// Records the screen the user is currently on.
  static Future<void> save(
    String screen, {
    Map<String, String> args = const {},
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode({
        'screen': screen,
        'args': args,
        'at': DateTime.now().millisecondsSinceEpoch,
      }),
    );
  }

  /// Reads the last recorded screen, or null if there isn't a usable one.
  ///
  /// Entries older than [maxAge] are ignored: coming back the next morning
  /// should start at the dashboard, not the subject someone looked at
  /// yesterday.
  static Future<RestoredScreen?> read({
    Duration maxAge = const Duration(hours: 2),
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(_key);
    if (raw == null) return null;

    try {
      final Map<String, dynamic> decoded = jsonDecode(raw);
      final int at = decoded['at'] as int? ?? 0;
      if (DateTime.now().millisecondsSinceEpoch - at > maxAge.inMilliseconds) {
        return null;
      }
      return RestoredScreen(
        screen: decoded['screen'] as String,
        args: Map<String, String>.from(decoded['args'] as Map? ?? {}),
      );
    } catch (_) {
      return null;
    }
  }

  /// Called on logout so the next user doesn't resume into someone else's view.
  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}

class RestoredScreen {
  final String screen;
  final Map<String, String> args;

  const RestoredScreen({required this.screen, required this.args});
}
