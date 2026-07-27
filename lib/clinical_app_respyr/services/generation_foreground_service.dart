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

/// Thin wrapper around [FlutterForegroundTask] scoped to result generation.
///
/// Start it when generation begins (BLE data transfer + result API call) and
/// stop it as soon as the result is shown or the attempt ends. While running,
/// the OS keeps the process at foreground priority so it is not low-memory
/// killed and Bluetooth/network keep working in the background.
class GenerationForegroundService {
  static const int _serviceId = 4711;
  static bool _initialized = false;

  static void _ensureInit() {
    if (_initialized) return;
    _initialized = true;
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'result_generation',
        channelName: 'Result generation',
        channelDescription:
            'Keeps generating your reading while the app is in the background.',
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
      ),
    );
  }

  /// Keep the app alive during a live reading: the connected BLE device is
  /// transferring sensor data AND the result is uploaded over the network.
  static Future<void> startForReading() async {
    try {
      _ensureInit();
      if (await FlutterForegroundTask.isRunningService) return;
      await FlutterForegroundTask.startService(
        serviceTypes: const [
          ForegroundServiceTypes.connectedDevice,
          ForegroundServiceTypes.dataSync,
        ],
        serviceId: _serviceId,
        notificationTitle: 'Generating your result',
        notificationText: 'Please keep the app open until your result is ready.',
        callback: generationForegroundCallback,
      );
    } catch (_) {
      // Never let foreground-service issues break the reading flow itself.
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
