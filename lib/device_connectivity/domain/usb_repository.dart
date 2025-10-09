import 'package:usb_serial/usb_serial.dart';

abstract class UsbRepository {
  Future<List<UsbDevice>> listDevices();
  Future<void> connectToDevice(UsbDevice device);
  void sendData(String data);
  void setUsbListener({
    required void Function(String status) onConnectionStatusChanged,
    required void Function(String data) onDataReceived,
    required void Function(String command) onCommandSent,
    required void Function(String error) onError,
  });
}
