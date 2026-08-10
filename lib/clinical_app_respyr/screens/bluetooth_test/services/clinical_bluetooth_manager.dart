import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class ClinicalBluetoothManager {
  static final ClinicalBluetoothManager _instance =
  ClinicalBluetoothManager._internal();
  factory ClinicalBluetoothManager() => _instance;
  ClinicalBluetoothManager._internal();

  /// Clinical units all advertise this exact name, whatever their individual
  /// GAP name is — RESPYR_M003l/q/r all appear as "RESPYR_01" in the
  /// advertisement. Matching the advertised name is therefore how the right
  /// hardware is identified.
  ///
  /// Do NOT loosen this to a "Respyr" prefix. Other Respyr-branded devices
  /// exist that expose a completely different BLE profile — Respyr_M69 serves
  /// 5833ff01/ff02/ff03 instead of the ffe1 serial characteristic, and answers
  /// every command with "i" — and a prefix match happily connects to one of
  /// those if it happens to be closer.
  final String targetDeviceName = 'RESPYR_01';

  /// The canonical advertised name. A unit using it is always preferred.
  bool _isPreferredDevice(String name) =>
      _normalizeName(name) == targetDeviceName;

  /// Any Respyr-branded unit. Used only as a fallback, because other Respyr
  /// hardware exists that does not serve the clinical protocol.
  bool _isRespyrDevice(String name) =>
      _normalizeName(name).toLowerCase().startsWith('respyr');

  /// Strips control characters before comparing. This firmware NUL-pads its
  /// strings, so an advertised name can arrive as "RESPYR_01\x00\x00\x00" —
  /// visually identical, but never equal, since trim() removes whitespace and
  /// not NUL.
  String _normalizeName(String name) =>
      name.replaceAll(RegExp(r'[\x00-\x1f\x7f]'), '').trim();

  /// Renders a device name so control characters survive the log. A name
  /// carrying an embedded NUL truncates the whole logcat line at that byte,
  /// which hid both the rest of the scan record and the fact that the name is
  /// not the clean string it appears to be. Dart's trim() drops whitespace but
  /// NOT NUL, so such a name also silently fails an equality comparison.
  String _describeName(String name) {
    final bool printable =
        name.codeUnits.every((c) => c >= 0x20 && c < 0x7f);
    if (printable) return name;

    final escaped = name.codeUnits
        .map((c) => c >= 0x20 && c < 0x7f
            ? String.fromCharCode(c)
            : "\\x${c.toRadixString(16).padLeft(2, '0')}")
        .join();
    return escaped;
  }

  /// Ask for a larger MTU so a whole line fits in one notification. At the
  /// default 23-byte MTU the payload is capped at 20 bytes, and the device's
  /// lines get split across packets — a "blownow" arrived as a bare "w" once,
  /// which stalls the test since the screen never sees the message.
  static bool requestLargerMtu = true;

  /// The write characteristic declares write-with-response, which is what the
  /// device gets. Left as a switch because it was useful while diagnosing.
  static bool forceWriteWithoutResponse = false;

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

  /// Incoming bytes awaiting a line terminator — see [_onNotification].
  final List<int> _rxBuffer = <int>[];
  Timer? _rxFlushTimer;

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

      // A unit advertising RESPYR_01 wins outright and ends the scan. Other
      // Respyr units are equally valid hardware, so they only wait out a short
      // grace period — long enough for a RESPYR_01 to appear and take
      // precedence, rather than the whole scan window. Waiting for the window
      // to close cost ten seconds on every connection to a pb unit, against
      // roughly two seconds for the connection and handshake themselves.
      ScanResult? fallback;
      Timer? fallbackGrace;
      const Duration fallbackGracePeriod = Duration(milliseconds: 1500);

      /// Device ids already logged during this scan — see the listener below.
      final Set<String> logged = <String>{};

      _scanSub = FlutterBluePlus.scanResults.listen((results) {
        if (_shouldStopAllProcesses || completer.isCompleted) return;

        ScanResult? preferred;

        for (final r in results) {
          final adv = r.device.advName.trim();
          final platform = r.device.platformName.trim();
          final id = r.device.remoteId.str;

          if (id.isEmpty) continue;

          // debugPrint, not kDebugMode/print: profile builds strip the latter,
          // which left the whole scan invisible when it found nothing.
          //
          // Log each device once per scan. scanResults re-emits the cumulative
          // list on every batch, so logging unconditionally repeated every
          // device several times over; and unnamed devices, of which a busy
          // room has dozens, can never match anything.
          if ((adv.isNotEmpty || platform.isNotEmpty) && logged.add(id)) {
            debugPrint(
              "🔍 Found: $id rssi=${r.rssi} "
              "'${_describeName(adv.isNotEmpty ? adv : platform)}'",
            );
          }

          // Strongest signal wins within a tier — a clinic can have several
          // units in range.
          if (_isPreferredDevice(adv) || _isPreferredDevice(platform)) {
            if (preferred == null || r.rssi > preferred.rssi) preferred = r;
          } else if (_isRespyrDevice(adv) || _isRespyrDevice(platform)) {
            if (fallback == null || r.rssi > fallback!.rssi) fallback = r;
          }
        }

        final ScanResult? target = preferred;
        if (target != null) {
          debugPrint(
            "🎯 Target: rssi=${target.rssi} "
            "adv=[${_describeName(target.device.advName)}]",
          );
          fallbackGrace?.cancel();
          completer.complete(target);
          return;
        }

        // Seen a Respyr unit that isn't the preferred name: give a RESPYR_01
        // a brief chance to appear, then take this one.
        if (fallback != null && fallbackGrace == null) {
          fallbackGrace = Timer(fallbackGracePeriod, () {
            final ScanResult? candidate = fallback;
            if (completer.isCompleted || candidate == null) return;
            debugPrint(
              "🎯 Target (no $targetDeviceName nearby): rssi=${candidate.rssi} "
              "adv=[${_describeName(candidate.device.advName)}]",
            );
            completer.complete(candidate);
          });
        }
      });

      // Guarantee scan completion (never hang)
      ScanResult? found = await Future.any<ScanResult?>([
        completer.future,
        Future.delayed(scanTimeout + const Duration(seconds: 1), () => null),
      ]);

      fallbackGrace?.cancel();
      await _stopScanInternal();

      found ??= fallback;

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
      // Normal race, not a failure: the screen can send its first command
      // before discovery has finished. The single-flight guard means this
      // awaits the discovery already running rather than starting a second.
      debugPrint("⏳ Write not ready yet — waiting for service discovery.");
      await _discoverServices();

      if (!_isReadyForWrite || _writeCharacteristic == null) {
        debugPrint("❌ Write characteristic still not available.");
        return;
      }
    }

    try {
      final bytes = data.codeUnits;

      // EXPERIMENT: the pb unit's write characteristic declares write=true and
      // wwr=false, so this has only ever written with response. That
      // declaration is advisory — devices commonly accept write-without-
      // response regardless, and terminal apps use it for several module
      // types. It is the last untested degree of freedom in the write path.
      if (forceWriteWithoutResponse) {
        debugPrint("🧪 Writing WITHOUT response: $bytes");
        await _writeCharacteristic!.write(bytes, withoutResponse: true);
      } else if (_writeCharacteristic!.properties.write) {
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

  /// Reassembles notifications into whole lines before publishing them.
  ///
  /// A notification is a transport packet, not a message. The device frames its
  /// output with CRLF and a line can straddle two packets, so treating each
  /// packet as a complete message loses data: a "blownow" once arrived as a
  /// bare "w" after "/909.77/" turned up with no terminator, and the test hung
  /// because no screen ever saw the message it was waiting for.
  ///
  /// Buffer instead, emit on each terminator, and keep any partial line for the
  /// next packet.
  void _onNotification(List<int> value) {
    if (value.isEmpty) return;

    _rxBuffer.addAll(value);
    _rxFlushTimer?.cancel();

    const int lf = 0x0a;
    int idx;
    while ((idx = _rxBuffer.indexOf(lf)) != -1) {
      final List<int> line = _rxBuffer.sublist(0, idx);
      _rxBuffer.removeRange(0, idx + 1);
      _emitLine(line);
    }

    // Not every message is guaranteed to be terminated, so never hold a partial
    // line indefinitely — publish it if nothing follows shortly.
    if (_rxBuffer.isNotEmpty) {
      _rxFlushTimer = Timer(const Duration(milliseconds: 250), () {
        if (_rxBuffer.isEmpty) return;
        final List<int> line = List<int>.from(_rxBuffer);
        _rxBuffer.clear();
        _emitLine(line);
      });
    }
  }

  void _emitLine(List<int> bytes) {
    final String line = String.fromCharCodes(bytes).replaceAll('\r', '').trim();
    if (line.isEmpty) return;

    debugPrint("📨 Received: $line");
    _receivedDataController.add(line);
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
        // MTU helps CCCD/write stability on many Android phones.
        //
        // EXPERIMENT: see [requestLargerMtu].
        if (requestLargerMtu) {
          try {
            await _targetDevice!.requestMtu(247);
            await Future.delayed(const Duration(milliseconds: 150));
          } catch (e) {
            debugPrint("MTU request failed (ok): $e");
          }
        } else {
          debugPrint("🧪 Skipping MTU request (default MTU retained)");
        }

        // Deliberately no bonding. These devices refuse to pair — createBond
        // fails and Android shows the user a "pairing declined by device"
        // error — and they serve their characteristics without it.
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

      // Android caches a device's GATT table and keeps serving the cached copy
      // after the device's firmware changes its services. That is very likely
      // what is happening with the pb units: they appear to serve 5833ff01,
      // which no serial terminal app supports — Serial Bluetooth Terminal
      // matches only ffe0/ffe1, Nordic, Microchip and Telit, and refuses to
      // connect otherwise — yet it talks to these devices successfully. So the
      // table we are being shown is probably stale. Drop it and re-read.
      if (!kIsWeb && Platform.isAndroid) {
        try {
          await device.clearGattCache();
          debugPrint("🧹 Cleared cached GATT table");
          await Future.delayed(const Duration(milliseconds: 300));
        } catch (e) {
          debugPrint("🧹 clearGattCache failed (may be unsupported): $e");
        }
      }

      final services = await device.discoverServices();


      BluetoothCharacteristic? bestNotify;
      BluetoothCharacteristic? bestWrite;

      // 0) Known serial characteristics first, by UUID, across all services.
      //
      // nRF Connect shows the pb unit serving a Nordic UART service whose write
      // characteristic is Nordic (6e400003) while its notify characteristic is
      // a Microchip UUID (49535343-1e4d). The two halves live under different
      // UUID families, so anything that insists on finding both inside one
      // service misses it — which is how this app ended up on 5833ff02/ff03
      // instead, the only self-consistent pair on offer, and the one the device
      // answers with a placeholder byte.
      //
      // So rank characteristics directly and let the pair span services.
      // 5833 is excluded here and left to the fallback below: it looks like a
      // serial pipe but does not behave as one.
      const List<String> writePriority = [
        '49535343-8841', // Microchip write
        '6e400002', // Nordic RX (phone -> device)
        '6e400003', // Nordic TX, writable on this hybrid module
        'ffe1', // legacy single-characteristic module
      ];
      const List<String> notifyPriority = [
        '49535343-1e4d', // Microchip read/notify
        '6e400003', // Nordic TX (device -> phone)
        '6e400002',
        'ffe1',
      ];

      BluetoothCharacteristic? pickByPriority(
        List<String> priority,
        bool Function(BluetoothCharacteristic) usable,
      ) {
        for (final wanted in priority) {
          for (final service in services) {
            if ("${service.uuid}".toLowerCase().contains('5833')) continue;
            for (final char in service.characteristics) {
              if (!"${char.uuid}".toLowerCase().contains(wanted)) continue;
              if (usable(char)) return char;
            }
          }
        }
        return null;
      }

      bestWrite = pickByPriority(
        writePriority,
        (c) => c.properties.write || c.properties.writeWithoutResponse,
      );
      // Require a CCCD: a notify characteristic without one cannot actually be
      // subscribed to, and trying stalls the connection.
      bestNotify = pickByPriority(
        notifyPriority,
        (c) =>
            (c.properties.notify || c.properties.indicate) &&
            c.descriptors.any(
              (d) => "${d.uuid}".toLowerCase().contains('2902'),
            ),
      );

      if (bestWrite != null && bestNotify != null) {
        debugPrint(
          "✅ Matched serial profile: write=${bestWrite.uuid} "
          "notify=${bestNotify.uuid}",
        );
      } else {
        bestWrite = null;
        bestNotify = null;
      }

      // 1) First pass: pick notify+write from SAME service (best for UART style)
      for (final service in services) {
        if (bestNotify != null && bestWrite != null) break;
        BluetoothCharacteristic? localNotify;
        BluetoothCharacteristic? localWrite;

        for (final char in service.characteristics) {
          // debugPrint so the GATT table is visible in profile builds — it is
          // the evidence needed when a device answers the handshake with
          // something the protocol doesn't define.
          debugPrint("GATT ${service.uuid} -> ${char.uuid} "
              "read=${char.properties.read} "
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
      // Subscribe once, the way a BLE terminal app does.
      //
      // This used to disable notifications, re-enable them, and then write the
      // CCCD descriptor by hand on top — three descriptor writes where the
      // protocol calls for one. A terminal app talking to the same device over
      // the same characteristic gets proper replies, so the extra writes are
      // the difference worth removing: a module whose stream state is disturbed
      // by a redundant disable/re-enable answers every command with the same
      // status byte afterwards.
      //
      // setNotifyValue(true) writes the CCCD itself, so nothing is lost.
      await c.setNotifyValue(true);
      await Future.delayed(const Duration(milliseconds: 200));

      debugPrint("✅ Notify enabled: ${c.uuid}");

      _rxBuffer.clear();
      _notificationSubscription = c.onValueReceived.listen(_onNotification);
    } catch (e) {
      debugPrint("❌ Enable notify failed: $e");
    } finally {
      _enablingNotify = false;
    }
  }

  void _handleDisconnection() {
    _isConnected = false;
    _isReadyForWrite = false;

    // Drop any half-received line so it cannot be spliced onto the first packet
    // of the next connection.
    _rxFlushTimer?.cancel();
    _rxFlushTimer = null;
    _rxBuffer.clear();

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
