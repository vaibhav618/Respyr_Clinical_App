import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Remembers which subject was tested and when, so the subjects list can lead
/// with whoever was seen most recently.
///
/// Recorded on this device rather than read from the subjects API, because the
/// `dttm` that API returns is the profile's own timestamp — it does not move
/// when a reading is taken, so sorting by it would show newest *profiles*
/// first, not most recently *tested* subjects.
class RecentSubjects {
  static const String _key = 'recent_subject_tests';

  /// Cap the stored history. A clinic accumulates subjects indefinitely and
  /// only the recent ones affect the ordering anyone notices.
  static const int _maxEntries = 200;

  /// Records that [subjectId] has just been tested.
  static Future<void> markTested(String subjectId) async {
    if (subjectId.isEmpty) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final Map<String, int> tested = await _read(prefs);

      tested[subjectId] = DateTime.now().millisecondsSinceEpoch;

      if (tested.length > _maxEntries) {
        final entries = tested.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        tested
          ..clear()
          ..addEntries(entries.take(_maxEntries));
      }

      await prefs.setString(_key, jsonEncode(tested));
    } catch (e) {
      // Ordering is a convenience — never let it interfere with a reading.
      debugPrint("RecentSubjects.markTested failed: $e");
    }
  }

  /// Subject id to the time it was last tested, in epoch milliseconds.
  static Future<Map<String, int>> lastTestedTimes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await _read(prefs);
    } catch (e) {
      debugPrint("RecentSubjects.lastTestedTimes failed: $e");
      return <String, int>{};
    }
  }

  static Future<Map<String, int>> _read(SharedPreferences prefs) async {
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return <String, int>{};

    final decoded = jsonDecode(raw);
    if (decoded is! Map) return <String, int>{};

    return decoded.map(
      (key, value) => MapEntry("$key", value is int ? value : 0),
    );
  }
}
