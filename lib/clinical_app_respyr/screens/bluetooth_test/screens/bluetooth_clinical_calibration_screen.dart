import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:respyr_clinical/clinical_app_respyr/screens/bluetooth_test/screens/bluetooth_clinical_inhale_screen.dart';
import 'package:respyr_clinical/clinical_app_respyr/screens/bluetooth_test/services/clinical_bluetooth_manager.dart';
import 'package:respyr_clinical/clinical_app_respyr/services/device_battery_utils.dart';
import 'package:respyr_clinical/clinical_app_respyr/services/disconnected_error.dart';
import 'package:respyr_clinical/shared/audio_helper.dart';
import 'package:respyr_clinical/shared/colors.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../common/floating_message.dart';
import '../../../../new_result/data/model/result_profile_data_model.dart';
import '../../../../router/app_routers.dart';

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

  StreamSubscription<bool>? _connectionStatusSubscription;
  StreamSubscription<String>? _receivedDataSubscription;
  late AnimationController _animationController;

  final storage = GetStorage();

  bool _isConnected = false;
  int _completedSteps = 0;
  bool _navigatedToInhaleScreen = false;
  bool _isDisposed = false;
  bool _isDisconnectDialogPop = false;
  bool _hasShownDisconnectedDialog = false;

  final AudioHelper _audioHelper = AudioHelper();

  bool allSignalSent = false;

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

    _isConnected = _bleManager.isConnected;

    _initializeAnimationController();
    _checkBluetoothDeviceConnectivity();

    // Start progress after first frame so context is safe for dialogs/snackbars
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _startProgress();
    });
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

    _isDisconnectDialogPop = true;
    _hasShownDisconnectedDialog = true;

    showDeviceDisconnectedBox(
      context: context,
      onButtonPressed: () async {
        if (!_isDisconnectDialogPop) return;

        _isDisconnectDialogPop = false;
        Navigator.pop(context);

        await Future.delayed(const Duration(milliseconds: 300));

        abortProcess();
        _navigateToDashboard();
      },
    );
  }

  void _checkBluetoothDeviceConnectivity() {
    _connectionStatusSubscription =
        _bleManager.connectionStatusStream.listen((isConnected) {
          if (_isDisposed) return;

          if (mounted) {
            setState(() => _isConnected = isConnected);
          } else {
            _isConnected = isConnected;
          }

          if (isConnected) {
            _hasShownDisconnectedDialog = false;
            _isDisconnectDialogPop = false;
          }

          if (!isConnected &&
              !_isDisposed &&
              !_isDisconnectDialogPop &&
              !_hasShownDisconnectedDialog) {
            Future.delayed(const Duration(milliseconds: 500)).then((_) {
              if (_isDisposed) return;
              if (_isConnected) return;
              if (!mounted) return;

              _animationController.stop();
              _audioHelper.stopAudio();
              _handleDisconnection();
            });
          }
        }, onError: (_) => _showErrorDialog("Connection status error."));

    _receivedDataSubscription = _bleManager.receivedDataStream.listen(
          (data) {
        if (_isDisposed) return;

        if (data.contains("inhale") && !_navigatedToInhaleScreen) {
          if (mounted) {
            _stopAllProcesses();
            _navigateToInhaleScreen();
          }
          return;
        }

        if (batteryVoltageReceived(data)) {
          final pattern = RegExp(r'^@(.+)@$');
          final match = pattern.firstMatch(data);
          if (match != null) {
            final batteryPercentage = BatteryUtils.calculateBatteryPercentage(
              extractBatteryVoltage(data),
            );
            if (kDebugMode) {
              print("Battery Percentage :$batteryPercentage");
            }
          }
        }
      },
      onError: (_) => _showErrorDialog("Error receiving data from device."),
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
    return 0.0;
  }

  Future<void> _startProgress() async {
    // ✅ Send signal immediately when timer starts
    await _sendInitialSignal();

    for (int i = 1; i <= 5; i++) {
      if (_isDisposed || _navigatedToInhaleScreen) return;

      // Step timers
      if (i < 5) {
        for (int seconds = 20; seconds > 0; seconds--) {
          if (_isDisposed || _navigatedToInhaleScreen) return;
          await Future.delayed(const Duration(seconds: 1));
          if (!mounted || _navigatedToInhaleScreen || _isDisposed) return;
        }
      } else {
        // Step 5: wait until inhale comes
        while (!_navigatedToInhaleScreen) {
          if (_isDisposed) return;
          await Future.delayed(const Duration(seconds: 1));
        }
      }

      if (_isDisposed) return;

      if (mounted) {
        setState(() => _completedSteps = i);
      } else {
        _completedSteps = i;
      }

      _restartAnimation();
      await _sendStepSpecificData(i);
    }
  }

  /// Sends the initial calibration signal once.
  /// If device is not connected at start, it will be retried in step 1 and 2.
  Future<void> _sendInitialSignal() async {
    if (allSignalSent) return;
    if (!_bleManager.isConnected) return;

    final prefs = await SharedPreferences.getInstance();
    final String signal = prefs.getString("isFirstReading") ?? "{";

    if (_isDisposed) return;

    if (kDebugMode) {
      print("🚀 Sending initial signal at timer start: $signal");
    }

    if (mounted) {
      FloatingMessage.show(context, message: signal);
    }

    await _bleManager.sendData("?");
    await _bleManager.sendData("}");
    await _bleManager.sendData(signal);
    await _bleManager.sendData("+");

    allSignalSent = true;
  }

  Future<void> _sendStepSpecificData(int step) async {
    try {
      if (_isDisposed) return;

      // ✅ Retry signal only for step 1 & 2 if not sent at timer start
      if (!allSignalSent && (step == 1 || step == 2)) {
        await _sendInitialSignal();
      }

      switch (step) {
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
      if (!_isDisposed) {
        _showErrorDialog("Failed to send data to the device.");
      }
    }
  }

  void _restartAnimation() {
    if (_isDisposed) return;
    _animationController
      ..reset()
      ..repeat();
  }

  void _showErrorDialog(String message) {
    if (_isDisposed || !mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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

  void _stopAllProcesses() {
    _isDisposed = true;
    _connectionStatusSubscription?.cancel();
    _receivedDataSubscription?.cancel();
    _animationController.stop();
    _audioHelper.stopAudio();
  }

  void _navigateToInhaleScreen() {
    _navigatedToInhaleScreen = true;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            BluetoothInhaleScreen(profileDetails: widget.profileDetails),
      ),
    ).then((_) {
      if (!mounted) return;
      setState(() => _navigatedToInhaleScreen = false);
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
    _stopAllProcesses();
    await _setCancelOrDisconnectFlag();

    if (mounted) {
      _navigateToDashboard();
    }
  }

  Future<void> _setCancelOrDisconnectFlag() async {
    final DateTime now = DateTime.now();
    await storage.write('cancel_or_disconnect_time', now.toIso8601String());
  }

  void _navigateToDashboard() {
    if (Get.isOverlaysOpen) {
      Get.back();
    }

    Get.offAllNamed(
      AppRoutes.mainDashboard,
      arguments: {
        'profile_details': widget.profileDetails,
      },
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
                  valueColor:
                  AlwaysStoppedAnimation<Color>(AppColor.textLightColor),
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
              color: isCompleted
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
                    _completedSteps > 4
                        ? calibrationGifs[4]
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
