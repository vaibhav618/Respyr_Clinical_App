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

  @override
  Future<void> close() {
    _healthCheckTimer?.cancel();
    return super.close();
  }
}
