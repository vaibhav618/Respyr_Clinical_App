import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:respyr_clinical/clinical_app_respyr/screens/bluetooth_test/screens/bluetooth_clinical_calibration_screen.dart';
import 'package:respyr_clinical/clinical_app_respyr/screens/bluetooth_test/services/clinical_bluetooth_manager.dart';
import 'package:respyr_clinical/clinical_app_respyr/services/device_battery_utils.dart';
import 'package:respyr_clinical/clinical_app_respyr/services/disconnected_error.dart';
import 'package:respyr_clinical/shared/audio_helper.dart';
import 'package:respyr_clinical/shared/colors.dart';

import '../../../../new_result/data/model/result_profile_data_model.dart';

class BluetoothBreatheTube extends StatefulWidget {
  final ResultProfileDataModel profileDetails;
  const BluetoothBreatheTube({super.key, required this.profileDetails});

  @override
  State<BluetoothBreatheTube> createState() => _BluetoothBreatheTubeState();
}

class _BluetoothBreatheTubeState extends State<BluetoothBreatheTube> {
  double progress = 0;
  Timer? _timer;

  final storage = GetStorage();
  int batteryPercentage = 0;
  final ClinicalBluetoothManager _bleManager = ClinicalBluetoothManager();
  final AudioHelper _audioHelper = AudioHelper();
  bool _isConnected = false;
  bool _hasShownDisconnectedDialog = false;
  bool _deviceDisconnectsPops = false;

  @override
  void initState() {
    super.initState();
    startProgress();
    _isConnected = _bleManager.isConnected;

    _checkBluetoothDeviceConnectivity();
  }

  void startProgress() {
    const totalDuration = 5;
    const steps = totalDuration * 1000 / 15;
    const incrementValue = 1.0 / steps;

    // Cancel any existing timer before starting a new one
    _timer?.cancel();
    _audioHelper.playPlaceBreatheTube();
    _timer = Timer.periodic(const Duration(milliseconds: 15), (Timer timer) {
      if (!mounted) return; // Ensure the widget is still in the tree
      setState(() {
        if (progress >= 1) {
          progress = 1.0;
          timer.cancel();

          Get.offAll(
            () => BluetoothCalibrationScreen(
              profileDetails: widget.profileDetails,
            ),
          );
        } else {
          progress += incrementValue;
        }
      });
    });
  }

  void _checkBluetoothDeviceConnectivity() {
    if (_isConnected || _hasShownDisconnectedDialog || _deviceDisconnectsPops) {
      return;
    }
    _bleManager.connectionStatusStream.listen((isConnected) {
      if (!mounted) return;

      setState(() {
        _isConnected = isConnected;
      });

      // Reset dialog control flag when connected
      if (isConnected) {
        _hasShownDisconnectedDialog = false;
        _deviceDisconnectsPops = false;
      }

      if (!isConnected && !_hasShownDisconnectedDialog) {
        Future.delayed(const Duration(milliseconds: 500)).then((_) {
          if (!_isConnected) {
            // Double-check before showing the dialog
            if (!mounted || _isConnected) return;
            _timer!.cancel();
            _audioHelper.stopAudio();
            _handleDisconnection();
          }
        });
      }
      _deviceDisconnectsPops = false;
    });
  }

  void _handleDisconnection() {
    if (_isConnected || _hasShownDisconnectedDialog || _deviceDisconnectsPops) {
      return;
    }

    _hasShownDisconnectedDialog = true;
    _deviceDisconnectsPops = true;

    showDeviceDisconnectedBox(
      context: context,
      onButtonPressed: () async {
        _deviceDisconnectsPops = false;
        Get.back();
        await Future.delayed(const Duration(milliseconds: 300));
      },
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void resetProgress() {
    setState(() {
      progress = 0;
    });
    _timer?.cancel();
  }

  Future<void> _showCancelTestDialog() async {
    showCancelTestBox(
      context: context,
      cancelTestButtonPressed: () {
        abortProcess();
      },
    );
  }

  void abortProcess() {
    if (_isConnected) {
      _bleManager.sendData("&");
    }
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: AppColor.whiteColor,
        statusBarIconBrightness: Brightness.dark,
      ),
    );
    batteryPercentage = storage.read('batteryPercentage');
    final height = MediaQuery.of(context).size.height;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColor.whiteColor,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: () => _showCancelTestDialog(),
                      icon: SvgPicture.asset("assets/svg_icons/close_icon.svg"),
                    ),
                    const Spacer(),
                    Text(
                      "$batteryPercentage%",
                      style: TextStyle(
                        color: AppColor.primaryBlackColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 8,
                      ),
                    ),
                    const SizedBox(width: 2),
                    BatteryUtils.batteryIndicatorWidget(batteryPercentage),
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
                SizedBox(height: height * 0.15),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    "Place the mouth tube in the slot",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.mulish(
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      color: AppColor.textLightColor,
                    ),
                  ),
                ),
                Image.asset("assets/gif_images/mouth_tube.gif"),
                SizedBox(height: height * 0.05),
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: const Color(0xFFE0E0E0),
                  color: AppColor.primaryBlueColor,
                  minHeight: 15,
                  borderRadius: BorderRadius.circular(15),
                ),
                SizedBox(height: height * 0.02),
                Text(
                  'Loading... ${(progress * 100).toInt()}%',
                  style: GoogleFonts.roboto(
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: AppColor.primaryBlueColor,
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class NoSwipeCupertinoPageRoute<T> extends CupertinoPageRoute<T> {
  NoSwipeCupertinoPageRoute({required super.builder, super.settings});

  @override
  bool get popGestureEnabled => false; // 🚫 disables swipe back
}
