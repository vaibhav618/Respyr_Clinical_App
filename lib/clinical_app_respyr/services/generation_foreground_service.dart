import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

/// Task handler entry point. We don't run any work inside the service isolate —
/// the service exists purely to keep the MAIN app process alive (and Bluetooth
/// + network delivery flowing) while a reading result is being generated, so
/// aggressive OEMs (MIUI etc.) don't kill the app the moment it's backgrounded.
@pragma('vm:entry-point')
void generationForegroundCallback() {
  FlutterForegroundTask.setTaskHandler(_GenerationTaskHandler());
}

class _GenerationTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {}

  @override
  void onRepeatEvent(DateTime timestamp) {}

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {}
}

/// Thin wrapper around [FlutterForegroundTask] scoped to a live breath test.
///
/// Start it the moment a test session begins (breathe-tube screen) and stop it
/// only when the session ends — result shown, cancelled, or back on the
/// dashboard. While it runs, the OS keeps the process at foreground priority,
/// so aggressive OEM background killers (Samsung's `AL_Kill`, MIUI's
/// `UserDefined`) cannot terminate the app mid-test, and Bluetooth/USB/network
/// keep working even if the user minimises.
class GenerationForegroundService {
  static const int _serviceId = 4711;
  static bool _initialized = false;

  static void _ensureInit() {
    if (_initialized) return;
    _initialized = true;
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'result_generation',
        channelName: 'Breath test in progress',
        channelDescription:
            'Keeps your test running if you switch away from the app.',
        onlyAlertOnce: true,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: false,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.nothing(),
        autoRunOnBoot: false,
        autoRunOnMyPackageReplaced: false,
        allowWakeLock: true,
        allowWifiLock: true,
        // NOTE: do NOT set `stopWithTask` here. Passing it from Dart makes the
        // plugin install an ActivityLifecycleCallbacks hook that stops the
        // service on the first onActivityPaused — i.e. the instant the app is
        // minimised, which is exactly when we need it alive. Stop-on-close is
        // configured via android:stopWithTask on the service in the manifest,
        // which only fires on onTaskRemoved.
      ),
    );
  }

  /// Keep the app alive for the whole test session — calibration, inhale,
  /// exhale and result generation all talk to a connected device, and a kill at
  /// any of those points strands the user mid-test.
  static Future<void> startForTest() => _start(
    title: 'Breath test in progress',
    text: 'Keep Respyr open until the test finishes.',
  );

  /// Same service, retitled for the generation phase (BLE/USB data transfer
  /// plus the result upload). Idempotent: if the session service is already
  /// running from [startForTest], this only refreshes the notification text.
  static Future<void> startForReading() => _start(
    title: 'Generating your result',
    text: 'Please keep the app open until your result is ready.',
  );

  static Future<void> _start({
    required String title,
    required String text,
  }) async {
    try {
      _ensureInit();
      _StopOnResume.cancel();
      if (await FlutterForegroundTask.isRunningService) {
        await FlutterForegroundTask.updateService(
          notificationTitle: title,
          notificationText: text,
        );
        return;
      }
      await FlutterForegroundTask.startService(
        serviceTypes: const [
          ForegroundServiceTypes.connectedDevice,
          ForegroundServiceTypes.dataSync,
        ],
        serviceId: _serviceId,
        notificationTitle: title,
        notificationText: text,
        callback: generationForegroundCallback,
      );
    } catch (_) {
      // Never let foreground-service issues break the test flow itself.
    }
  }

  /// Stop keeping the app alive. Safe to call even if not running.
  static Future<void> stop() async {
    _StopOnResume.cancel();
    try {
      if (await FlutterForegroundTask.isRunningService) {
        await FlutterForegroundTask.stopService();
      }
    } catch (_) {
      // Ignore — stopping is best-effort cleanup.
    }
  }

  /// Stop the service once the user is actually looking at the result.
  ///
  /// If the app is already in the foreground, stop now. But if the result
  /// completed while the app was backgrounded (user minimized during
  /// generation), keep the service running — otherwise the process instantly
  /// drops to "cached" and gets low-memory killed before the user returns,
  /// landing them on the dashboard instead of their result. Instead we hold the
  /// app alive until it next comes to the foreground (user reopened → result
  /// screen visible), then stop. A timeout caps how long we ever hold it.
  static void stopWhenForegrounded() {
    final state = WidgetsBinding.instance.lifecycleState;
    if (state == null || state == AppLifecycleState.resumed) {
      stop();
    } else {
      _StopOnResume.arm();
    }
  }
}

/// Observes app lifecycle and stops the foreground service the next time the
/// app returns to the foreground (or after a safety timeout).
class _StopOnResume with WidgetsBindingObserver {
  static _StopOnResume? _instance;
  Timer? _timeout;

  static void arm() {
    _instance?._dispose();
    _instance = _StopOnResume().._start();
  }

  static void cancel() {
    _instance?._dispose();
    _instance = null;
  }

  void _start() {
    WidgetsBinding.instance.addObserver(this);
    // Never hold the app alive indefinitely if the user never returns.
    _timeout = Timer(const Duration(minutes: 3), _finish);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _finish();
    }
  }

  void _finish() {
    _dispose();
    GenerationForegroundService.stop();
  }

  void _dispose() {
    _timeout?.cancel();
    _timeout = null;
    WidgetsBinding.instance.removeObserver(this);
    if (identical(_instance, this)) _instance = null;
  }
}
