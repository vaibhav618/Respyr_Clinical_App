// // usb_cubit.dart
// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:respyr_clinical/clinical_app_respyr/screens/usb_test/screens/usb_clinical_breathe_tube.dart';
// import 'package:respyr_clinical/clinical_app_respyr/screens/usb_test/services/clinical_device_check_api.dart';
// import 'package:respyr_clinical/device_connectivity/domain/usb_repository.dart';
// import 'package:respyr_clinical/device_connectivity/presentation/cubit/usb_connection_state.dart';
// import 'package:respyr_clinical/new_result/data/model/result_profile_data_model.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// class UsbCubit extends Cubit<UsbState> {
//   final UsbRepository repository;

//   UsbCubit(this.repository) : super(const UsbState()) {
//     _init();
//   }

//   void _init() {
//     repository.setUsbListener(
//       onConnectionStatusChanged: (status) async {
//         print("USB status changed: $status");
//         final connected = status.toLowerCase().trim() == "connected";
//         emit(state.copyWith(isConnected: connected));

//         if (connected) {
//           await Future.delayed(const Duration(seconds: 1));
//           repository.sendData("!");
//         }
//       },
//       onDataReceived: (data) {
//         if (data.startsWith("H")) {
//           emit(state.copyWith(deviceId: data.substring(1).trim()));
//         }
//       },
//       onCommandSent: (command) {
//         print("Command sent: $command");
//       },
//       onError: (error) {
//         print("USB Error: $error");
//       },
//     );

//     _checkInitialConnection();
//   }

//   Future<void> _checkInitialConnection() async {
//     final devices = await repository.listDevices();
//     if (devices.isNotEmpty) {
//       await Future.delayed(const Duration(seconds: 1));
//       await repository.connectToDevice(devices.first);
//     }
//   }

//   // Future<void> checkDevice() async {
//   //   emit(state.copyWith(isChecking: true, deviceId: null));
//   //   repository.sendData("!");

//   //   int attempts = 0;
//   //   while (state.deviceId == null && attempts < 30) {
//   //     await Future.delayed(const Duration(milliseconds: 100));
//   //     attempts++;
//   //   }

//   //   emit(state.copyWith(isChecking: false));
//   // }

//   Future<void> checkAndProceed({
//     required bool isClinicalTest,
//     required BuildContext context,
//     required ResultProfileDataModel
//     profileDetails, // Type this properly if possible
//   }) async {
//     emit(state.copyWith(isChecking: true, deviceId: null));

//     repository.sendData("!");

//     int attempts = 0;
//     while (state.deviceId == null && attempts < 30) {
//       await Future.delayed(const Duration(milliseconds: 100));
//       attempts++;
//     }

//     final deviceId = state.deviceId;

//     if (deviceId != null) {
//       await clinicalDeviceCheckApi(deviceId);

//       final prefs = await SharedPreferences.getInstance();
//       final isReady = prefs.getBool("is_device_ready") ?? false;

//       if (isReady) {
//         if (!context.mounted) return;

//         Navigator.push(
//           context,
//           MaterialPageRoute(
//             builder:
//                 (_) => UsbClinicalBreatheTube(
//                   isClinicalTest: isClinicalTest,
//                   profileDetails: profileDetails,
//                 ),
//           ),
//         );
//       } else {
//         if (context.mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(
//               content: Text("Device not ready yet. Please try again."),
//             ),
//           );
//         }
//       }
//     } else {
//       if (context.mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text("Device ID not received. Please reconnect."),
//           ),
//         );
//       }
//     }

//     if (context.mounted) {
//       emit(state.copyWith(isChecking: false));
//     }
//   }
// }

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:respyr_clinical/clinical_app_respyr/screens/usb_test/screens/usb_clinical_breathe_tube.dart';
import 'package:respyr_clinical/clinical_app_respyr/screens/usb_test/services/clinical_device_check_api.dart';
import 'package:respyr_clinical/device_connectivity/domain/usb_repository.dart';
import 'package:respyr_clinical/device_connectivity/presentation/cubit/usb_connection_state.dart';
import 'package:respyr_clinical/new_result/data/model/result_profile_data_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UsbCubit extends Cubit<UsbState> {
  final UsbRepository repository;
  Timer? _healthCheckTimer;

  /// A device that has finished its cycle is silent between the "!" handshake
  /// and the first calibration signal. One that is still working through the
  /// cycle left behind by a cancelled reading keeps streaming — sensor values
  /// while it is in calibration mode, bare counters while it is purging. Any
  /// such unsolicited traffic means it is not ready to start a new test.
  bool _watchingForChatter = false;
  bool _sawChatter = false;

  /// How long to listen before deciding the device is idle. The busy device
  /// emits several packets a second, so this is comfortably long enough.
  static const Duration _readinessProbe = Duration(milliseconds: 1500);

  UsbCubit(this.repository) : super(const UsbState()) {
    _init();
  }

  void _init() {
    repository.setUsbListener(
      onConnectionStatusChanged: (status) async {
        print("USB Connection Status Changed: $status");
        final connected = status.toLowerCase().trim() == "connected";

        emit(
          state.copyWith(
            isConnected: connected,
            deviceId:
                connected ? state.deviceId : null, // Null when disconnected!
          ),
        );
        if (connected) {
          repository.sendData("!");

          emit(state.copyWith(deviceId: null));
        } else {
          _healthCheckTimer?.cancel();
          emit(
            state.copyWith(
              isConnected: false,
              deviceId: null,
              isChecking: false,
            ),
          );
        }
      },
      onDataReceived: (data) {
        print("Data Received from Device: $data");
        if (data.startsWith("H")) {
          emit(state.copyWith(deviceId: data.substring(1).trim()));
          return;
        }
        if (_watchingForChatter && data.trim().isNotEmpty) {
          _sawChatter = true;
        }
      },
      onCommandSent: (command) {
        print("Command sent to Device: $command");
      },
      onError: (error) {
        print("USB Error: $error");
      },
    );

    _checkInitialConnection();
  }

  void reinitializeListener() {
    _init(); // or just the listener logic if _init does too much
  }

  Future<void> _checkInitialConnection() async {
    final devices = await repository.listDevices();
    if (devices.isNotEmpty) {
      print("Devices found initially: ${devices.first}");
      await Future.delayed(const Duration(seconds: 1));
      await repository.connectToDevice(devices.first);
    } else {
      emit(state.copyWith(isConnected: false, deviceId: null));
    }
  }

  Future<void> checkAndProceed({
    required bool isClinicalTest,
    required BuildContext context,
    required ResultProfileDataModel profileDetails,
  }) async {
    emit(state.copyWith(isChecking: true, deviceId: null));

    repository.sendData("!");

    int attempts = 0;
    while (state.deviceId == null && attempts < 30) {
      await Future.delayed(const Duration(milliseconds: 100));
      attempts++;
    }

    final deviceId = state.deviceId;

    if (deviceId != null) {
      // Gate entry on the device actually being idle. A cancelled reading
      // leaves it part-way through its own cycle, and it ignores the
      // calibration signals until that finishes — so a test started now just
      // sits in calibration until the device happens to come back. Replugging
      // is the only thing that resets it, so say so instead of letting the
      // user walk into a hang.
      if (!await _isDeviceIdle()) {
        if (context.mounted) {
          emit(state.copyWith(isChecking: false));
          await _showDeviceBusyDialog(context);
        }
        return;
      }

      await clinicalDeviceCheckApi(deviceId);
      final prefs = await SharedPreferences.getInstance();
      final isReady = prefs.getBool("is_device_ready") ?? false;

      if (isReady && context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (_) => UsbClinicalBreatheTube(
                  isClinicalTest: isClinicalTest,
                  profileDetails: profileDetails,
                ),
          ),
        );
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Device not ready yet. Please try again."),
          ),
        );
      }
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Device ID not received. Please reconnect."),
        ),
      );
    }

    if (context.mounted) {
      emit(state.copyWith(isChecking: false));
    }
  }

  /// Listen briefly and report whether the device stayed quiet. See
  /// [_watchingForChatter] for why silence is the readiness signal.
  Future<bool> _isDeviceIdle() async {
    _sawChatter = false;
    _watchingForChatter = true;
    await Future.delayed(_readinessProbe);
    _watchingForChatter = false;
    if (_sawChatter) {
      print("⛔ Device still busy from a previous test — blocking new test.");
    }
    return !_sawChatter;
  }

  Future<void> _showDeviceBusyDialog(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Device not ready"),
        content: const Text(
          "The device is still finishing the previous test. Unplug it, plug it "
          "back in, and start the test again.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  Future<void> close() {
    _healthCheckTimer?.cancel();
    return super.close();
  }
}
