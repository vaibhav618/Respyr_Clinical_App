import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:usb_serial/transaction.dart';
import 'package:usb_serial/usb_serial.dart';

class ClinicalUsbCommunicationServices {
  static final ClinicalUsbCommunicationServices _instance =
      ClinicalUsbCommunicationServices._internal();

  factory ClinicalUsbCommunicationServices() => _instance;

  ClinicalUsbCommunicationServices._internal() {
    UsbSerial.usbEventStream?.listen((UsbEvent event) {
      if (event.event == UsbEvent.ACTION_USB_ATTACHED) {
        _autoConnect();
      } else if (event.event == UsbEvent.ACTION_USB_DETACHED) {
        _disconnect();
      }
    });
  }

  UsbPort? _port;
  UsbDevice? device;
  StreamSubscription<String>? _subscription;
  Transaction<String>? _transaction;
  final StreamController<String> _dataController =
      StreamController<String>.broadcast();
  final StreamController<bool> _connectionStatusController =
      StreamController<bool>.broadcast();

  bool _isConnected = false;
  Timer? _watchdogTimer;
  bool _isPaused = false; // New flag to track paused state
  Stream<String> get dataStream => _dataController.stream;
  Stream<bool> get connectionStatusStream => _connectionStatusController.stream;
  bool get isConnected => _isConnected;
  bool get isPaused => _isPaused; // Getter for paused state
  // Listener Callbacks
  void Function(String status)? _onConnectionStatusChanged;
  void Function(String data)? _onDataReceived;
  void Function(String command)? _onCommandSent;
  void Function(String error)? _onError;

  void setUsbSerialListener({
    void Function(String status)? onConnectionStatusChanged,
    void Function(String data)? onDataReceived,
    void Function(String command)? onCommandSent,
    void Function(String error)? onError,
  }) {
    _onConnectionStatusChanged = onConnectionStatusChanged;
    _onDataReceived = onDataReceived;
    _onCommandSent = onCommandSent;
    _onError = onError;
  }

  Future<void> connect() async {
    await _autoConnect();
  }

  void startConnectionWatchdog({
    Duration interval = const Duration(seconds: 2),
  }) {
    _watchdogTimer?.cancel(); // to avoid multiple timers
    _watchdogTimer = Timer.periodic(interval, (_) async {
      if (_isPaused) return;
      List<UsbDevice> currentDevices = await UsbSerial.listDevices();
      if (_isConnected) {
        bool stillConnected = currentDevices.any(
          (d) => d.deviceId == device?.deviceId,
        );
        if (!stillConnected) {
          debugPrint("Watchdog: Device lost, triggering disconnect.");
          _disconnect();
        }
      }
    });
  }

  void pauseCommunication() {
    _isPaused = true;
    // Pause the subscription to stop processing incoming data
    _subscription?.pause();
    debugPrint("USB communication paused");
  }

  void resumeCommunication() {
    _isPaused = false;
    // Resume the subscription to continue processing incoming data
    _subscription?.resume();
    debugPrint("USB communication resumed");
    // Optionally, send a specific command to re-sync or re-initialize communication
    // e.g., sendData("?") to re-query the device state, if needed
  }

  Future<void> _autoConnect() async {
    List<UsbDevice> devices = await UsbSerial.listDevices();
    if (devices.isNotEmpty) {
      await connectToDevice(devices.first);
      startConnectionWatchdog();
    } else {
      _isConnected = false;
      _onConnectionStatusChanged?.call("disconnected");
      _connectionStatusController.add(false);
    }
  }

  Future<bool> connectToDevice(UsbDevice? usbDevice) async {
    await Future.microtask(() => _disconnect());

    if (usbDevice == null) {
      _isConnected = false;
      _onConnectionStatusChanged?.call("disconnected");
      _connectionStatusController.add(false);
      return false;
    }

    try {
      _port = await usbDevice.create();
      if (_port == null || !await _port!.open()) {
        _onError?.call("Failed to open USB port");
        _connectionStatusController.add(false);
        return false;
      }

      device = usbDevice;

      await _port!.setDTR(true);
      await _port!.setRTS(true);
      await _port!.setPortParameters(
        115200,
        UsbPort.DATABITS_8,
        UsbPort.STOPBITS_1,
        UsbPort.PARITY_NONE,
      );

      _isConnected = true;
      _onConnectionStatusChanged?.call("connected");
      _connectionStatusController.add(true);
      startConnectionWatchdog();
      _transaction = Transaction.stringTerminated(
        _port!.inputStream as Stream<Uint8List>,
        Uint8List.fromList([13, 10]), // \r\n
      );

      _subscription = _transaction!.stream.listen(
        (String line) {
          _dataController.add(line);
          _onDataReceived?.call(line);
        },
        onError: (error) {
          _onError?.call("Read error: $error");
        },
      );

      return true;
    } catch (e) {
      _onError?.call("Connection error: $e");
      _isConnected = false;
      _connectionStatusController.add(false);
      return false;
    }
  }

  Future<void> sendData(String data) async {
    if (_isPaused) {
      debugPrint("Cannot send data: USB communication is paused");
      return;
    }
    try {
      if (_port != null) {
        await _port!.write(Uint8List.fromList(("$data\r\n").codeUnits));
        debugPrint("Command send : =>$data");
        _onCommandSent?.call(data);
      } else {
        _onError?.call("No USB port open");
      }
    } catch (e) {
      _onError?.call("Send error: $e");
    }
  }

  void _disconnect() {
    _subscription?.cancel();
    _transaction?.dispose();
    _port?.close();

    _subscription = null;
    _transaction = null;
    _port = null;
    device = null;
    _isPaused = false;
    _isConnected = false;
    _watchdogTimer?.cancel(); // Stop timer
    _watchdogTimer = null;

    _connectionStatusController.add(false);
    _onConnectionStatusChanged?.call("disconnected");
  }

  Future<List<UsbDevice>> listDevices() async {
    return await UsbSerial.listDevices();
  }

  void dispose() {
    _disconnect();
    _dataController.close();
    _connectionStatusController.close();
  }
}
