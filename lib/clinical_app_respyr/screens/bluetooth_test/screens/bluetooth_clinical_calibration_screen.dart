import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:respyr_clinical/clinical_app_respyr/screens/bluetooth_test/screens/bluetooth_clinical_inhale_screen.dart';
import 'package:respyr_clinical/clinical_app_respyr/screens/bluetooth_test/services/clinical_bluetooth_manager.dart';
import 'package:respyr_clinical/clinical_app_respyr/services/device_battery_utils.dart';
import 'package:respyr_clinical/clinical_app_respyr/services/disconnected_error.dart';
import 'package:respyr_clinical/clinical_dashboard/views/clinical_dashboard.dart';
import 'package:respyr_clinical/shared/audio_helper.dart';
import 'package:respyr_clinical/shared/colors.dart';

import '../../../../clinical_dashboard/bloc/health_score_bloc.dart';
import '../../../../clinical_dashboard/service/overall_data_by_date_service.dart';
import '../../../../new_result/data/model/result_profile_data_model.dart';

class BluetoothCalibrationScreen extends StatefulWidget {
  final ResultProfileDataModel profileDetails;
  const BluetoothCalibrationScreen({super.key, required this.profileDetails});

  @override
  State<BluetoothCalibrationScreen> createState() =>
      _BluetoothCalibrationScreenState();
}

class _BluetoothCalibrationScreenState extends State<BluetoothCalibrationScreen>
    with SingleTickerProviderStateMixin {
  final ClinicalBluetoothManager _bleManager = ClinicalBluetoothManager();
  late StreamSubscription<bool> _connectionStatusSubscription;
  late StreamSubscription<String> _receivedDataSubscription;
  late AnimationController _animationController;


  final storage = GetStorage();
  bool _isConnected = false;
  int _completedSteps = 0;
  bool _navigatedToInhaleScreen = false;
  bool _isDisposed = false;
  bool _isDisconnectDialogPop = false;
  bool _hasShownDisconnectedDialog = false;
  final AudioHelper _audioHelper = AudioHelper();

  final List<String> progressMessage = [
    "Cleaning inner\nChamber of Device",
    "Verifying Cleanlliness",
    "Initialing Calibration",
    "Activating Sensors",
    "Getting Device Ready",
  ];

  final List<String> calibrationGifs = [
    "assets/gif_images/cal0.gif",
    "assets/gif_images/cal1.gif",
    "assets/gif_images/cal2.gif",
    "assets/gif_images/cal3.gif",
    "assets/gif_images/cal4.gif",
  ];

  @override
  void initState() {
    super.initState();
    setState(() {
      _isConnected = _bleManager.isConnected;
    });

    _initializeAnimationController();
    _checkBluetoothDeviceConnectivity();
    _startProgress();
  }

  void _initializeAnimationController() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  void _handleDisconnection() {
    if (_isDisposed ||
        _isConnected ||
        _isDisconnectDialogPop ||
        _hasShownDisconnectedDialog) {
      return;
    }

    _isDisconnectDialogPop = true; // Prevent multiple dialogs
    _hasShownDisconnectedDialog = true;

    showDeviceDisconnectedBox(
      context: context,
      onButtonPressed: () async {
        if (!_isDisconnectDialogPop) return;
        _isDisconnectDialogPop = false; // ✅ Reset BEFORE connecting
        Navigator.pop(context);
        await Future.delayed(const Duration(milliseconds: 300));
        abortProcess();
        _navigateToDashboard(); // Attempt reconnect
      },
    );
  }

  void _checkBluetoothDeviceConnectivity() {
    // Update connection status
    _connectionStatusSubscription = _bleManager.connectionStatusStream.listen((
      isConnected,
    ) {
      if (!_isDisposed) {
        setState(() => _isConnected = isConnected);
        if (isConnected) {
          _hasShownDisconnectedDialog = false;
          _isDisconnectDialogPop = false;
        }

        if (!isConnected &&
            !_isDisposed &&
            !_isDisconnectDialogPop &&
            !_hasShownDisconnectedDialog) {
          Future.delayed(const Duration(milliseconds: 500)).then((_) {
            if (!_isConnected) {
              // Double-check before showing the dialog
              if (!mounted || _isDisposed || _isConnected) return;
              _animationController.stop();
              _audioHelper.stopAudio();
              _handleDisconnection();
            }
          });
        }
        _isDisconnectDialogPop = false;
      }
    }, onError: (error) => _showErrorDialog("Connection status error."));

    // Handle received data
    _receivedDataSubscription = _bleManager.receivedDataStream.listen(
      (data) {
        // if (kDebugMode) {
        //   print("New Data Received CalibrationScreen: $data");
        // }
        if (data.contains("inhale") && !_navigatedToInhaleScreen) {
          if (mounted) {
            _stopAllProcesses();
            _navigateToInhaleScreen();
          }
        } else if (batteryVoltageReceived(data)) {
          final pattern = RegExp(r'^@(.+)@$');
          final match = pattern.firstMatch(data);

          if (match != null) {
            int batteryPercentage = BatteryUtils.calculateBatteryPercentage(
              extractBatteryVoltage(data),
            );
            if (kDebugMode) {
              print("Battery Percentage :$batteryPercentage");
            }
          }
        }
      },
      onError: (error) => _showErrorDialog("Error receiving data from device."),
    );
  }

  bool batteryVoltageReceived(String input) {
    final pattern = RegExp(r'^@.+@$');
    return pattern.hasMatch(input);
  }

  double extractBatteryVoltage(String data) {
    final pattern = RegExp(r'^@(.+)@$');
    final match = pattern.firstMatch(data);

    if (match != null) {
      return double.tryParse(match.group(1)!) ?? 0.0;
    }
    return 0.0; // default if no match
  }

  Future<void> _startProgress() async {
    for (int i = 1; i <= 5; i++) {
      if (i < 5) {
        // Steps 0 to 4: Process normally for 20 seconds
        for (int seconds = 20; seconds > 0; seconds--) {
          if (_isDisposed || _navigatedToInhaleScreen) return;

          if (kDebugMode) {
            print("Step $i: $seconds seconds remaining");
          }
          await Future.delayed(const Duration(seconds: 1));
          if (!mounted || _navigatedToInhaleScreen) return;
        }
      } else {
        // Step 5: Keep checking until "inhale" is received
        if (kDebugMode) {
          print("Step 5 started: Waiting for 'inhale' data...");
        }

        while (!_navigatedToInhaleScreen) {
          await Future.delayed(const Duration(seconds: 1));

          if (_isDisposed || _navigatedToInhaleScreen) return;

          if (kDebugMode) {
            print("Still waiting for 'inhale'");
          }
        }
      }

      if (!_isDisposed) {
        setState(() => _completedSteps = i);
        _restartAnimation();
        await _sendStepSpecificData(i);

        if (i == 5) {
          if (kDebugMode) {
            print("Final Step: Waiting for 'inhale' completed!");
          }
        }
      }
    }
  }

  Future<void> _sendStepSpecificData(int step) async {
    try {
      if (!_bleManager.isConnected) {
        if (kDebugMode) {
          print("⚠️ BLE device not connected. Skipping send for step $step.");
        }
        return;
      }

      if (kDebugMode) {
        print("Sending step-specific data for step $step");
      }

      switch (step) {
        case 2:
          await _bleManager.sendData("?");
          await _bleManager.sendData("}");
          await _bleManager.sendData("{");
          await _bleManager.sendData("+");
          break;
        case 3:
          _audioHelper.playActivatingSensors();
          break;
        case 4:
          _audioHelper.playStartBreathTest();
          await Future.delayed(const Duration(seconds: 10));
          break;
      }
    } catch (e, stacktrace) {
      if (kDebugMode) {
        print("❌ Error sending data: $e");
        print(stacktrace);
      }

      _showErrorDialog("Failed to send data to the device.");
    }
  }

  void _restartAnimation() {
    if (!_isDisposed) {
      _animationController.reset();
      _animationController.repeat();
    }
  }

  void _showErrorDialog(String message) {
    if (!_isDisposed) {
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text("Error"),
              content: Text(message),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text("OK"),
                ),
              ],
            ),
      );
    }
  }

  void _stopAllProcesses() {
    _isDisposed = true;
    _connectionStatusSubscription.cancel();
    _receivedDataSubscription.cancel();
    _animationController.stop();
  }

  void _navigateToInhaleScreen() {
    _navigatedToInhaleScreen = true;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) =>
                BluetoothInhaleScreen(profileDetails: widget.profileDetails),
      ),
    ).then((_) {
      if (mounted) {
        setState(() {
          _navigatedToInhaleScreen = false;
        });
      }
    });
  }

  Future<bool> _showCancelTestDialog(BuildContext context) async {
    bool didCancel = false;

    showCancelTestBox(
      context: context,
      cancelTestButtonPressed: () async {
        debugPrint("🛑 Cancel button pressed");

        didCancel = true;

        abortProcess();
        if (mounted) {
          Navigator.pop(context);
        }

        await Future.delayed(const Duration(milliseconds: 300));

        await _exitToDashboard();
      },
    );

    return didCancel;
  }

  Future<void> _exitToDashboard() async {
    if (mounted) {
      _navigateToDashboard();
    }
  }




  void _navigateToDashboard() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder:
            (_) => BlocProvider(
          create: (_) => HealthScoreBloc(OverallDataByDateService()),
          child: ClinicalDashboardMain(
            loginId: widget.profileDetails.clinicName!,
          ),
        ),
      ),
          (route) => false,
    );
  }

  void abortProcess() {
    if (_isConnected) {
      _bleManager.sendData("&");
    }
  }



  @override
  void dispose() {
    _stopAllProcesses();
    _animationController.dispose();
    super.dispose();
  }

  Widget _buildProgressIndicator(int step) {
    final bool isCurrentStep = _completedSteps == step;
    final bool isCompleted = _completedSteps > step;

    return Row(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            if (isCurrentStep)
              SizedBox(
                height: 25,
                width: 25,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColor.textLightColor,
                  ),
                  strokeWidth: 3.0,
                ),
              ),
            SvgPicture.asset(
              isCompleted ? "assets/verified.svg" : "assets/unverified.svg",
              height: 25,
              width: 25,
            ),
          ],
        ),
        if (step < 4)
          Container(
            height: 5,
            width: 50,
            decoration: BoxDecoration(
              color:
                  isCompleted
                      ? AppColor.buttonGreenColor
                      : const Color(0xFFE0E0E0),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: AppColor.whiteColor,
        statusBarIconBrightness: Brightness.dark,
      ),
    );


    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColor.whiteColor,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: () => _showCancelTestDialog(context),
                      icon: SvgPicture.asset("assets/svg_icons/close_icon.svg"),
                    ),
                    const Spacer(),
                    // Text(
                    //   "$batteryPercentage%",
                    //   style: TextStyle(
                    //     color: AppColor.primaryBlackColor,
                    //     fontWeight: FontWeight.w600,
                    //     fontSize: 8,
                    //   ),
                    // ),
                    // const SizedBox(width: 2),
                    //BatteryUtils.batteryIndicatorWidget(batteryPercentage),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _audioHelper.toggleMute();
                        });
                      },
                      icon: Icon(
                        _audioHelper.isMuted
                            ? Icons.volume_off
                            : Icons.volume_up,
                      ),
                    ),
                  ],
                ),
                Image(
                  image: AssetImage(
                    _completedSteps >
                            4 // Ensure index doesn't go out of bounds
                        ? calibrationGifs[4] // Use the last available GIF
                        : calibrationGifs[_completedSteps],
                  ),
                ),
                Text(
                  _completedSteps > 4
                      ? progressMessage[4]
                      : progressMessage[_completedSteps],
                  textAlign: TextAlign.center,
                  style: GoogleFonts.roboto(
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: AppColor.textLightColor,
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    5,
                    (index) => _buildProgressIndicator(index),
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.06),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
