import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:respyr_clinical/clinical_app_respyr/screens/usb_test/screens/usb_clinical_calibration_screen.dart';
import 'package:respyr_clinical/clinical_app_respyr/screens/usb_test/services/clinical_usb_communication_services.dart';
import 'package:respyr_clinical/clinical_app_respyr/services/disconnected_error.dart';
import 'package:respyr_clinical/widgets/internet_connectivity_check.dart';
import 'package:respyr_clinical/shared/audio_helper.dart';
import 'package:respyr_clinical/shared/colors.dart';

import '../../../../clinical_dashboard/bloc/health_score_bloc.dart';
import '../../../../clinical_dashboard/service/overall_data_by_date_service.dart';
import '../../../../clinical_dashboard/views/clinical_dashboard.dart';
import '../../../../new_result/data/model/result_profile_data_model.dart';

class UsbClinicalBreatheTube extends StatefulWidget {
  final bool isClinicalTest;
  final ResultProfileDataModel profileDetails;
  const UsbClinicalBreatheTube({
    super.key,
    this.isClinicalTest = false,
    required this.profileDetails,
  });

  @override
  State<UsbClinicalBreatheTube> createState() => _UsbClinicalBreatheTubeState();
}

class _UsbClinicalBreatheTubeState extends State<UsbClinicalBreatheTube> {
  final ClinicalUsbCommunicationServices _usbService =
      ClinicalUsbCommunicationServices();
  final AudioHelper _audioHelper = AudioHelper();

  Timer? _progressTimer;

  double progress = 0;
  bool _isConnected = false;
  bool _dialogShown = false;
  bool _hasInternet = true;
  bool _isDialogShowing = false;

  @override
  void initState() {
    super.initState();

    _checkConnectionAndStart();
    _listenToDisconnection();
  }

  void _checkConnectionAndStart() async {
    final devices = await _usbService.listDevices();
    if (devices.isNotEmpty) {
      setState(() {
        _isConnected = true;
      });
      _startProgress();
    }
  }

  void _listenToDisconnection() {
    _usbService.setUsbSerialListener(
      onConnectionStatusChanged: (status) async {
        final connected = status.toLowerCase().trim() == "connected";

        if (!mounted) return;

        setState(() {
          _isConnected = connected;
        });

        if (!connected) {
          Future.delayed(const Duration(milliseconds: 500)).then((_) {
            _progressTimer!.cancel();
            _audioHelper.stopAudio();
            _handleDisconnected();
          });
        }
      },
      onError: (error) {},
    );
  }

  void _handleDisconnected() {
    _stopProgress();
    if (_dialogShown || !(ModalRoute.of(context)?.isCurrent ?? false)) return;

    _dialogShown = true;
    showDeviceDisconnectedBox(
      context: context,
      onButtonPressed: () async {
        Get.back();
        await Future.delayed(const Duration(milliseconds: 300));
        _abortProcess();
        _exitToDashboard();
      },
    );
  }

  void _abortProcess() {
    debugPrint("🛑 Aborting calibration...");
    debugPrint("USB connected: $_isConnected");

    try {
      if (_isConnected) {
        _usbService.sendData("&");
        debugPrint("✅ Sent '&' to abort process");
      } else {
        debugPrint("⚠️ Device not connected, cannot send '&'");
      }
    } catch (e) {
      debugPrint("❌ Failed to send '&': $e");
    }
  }

  void _startProgress() {
    const totalDuration = 5;
    const steps = totalDuration * 1000 / 10;
    const incrementValue = 1.0 / steps;

    _audioHelper.playPlaceBreatheTube();

    _progressTimer?.cancel();
    _progressTimer = Timer.periodic(const Duration(milliseconds: 10), (
      Timer timer,
    ) {
      if (!mounted || !_isConnected || !_hasInternet) {
        timer.cancel();
        return;
      }

      setState(() {
        if (progress >= 1) {
          progress = 1.0;
          timer.cancel();
          if (!_hasInternet) {
            debugPrint(
              "❌ Blocked navigation to calibration due to no internet",
            );
            return;
          }
          if (widget.isClinicalTest) {
            Get.offAll(
              () => UsbClinicalCalibrationScreen(
                profileDetails: widget.profileDetails,
              ),
            );
          } else {
            // Get.offAll(() => const ClinicalUserInformation());
          }
        } else {
          progress += incrementValue;
        }
      });
    });
  }

  void _stopProgress() {
    _progressTimer?.cancel();
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

  Future<void> _exitToDashboard() async {
    _stopProgress();
    if (mounted) {
      _navigateToDashboard();
    }
  }

  Future<bool> _showCancelTestDialog(BuildContext context) async {
    bool didCancel = false;

    showCancelTestBox(
      context: context,
      cancelTestButtonPressed: () async {
        debugPrint("🛑 Cancel button pressed");

        didCancel = true;

        _abortProcess();
        if (mounted) {
          Navigator.pop(context);
        }

        await Future.delayed(const Duration(milliseconds: 300));

        await _exitToDashboard();
      },
    );

    return didCancel;
  }

  @override
  void dispose() {
    _stopProgress();
    _progressTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: AppColor.whiteColor,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    final height = MediaQuery.of(context).size.height;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          final shouldExit = await _showCancelTestDialog(context);

          if (shouldExit) {}
        }
      },
      child: InternetConnectivityHandler(
        onConnectivityChanged: (hasInternet) async {
          debugPrint("📡 Connectivity changed on Breathe Tube: $hasInternet");

          if (!hasInternet && !_isDialogShowing) {
            _isDialogShowing = true;
            _hasInternet = false;
            _stopProgress();
          } else if (hasInternet) {
            _isDialogShowing = false;
            _hasInternet = true;
            progress = 0;
            _checkConnectionAndStart();
          }
        },

        onRetry: () async {
          if (_isDialogShowing) return;
          _isDialogShowing = true;

          debugPrint("🔁 Retry tapped — navigating to Dashboard");
          _abortProcess();
          await _exitToDashboard();

          _isDialogShowing = false;
        },
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
                        onPressed: () => _showCancelTestDialog(context),
                        icon: SvgPicture.asset(
                          "assets/svg_icons/close_icon.svg",
                        ),
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
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: const Color(0xFFE0E0E0),
                      color: AppColor.primaryBlueColor,
                      minHeight: 15,
                      borderRadius: BorderRadius.circular(15),
                    ),
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
      ),
    );
  }
}

class NoSwipeCupertinoPageRoute<T> extends CupertinoPageRoute<T> {
  NoSwipeCupertinoPageRoute({required super.builder, super.settings});

  @override
  bool get popGestureEnabled => false;
}
