import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class ClinicalBluetoothManager {
  static final ClinicalBluetoothManager _instance =
  ClinicalBluetoothManager._internal();
  factory ClinicalBluetoothManager() => _instance;
  ClinicalBluetoothManager._internal();

  /// Devices are matched on this prefix, case-insensitively, rather than on one
  /// exact name. Units in the field do not all advertise the same string —
  /// "RESPYR_01" and "Respyr_M69" are both Respyr hardware — and an exact
  /// comparison silently failed to find anything but the one hardcoded name.
  final String targetDeviceNamePrefix = 'respyr';

  bool _isRespyrDevice(String name) =>
      name.toLowerCase().startsWith(targetDeviceNamePrefix);

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

  // Guards against concurrent service discovery. Without this, connect()'s
  // discovery (:318) and sendData()'s recovery discovery (:152) can overlap,
  // each attaching a notify listener and leaking the first one -> every packet
  // is delivered twice (which corrupts the server payload).
  Future<void>? _discoverInFlight;
  bool _enablingNotify = false;

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

    await _stopScanInternal();
    await disconnect(force: true);

    try {
      final state = await FlutterBluePlus.adapterState.first;
      if (state != BluetoothAdapterState.on) {
        debugPrint("❌ Bluetooth is not ON: $state");
        _connectionStatusController.add(false);
        return;
      }

      debugPrint("🔍 Starting scan...");

      // Start scan
      await FlutterBluePlus.startScan(
        timeout: scanTimeout,
        androidScanMode: AndroidScanMode.lowLatency,
      );

      // Hard timeout safety
      _scanHardTimeoutTimer = Timer(hardTimeout, () async {
        if (_isScanning) {
          debugPrint("⏰ Scan hard-timeout. Resetting.");
          _shouldStopAllProcesses = true;
          await _stopScanInternal();
          reset();
          _connectionStatusController.add(false);
        }
      });

      final completer = Completer<ScanResult?>();

      _scanSub = FlutterBluePlus.scanResults.listen((results) {
        if (_shouldStopAllProcesses || completer.isCompleted) return;

        ScanResult? best;

        for (final r in results) {
          final adv = r.device.advName.trim();
          final platform = r.device.platformName.trim();
          final id = r.device.remoteId.str;

          if (id.isEmpty) continue;

          // debugPrint, not kDebugMode/print: profile builds strip the latter,
          // which left the whole scan invisible when it found nothing.
          debugPrint(
            "🔍 Found: adv='$adv' platform='$platform' id=$id rssi=${r.rssi}",
          );

          final matchesName =
              (adv.isNotEmpty && _isRespyrDevice(adv)) ||
                  (platform.isNotEmpty && _isRespyrDevice(platform));

          // Several units can be in range in a clinic, so take the strongest
          // signal rather than whichever happened to be seen first.
          if (matchesName && (best == null || r.rssi > best.rssi)) {
            best = r;
          }
        }

        final ScanResult? target = best;
        if (target != null) {
          debugPrint(
            "🎯 Target device: '${target.device.advName}' rssi=${target.rssi}",
          );
          completer.complete(target);
        }
      });

      // Guarantee scan completion (never hang)
      final found = await Future.any<ScanResult?>([
        completer.future,
        Future.delayed(scanTimeout + const Duration(seconds: 1), () => null),
      ]);

      await _stopScanInternal();

      if (found == null) {
        debugPrint("❌ Target not found in scan window.");
        _connectionStatusController.add(false);
        return;
      }

      await _connectWithRetries(found.device, retries: connectRetries);
    } catch (e) {
      debugPrint("Scan/connect error: $e");
      _connectionStatusController.add(false);
    } finally {
      await _stopScanInternal();
      _isScanning = false;
    }
  }

  Future<void> sendData(String data) async {
    if (_targetDevice == null) {
      debugPrint("❌ No target device.");
      return;
    }
    if (!_isConnected) {
      debugPrint("❌ Device not connected.");
      return;
    }
    if (_shouldStopAllProcesses) {
      debugPrint("❌ Stopped due to abort flag.");
      return;
    }

    if (!_isReadyForWrite || _writeCharacteristic == null) {
      debugPrint("❌ Not ready to write. Attempting recovery...");
      await _discoverServices();

      if (!_isReadyForWrite || _writeCharacteristic == null) {
        debugPrint("❌ Write characteristic still not available.");
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
        debugPrint("❌ Characteristic does not support writing.");
        return;
      }

      debugPrint("✅ Sent: $data");
    } catch (e) {
      debugPrint("❌ Send error: $e");
    }
  }

  Future<void> disconnect({bool force = false}) async {
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

      await device.disconnect();
    } catch (e) {
      debugPrint("Disconnect error: $e");
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

        debugPrint("🔌 Connect attempt $attempt/$retries...");

        final ok = await _connectToDeviceOnce(device);
        if (ok) return;

        await Future.delayed(Duration(milliseconds: 300 * attempt));
      }

      debugPrint("❌ All connect retries failed.");
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
      await _targetDevice!
          .connect(autoConnect: false, timeout: const Duration(seconds: 12));

      await Future.delayed(const Duration(milliseconds: 300));

      if (!kIsWeb && Platform.isAndroid) {
        // MTU helps CCCD/write stability on many Android phones
        try {
          await _targetDevice!.requestMtu(247);
          await Future.delayed(const Duration(milliseconds: 150));
        } catch (e) {
          debugPrint("MTU request failed (ok): $e");
        }

        // Optional: some devices require bonding for notifications
        // If your device is not bonded, uncomment below.
        /*
        try {
          final bondState = await _targetDevice!.bondState.first;
          if (bondState == BluetoothBondState.none) {
            debugPrint("🔐 Creating bond...");
            await _targetDevice!.createBond();
            await Future.delayed(const Duration(milliseconds: 500));
          }
        } catch (e) {
          debugPrint("Bond attempt failed (maybe not required): $e");
        }
        */
      }

      _isConnected = true;
      _connectionStatusController.add(true);

      await _connectionSubscription?.cancel();
      _connectionSubscription =
          _targetDevice!.connectionState.listen((state) async {
            if (state == BluetoothConnectionState.disconnected) {
              debugPrint("🔌 Disconnected!");
              _connectionStatusController.add(false);
              _handleDisconnection();
            } else if (state == BluetoothConnectionState.connected) {
              debugPrint("✅ Connected (state stream).");
              _isConnected = true;
              _connectionStatusController.add(true);
            }
          });

      await _discoverServices();
      return _isReadyForWrite;
    } catch (e) {
      debugPrint("Connection error: $e");
      await disconnect(force: true);
      return false;
    }
  }

  Future<void> _discoverServices() async {
    // Single-flight: if a discovery is already running, await it instead of
    // starting a second concurrent one (which would double the notify listener).
    final inFlight = _discoverInFlight;
    if (inFlight != null) {
      await inFlight;
      return;
    }
    final future = _discoverServicesImpl();
    _discoverInFlight = future;
    try {
      await future;
    } finally {
      _discoverInFlight = null;
    }
  }

  Future<void> _discoverServicesImpl() async {
    _isReadyForWrite = false;

    final device = _targetDevice;
    if (device == null || _shouldStopAllProcesses) return;

    try {
      debugPrint("🔎 Discovering services...");

      final services = await device.discoverServices();

      BluetoothCharacteristic? bestNotify;
      BluetoothCharacteristic? bestWrite;

      // 1) First pass: pick notify+write from SAME service (best for UART style)
      for (final service in services) {
        BluetoothCharacteristic? localNotify;
        BluetoothCharacteristic? localWrite;

        for (final char in service.characteristics) {
          // debugPrint so the GATT table is visible in profile builds — it is
          // the evidence needed when a device answers the handshake with
          // something the protocol doesn't define.
          debugPrint("GATT ${service.uuid} -> ${char.uuid} "
              "notify=${char.properties.notify} "
              "indicate=${char.properties.indicate} "
              "write=${char.properties.write} "
              "wwr=${char.properties.writeWithoutResponse}");

          if (localNotify == null &&
              (char.properties.notify || char.properties.indicate)) {
            localNotify = char;
          }

          if (localWrite == null) {
            if (char.properties.write) {
              localWrite = char;
            } else if (char.properties.writeWithoutResponse) {
              localWrite = char;
            }
          }
        }

        if (localNotify != null && localWrite != null) {
          bestNotify = localNotify;
          bestWrite = localWrite;
          break;
        }
      }

      // 2) Fallback: any notify + any write
      if (bestNotify == null || bestWrite == null) {
        for (final service in services) {
          for (final char in service.characteristics) {
            if (bestNotify == null &&
                (char.properties.notify || char.properties.indicate)) {
              bestNotify = char;
            }
            if (bestWrite == null) {
              if (char.properties.write) {
                bestWrite = char;
              } else if (char.properties.writeWithoutResponse) {
                bestWrite = char;
              }
            }
          }
        }
      }

      _notifyCharacteristic = bestNotify;
      _writeCharacteristic = bestWrite;

      if (_notifyCharacteristic == null) {
        debugPrint("❌ No notify/indicate characteristic found.");
      } else {
        await _enableNotify(_notifyCharacteristic!);
      }

      if (_writeCharacteristic == null) {
        _isReadyForWrite = false;
        debugPrint("❌ No valid write characteristic found.");
      } else {
        _isReadyForWrite = true;
        debugPrint("✅ Write ready: ${_writeCharacteristic!.uuid}");
      }
    } catch (e) {
      debugPrint("Service discovery error: $e");
      _isReadyForWrite = false;
    }
  }

  Future<void> _enableNotify(BluetoothCharacteristic c) async {
    // Re-entrancy guard: never run two enable-notify sequences at once, or the
    // first listener can leak and every packet gets delivered twice.
    if (_enablingNotify) return;
    _enablingNotify = true;

    // Clean old sub
    await _notificationSubscription?.cancel();
    _notificationSubscription = null;

    try {
      // Some stacks behave better if we disable then enable
      try {
        await c.setNotifyValue(false);
        await Future.delayed(const Duration(milliseconds: 120));
      } catch (_) {}

      await c.setNotifyValue(true);
      await Future.delayed(const Duration(milliseconds: 200));

      // Extra safety: write CCCD 0x2902 explicitly (helps some Android devices)
      try {
        for (final d in c.descriptors) {
          // CCCD = 00002902-0000-1000-8000-00805f9b34fb
          if (d.uuid.toString().toLowerCase().contains("2902")) {
            final isIndicate = c.properties.indicate && !c.properties.notify;
            final value = isIndicate ? [0x02, 0x00] : [0x01, 0x00];
            await d.write(value);
            break;
          }
        }
      } catch (e) {
        debugPrint("CCCD write failed (maybe ok): $e");
      }

      debugPrint("✅ Notify enabled: ${c.uuid}");

      _notificationSubscription = c.onValueReceived.listen((value) {
        if (value.isEmpty) return;

        final received = String.fromCharCodes(value);
        // Log raw bytes too: a one-character reply like "i" is ambiguous
        // between a real response and a truncated frame, and only the bytes
        // tell them apart.
        debugPrint("📨 Received: $received  bytes=$value");
        _receivedDataController.add(received);

        if (received.trim() == '120') {
          if (kDebugMode) {
            print("⚠️ Received 120 – ignoring disconnect trigger here");
          }
        }
      });
    } catch (e) {
      debugPrint("❌ Enable notify failed: $e");
    } finally {
      _enablingNotify = false;
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

    debugPrint("🔄 BLE reset");
  }
}
