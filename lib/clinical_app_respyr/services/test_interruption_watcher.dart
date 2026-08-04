import 'package:flutter/widgets.dart';

/// Detects the app being sent to the background part-way through a test.
///
/// The device runs its own real-time sequence — calibrate, then "inhale", then
/// "blownow" — and each step waits on an actual breath from the subject. The
/// foreground service keeps our process alive across a minimise, but it cannot
/// keep the *person* in front of the device. Someone who leaves the app and
/// comes back a few minutes later misses the inhale cue entirely, so the device
/// sits waiting for a breath that never arrives and the Hold screen strands at
/// 00 with no way forward.
///
/// A breath test whose subject wasn't following the prompts must not produce a
/// reading, so the screens use this to notice the interruption and start over
/// rather than continue a sequence that has already desynchronised.
class TestInterruptionWatcher with WidgetsBindingObserver {
  TestInterruptionWatcher({
    required this.onInterrupted,
    this.threshold = const Duration(seconds: 5),
  });

  /// Called once, on resume, if the app was away longer than [threshold].
  final VoidCallback onInterrupted;

  /// Short enough to catch a real absence, long enough to ignore the transient
  /// pauses Android fires for permission dialogs and the USB-attached prompt.
  final Duration threshold;

  DateTime? _leftAt;
  bool _fired = false;

  void start() => WidgetsBinding.instance.addObserver(this);

  void stop() => WidgetsBinding.instance.removeObserver(this);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.inactive) {
      _leftAt ??= DateTime.now();
      return;
    }

    if (state != AppLifecycleState.resumed) return;

    final DateTime? leftAt = _leftAt;
    _leftAt = null;
    if (leftAt == null || _fired) return;

    final Duration away = DateTime.now().difference(leftAt);
    if (away < threshold) return;

    _fired = true;
    debugPrint("⚠️ Test interrupted — app was in the background for $away");
    onInterrupted();
  }
}
