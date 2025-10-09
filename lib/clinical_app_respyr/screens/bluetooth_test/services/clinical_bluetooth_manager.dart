import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class ClinicalBluetoothManager {
  static final ClinicalBluetoothManager _instance =
      ClinicalBluetoothManager._internal();
  factory ClinicalBluetoothManager() => _instance;
  ClinicalBluetoothManager._internal();

  final String targetDeviceName = 'HUMORS_08';
  BluetoothDevice? _targetDevice;
  BluetoothCharacteristic? _notifyCharacteristic;
  BluetoothCharacteristic? _writeCharacteristic;

  bool _isConnected = false;
  bool _isScanning = false;
  bool _shouldStopAllProcesses = false;
  bool _isReadyForWrite = false; // ✅ NEW FLAG

  final StreamController<bool> _connectionStatusController =
      StreamController<bool>.broadcast();
  final StreamController<String> _receivedDataController =
      StreamController<String>.broadcast();

  StreamSubscription<BluetoothConnectionState>? _connectionSubscription;
  StreamSubscription<List<int>>? _notificationSubscription;

  bool get isConnected => _isConnected;
  Stream<bool> get connectionStatusStream => _connectionStatusController.stream;
  Stream<String> get receivedDataStream => _receivedDataController.stream;

  Future<void> scanAndConnect() async {
    if (_isScanning || _isConnected) return;

    _isScanning = true;
    await disconnect();
    FlutterBluePlus.stopScan();

    Timer? timeoutTimer;

    try {
      FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));

      timeoutTimer = Timer(const Duration(seconds: 45), () {
        if (_isScanning) {
          if (kDebugMode) print("⏰ Scan timeout. Resetting.");
          _shouldStopAllProcesses = true;
          FlutterBluePlus.stopScan();
          reset();
          _connectionStatusController.add(false);
        }
      });

      await for (var results in FlutterBluePlus.scanResults) {
        if (_shouldStopAllProcesses) break;

        for (var result in results) {
          final name = result.device.advName;
          final id = result.device.remoteId.str;

          if (id.isEmpty) continue;

          if (kDebugMode) print("Found: $name - $id");

          if (name == targetDeviceName) {
            if (kDebugMode) print("🎯 Target device found!");
            FlutterBluePlus.stopScan();
            timeoutTimer.cancel();
            await connectToDevice(result.device);
            return;
          }
        }
      }
    } catch (e) {
      if (kDebugMode) print("Scan error: $e");
    } finally {
      FlutterBluePlus.stopScan();
      timeoutTimer?.cancel();
      _isScanning = false;
    }
  }

  Future<void> connectToDevice(BluetoothDevice device) async {
    _shouldStopAllProcesses = false;
    _isReadyForWrite = false;

    if (_isConnected && _targetDevice?.remoteId == device.remoteId) return;

    await disconnect();
    _targetDevice = device;

    try {
      await _targetDevice!.connect(autoConnect: false);
      _isConnected = true;
      _connectionStatusController.add(true);

      _connectionSubscription?.cancel();
      _connectionSubscription =
          _targetDevice!.connectionState.listen((state) async {
        if (state == BluetoothConnectionState.disconnected) {
          if (!_isConnected) return;
          if (kDebugMode) print("🔌 Disconnected!");
          _isConnected = false;
          _connectionStatusController.add(false);
          _handleDisconnection();
        } else if (state == BluetoothConnectionState.connected) {
          if (kDebugMode) print("✅ Connected. Discovering services...");
          _isConnected = true;
          _connectionStatusController.add(true);
          await _discoverServices(); // ✅ ensure ready after reconnect
        }
      });

      await _discoverServices();
    } catch (e) {
      if (kDebugMode) print("Connection error: $e");
      _handleDisconnection();
    }
  }

  Future<void> _discoverServices() async {
    _isReadyForWrite = false;
    if (_targetDevice == null || _shouldStopAllProcesses) return;

    try {
      List<BluetoothService> services = await _targetDevice!.discoverServices();

      BluetoothCharacteristic? notifyChar;
      BluetoothCharacteristic? writeChar;

      for (var service in services) {
        for (var char in service.characteristics) {
          if (kDebugMode) print("Characteristic: ${char.uuid}");

          if (char.properties.notify && notifyChar == null) {
            notifyChar = char;
          }

          if ((char.properties.write || char.properties.writeWithoutResponse) &&
              writeChar == null) {
            writeChar = char;
          }
        }
      }

      if (notifyChar != null) {
        _notifyCharacteristic = notifyChar;
        bool notifySuccess = await _notifyCharacteristic!.setNotifyValue(true);
        if (kDebugMode) print("Notify subscription status: $notifySuccess");

        _notificationSubscription?.cancel();
        _notificationSubscription =
            _notifyCharacteristic!.onValueReceived.listen((value) {
          if (value.isNotEmpty) {
            final received = String.fromCharCodes(value);
            if (kDebugMode) print("📨 Received: $received");

            _receivedDataController.add(received);

            if (received.trim() == '120') {
              if (kDebugMode) {
                print("⚠️ Received 120 – ignoring disconnect trigger here");
              }
              // Do not disconnect prematurely
              //_shouldStopAllProcesses = true;
              //disconnect();
            }
          }
        });
      }

      if (writeChar != null) {
        _writeCharacteristic = writeChar;
        _isReadyForWrite = true; // ✅ Mark ready
        if (kDebugMode) {
          print("✅ Write characteristic ready: ${_writeCharacteristic!.uuid}");
        }
      } else {
        if (kDebugMode) print("❌ No valid write characteristic found.");
      }
    } catch (e) {
      if (kDebugMode) print("Service discovery error: $e");
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
      final dataToSend = data.codeUnits;

      if (_writeCharacteristic!.properties.write) {
        await _writeCharacteristic!.write(dataToSend, withoutResponse: false);
      } else if (_writeCharacteristic!.properties.writeWithoutResponse) {
        await _writeCharacteristic!.write(dataToSend, withoutResponse: true);
      } else {
        if (kDebugMode) print("❌ Characteristic does not support writing.");
        return;
      }

      if (kDebugMode) print("✅ Sent data: $data");
    } catch (e) {
      if (kDebugMode) print("❌ Send error: $e");
    }
  }

  Future<void> disconnect() async {
    if (_targetDevice == null || !_isConnected) {
      if (kDebugMode) print("Already disconnected");
      return;
    }

    try {
      await _targetDevice!.disconnect();
      _isConnected = false;
      _connectionStatusController.add(false);
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
  }

  void _handleDisconnection() {
    _isConnected = false;
    _targetDevice = null;
    _notifyCharacteristic = null;
    _writeCharacteristic = null;
    _isReadyForWrite = false;
    _notificationSubscription?.cancel();
    _notificationSubscription = null;
    _connectionStatusController.add(false);
    _shouldStopAllProcesses = false;

    if (kDebugMode) print("🔄 BLE reset");
  }

  void dispose() {
    _connectionStatusController.close();
    _receivedDataController.close();
    _notificationSubscription?.cancel();
  }
}
