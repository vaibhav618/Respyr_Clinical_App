import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class ClinicalBluetoothManager {
  static final ClinicalBluetoothManager _instance =
  ClinicalBluetoothManager._internal();
  factory ClinicalBluetoothManager() => _instance;
  ClinicalBluetoothManager._internal();

  final String targetDeviceName = 'RESPYR_01';

  BluetoothDevice? _targetDevice;
  BluetoothCharacteristic? _notifyCharacteristic;
  BluetoothCharacteristic? _writeCharacteristic;

  bool _isConnected = false;
  bool _isScanning = false;
  bool _shouldStopAllProcesses = false;
  bool _isReadyForWrite = false;
  bool _isConnecting = false;

  StreamSubscription<List<ScanResult>>? _scanSub;
  Timer? _scanHardTimeoutTimer;

  final StreamController<bool> _connectionStatusController =
  StreamController<bool>.broadcast();
  final StreamController<String> _receivedDataController =
  StreamController<String>.broadcast();

  StreamSubscription<BluetoothConnectionState>? _connectionSubscription;
  StreamSubscription<List<int>>? _notificationSubscription;

  bool get isConnected => _isConnected;
  Stream<bool> get connectionStatusStream => _connectionStatusController.stream;
  Stream<String> get receivedDataStream => _receivedDataController.stream;

  // ---------------------------
  // Public API
  // ---------------------------

  Future<void> scanAndConnect({
    Duration scanTimeout = const Duration(seconds: 8),
    Duration hardTimeout = const Duration(seconds: 45),
    int connectRetries = 3,
  }) async {
    if (_isScanning || _isConnecting) return;
    if (_isConnected) return;

    _isScanning = true;
    _shouldStopAllProcesses = false;

    // Always cleanup previous scan subscriptions/timers
    await _stopScanInternal();

    // Optional: if previous device exists, force full cleanup
    // (Do NOT call disconnect if already null; do not spam)
    await disconnect(force: true);

    try {
      // Ensure Bluetooth is ON
      final state = await FlutterBluePlus.adapterState.first;
      if (state != BluetoothAdapterState.on) {
        if (kDebugMode) {
          print("❌ Bluetooth is not ON: $state");
        }
        _connectionStatusController.add(false);
        return;
      }

      if (kDebugMode) print("🔍 Starting scan...");

      // Start scan
      await FlutterBluePlus.startScan(
        timeout: scanTimeout,
        // These help on Android
        androidScanMode: AndroidScanMode.lowLatency,
      );

      // Hard timeout (your old behavior, but implemented safely)
      _scanHardTimeoutTimer = Timer(hardTimeout, () async {
        if (_isScanning) {
          if (kDebugMode) print("⏰ Scan hard-timeout. Resetting.");
          _shouldStopAllProcesses = true;
          await _stopScanInternal();
          reset();
          _connectionStatusController.add(false);
        }
      });

      final completer = Completer<ScanResult?>();

      _scanSub = FlutterBluePlus.scanResults.listen((results) {
        if (_shouldStopAllProcesses || completer.isCompleted) return;

        for (final r in results) {
          final adv = r.device.advName.trim();
          final platform = r.device.platformName.trim();
          final id = r.device.remoteId.str;

          if (id.isEmpty) continue;

          if (kDebugMode) {
            print("Found: adv='$adv' platform='$platform' id=$id rssi=${r.rssi}");
          }

          final matchesName =
              (adv.isNotEmpty && adv == targetDeviceName) ||
                  (platform.isNotEmpty && platform == targetDeviceName);

          if (matchesName) {
            if (kDebugMode) print("🎯 Target device found!");
            completer.complete(r);
            break;
          }
        }
      });

      final found = await completer.future;

      // Stop scan once we got something (or timed out)
      await _stopScanInternal();

      if (found == null) {
        if (kDebugMode) print("❌ Target not found in scan window.");
        _connectionStatusController.add(false);
        return;
      }

      await _connectWithRetries(found.device, retries: connectRetries);
    } catch (e) {
      if (kDebugMode) print("Scan/connect error: $e");
      _connectionStatusController.add(false);
    } finally {
      await _stopScanInternal();
      _isScanning = false;
    }
  }

  Future<void> sendData(String data) async {
    if (_targetDevice == null) {
      if (kDebugMode) print("❌ No target device.");
      return;
    }
    if (!_isConnected) {
      if (kDebugMode) print("❌ Device not connected.");
      return;
    }
    if (_shouldStopAllProcesses) {
      if (kDebugMode) print("❌ Stopped due to abort flag.");
      return;
    }

    if (!_isReadyForWrite || _writeCharacteristic == null) {
      if (kDebugMode) print("❌ Not ready to write. Attempting recovery...");
      await _discoverServices();

      if (!_isReadyForWrite || _writeCharacteristic == null) {
        if (kDebugMode) print("❌ Write characteristic still not available.");
        return;
      }
    }

    try {
      final bytes = data.codeUnits;

      if (_writeCharacteristic!.properties.write) {
        await _writeCharacteristic!.write(bytes, withoutResponse: false);
      } else if (_writeCharacteristic!.properties.writeWithoutResponse) {
        await _writeCharacteristic!.write(bytes, withoutResponse: true);
      } else {
        if (kDebugMode) print("❌ Characteristic does not support writing.");
        return;
      }

      if (kDebugMode) print("✅ Sent: $data");
    } catch (e) {
      if (kDebugMode) print("❌ Send error: $e");
    }
  }

  Future<void> disconnect({bool force = false}) async {
    // force=true means: cleanup even if flags think disconnected
    final device = _targetDevice;
    if (device == null) {
      _handleDisconnection();
      return;
    }

    if (!force && !_isConnected) {
      _handleDisconnection();
      return;
    }

    try {
      await _notificationSubscription?.cancel();
      _notificationSubscription = null;

      await _connectionSubscription?.cancel();
      _connectionSubscription = null;

      // Try disconnect safely
      await device.disconnect();
    } catch (e) {
      if (kDebugMode) print("Disconnect error: $e");
    } finally {
      _handleDisconnection();
    }
  }

  void reset() {
    _isConnected = false;
    _isScanning = false;
    _shouldStopAllProcesses = false;
    _isReadyForWrite = false;
    _isConnecting = false;
  }

  void dispose() {
    _stopScanInternal();
    _connectionStatusController.close();
    _receivedDataController.close();
    _notificationSubscription?.cancel();
    _connectionSubscription?.cancel();
  }

  // ---------------------------
  // Internals
  // ---------------------------

  Future<void> _stopScanInternal() async {
    _scanHardTimeoutTimer?.cancel();
    _scanHardTimeoutTimer = null;

    await _scanSub?.cancel();
    _scanSub = null;

    try {
      await FlutterBluePlus.stopScan();
    } catch (_) {}

    _isScanning = false;
  }

  Future<void> _connectWithRetries(BluetoothDevice device,
      {int retries = 3}) async {
    if (_isConnecting) return;
    _isConnecting = true;

    try {
      for (int attempt = 1; attempt <= retries; attempt++) {
        if (_shouldStopAllProcesses) return;

        if (kDebugMode) print("🔌 Connect attempt $attempt/$retries...");

        final ok = await _connectToDeviceOnce(device);
        if (ok) return;

        // Backoff
        await Future.delayed(Duration(milliseconds: 300 * attempt));
      }

      if (kDebugMode) print("❌ All connect retries failed.");
      _connectionStatusController.add(false);
    } finally {
      _isConnecting = false;
    }
  }

  Future<bool> _connectToDeviceOnce(BluetoothDevice device) async {
    _shouldStopAllProcesses = false;
    _isReadyForWrite = false;

    await disconnect(force: true);
    _targetDevice = device;

    try {
      // Connect with timeout
      await _targetDevice!
          .connect(autoConnect: false, timeout: const Duration(seconds: 12));

      // small settle time (very important on some phones)
      await Future.delayed(const Duration(milliseconds: 250));

      // Request MTU on Android to stabilize transfers/CCCD writes
      if (!kIsWeb && Platform.isAndroid) {
        try {
          await _targetDevice!.requestMtu(247);
          await Future.delayed(const Duration(milliseconds: 150));
        } catch (e) {
          if (kDebugMode) print("MTU request failed (ok): $e");
        }
      }

      _isConnected = true;
      _connectionStatusController.add(true);

      await _connectionSubscription?.cancel();
      _connectionSubscription =
          _targetDevice!.connectionState.listen((state) async {
            if (state == BluetoothConnectionState.disconnected) {
              if (kDebugMode) print("🔌 Disconnected!");
              _connectionStatusController.add(false);
              _handleDisconnection();
            } else if (state == BluetoothConnectionState.connected) {
              if (kDebugMode) print("✅ Connected (state stream).");
              _isConnected = true;
              _connectionStatusController.add(true);
            }
          });

      await _discoverServices();
      return _isReadyForWrite; // success when write is ready
    } catch (e) {
      if (kDebugMode) print("Connection error: $e");
      await disconnect(force: true);
      return false;
    }
  }

  Future<void> _discoverServices() async {
    _Reminder: {}
    _isReadyForWrite = false;

    final device = _targetDevice;
    if (device == null || _shouldStopAllProcesses) return;

    try {
      if (kDebugMode) print("🔎 Discovering services...");

      final services = await device.discoverServices();

      BluetoothCharacteristic? notifyChar;
      BluetoothCharacteristic? writeChar;

      for (final service in services) {
        for (final char in service.characteristics) {
          if (kDebugMode) print("Characteristic: ${char.uuid}");

          // Prefer NOTIFY/INDICATE
          if ((char.properties.notify || char.properties.indicate) &&
              notifyChar == null) {
            notifyChar = char;
          }

          // Prefer WRITE (with response), then WRITE WITHOUT RESPONSE
          if (writeChar == null) {
            if (char.properties.write) {
              writeChar = char;
            } else if (char.properties.writeWithoutResponse) {
              writeChar = char;
            }
          }
        }
      }

      // Enable notifications (with settle delay)
      if (notifyChar != null) {
        _notifyCharacteristic = notifyChar;

        await Future.delayed(const Duration(milliseconds: 200));
        try {
          await _notifyCharacteristic!.setNotifyValue(true);
          if (kDebugMode) print("✅ Notify enabled: ${notifyChar.uuid}");
        } catch (e) {
          if (kDebugMode) print("❌ setNotifyValue failed: $e");
        }

        await _notificationSubscription?.cancel();
        _notificationSubscription =
            _notifyCharacteristic!.onValueReceived.listen((value) {
              if (value.isEmpty) return;

              final received = String.fromCharCodes(value);
              if (kDebugMode) print("📨 Received: $received");
              _receivedDataController.add(received);

              // Your special-case handling
              if (received.trim() == '120') {
                if (kDebugMode) {
                  print("⚠️ Received 120 – ignoring disconnect trigger here");
                }
              }
            });
      } else {
        if (kDebugMode) print("❌ No notify characteristic found.");
      }

      if (writeChar != null) {
        _writeCharacteristic = writeChar;
        _isReadyForWrite = true;
        if (kDebugMode) print("✅ Write ready: ${writeChar.uuid}");
      } else {
        _isReadyForWrite = false;
        if (kDebugMode) print("❌ No valid write characteristic found.");
      }
    } catch (e) {
      if (kDebugMode) print("Service discovery error: $e");
      _isReadyForWrite = false;
    }
  }

  void _handleDisconnection() {
    _isConnected = false;
    _isReadyForWrite = false;

    _notifyCharacteristic = null;
    _writeCharacteristic = null;
    _targetDevice = null;

    _notificationSubscription?.cancel();
    _notificationSubscription = null;

    _connectionSubscription?.cancel();
    _connectionSubscription = null;

    _connectionStatusController.add(false);

    _shouldStopAllProcesses = false;

    if (kDebugMode) print("🔄 BLE reset");
  }
}
