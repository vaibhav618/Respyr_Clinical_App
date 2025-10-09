// usb_cubit_state.dart
import 'package:equatable/equatable.dart';

class UsbState extends Equatable {
  final bool isConnected;
  final bool isChecking;
  final String? deviceId;

  const UsbState({
    this.isConnected = false,
    this.isChecking = false,
    this.deviceId,
  });

  UsbState copyWith({bool? isConnected, bool? isChecking, String? deviceId}) {
    return UsbState(
      isConnected: isConnected ?? this.isConnected,
      isChecking: isChecking ?? this.isChecking,
      deviceId: deviceId ?? this.deviceId,
    );
  }

  @override
  List<Object?> get props => [isConnected, isChecking, deviceId];
}
