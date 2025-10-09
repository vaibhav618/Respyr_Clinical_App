import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:respyr_clinical/clinical_app_respyr/screens/usb_test/screens/usb_clinical_inhale_screen.dart';
import 'package:respyr_clinical/clinical_app_respyr/screens/usb_test/services/clinical_usb_communication_services.dart';
import 'package:respyr_clinical/clinical_app_respyr/services/disconnected_error.dart';
import 'package:respyr_clinical/widgets/internet_connectivity_check.dart';
import 'package:respyr_clinical/shared/audio_helper.dart';
import 'package:respyr_clinical/shared/colors.dart';
import 'package:respyr_clinical/shared/get_stored_data_text.dart';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../../clinical_dashboard/bloc/health_score_bloc.dart';
import '../../../../clinical_dashboard/service/overall_data_by_date_service.dart';
import '../../../../clinical_dashboard/views/clinical_dashboard.dart';
import '../../../../new_result/data/model/result_profile_data_model.dart';

class UsbClinicalCalibrationScreen extends StatefulWidget {
  final bool isDeveloper;
  final ResultProfileDataModel profileDetails;
  const UsbClinicalCalibrationScreen({
    super.key,
    this.isDeveloper = false,
    required this.profileDetails,
  });

  @override
  State<UsbClinicalCalibrationScreen> createState() =>
      _UsbClinicalCalibrationScreenState();
}

class _UsbClinicalCalibrationScreenState
    extends State<UsbClinicalCalibrationScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  int _completedSteps = 0;
  bool _navigatedToInhaleScreen = false;
  bool _isDisposed = false;
  bool _isPaused = false;

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
  late StreamSubscription<String> _usbDataSubscription;
  final ClinicalUsbCommunicationServices _usbService =
      ClinicalUsbCommunicationServices();
  bool _isConnected = false;
  bool _dialogShown = false;

  String? loginId;
  String? profileId;
  Color profileColor = const Color(0xFF99E37F);
  bool signalsAlreadySent = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimationController();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted && _usbService.isConnected) {
        setState(() {
          _isConnected = true;
          _getUserId();
          _loadProfileColor();
          _initializeUsbConnection();
          _startProgress();
          if (!signalsAlreadySent) {
            _sendStepSpecificData(1);
            signalsAlreadySent = true;
          }
        });
      } else {
        _handleDisconnection();
      }
    });
  }

  void _handleConnectivityChanged(bool hasInternet) {
    setState(() {
      _isPaused = !hasInternet;
    });
    if (_isPaused) {
      _pauseProcesses();
    } else {
      _resumeProcesses();
    }
  }

  void _pauseProcesses() {
    if (!_isDisposed) {
      _animationController.stop();
      _usbService.pauseCommunication(); // Implement this in your service
      _audioHelper.stopAudio();
    }
  }

  void _resumeProcesses() {
    if (!_isDisposed && _isConnected) {
      _animationController.repeat();
      _usbService.resumeCommunication(); // Implement this in your service
      if (!_navigatedToInhaleScreen) {
        _startProgress();
      }
    }
  }

  void _handleDisconnection() {
    if (_dialogShown || !(ModalRoute.of(context)?.isCurrent ?? false)) return;

    _dialogShown = true;
    showDeviceDisconnectedBox(
      context: context,
      onButtonPressed: () async {
        Get.back();
        await Future.delayed(const Duration(milliseconds: 300));
        _exitToDashboard();
      },
    );
  }

  Future<void> _exitToDashboard() async {
    _stopAllProcesses();
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

  Future<void> _getUserId() async {
    final prefs = await SharedPreferences.getInstance();

    loginId = prefs.getString('userLoginId');
    profileId = prefs.getString('userProfileId');
  }

  // Method to load profile color from GetStorage
  void _loadProfileColor() {
    final storage = GetStorage();
    final String? profileColorHex = storage.read(
      GetStoredDataText.isProfileColorChanged,
    );

    // If profile color is available, convert from hex string to Color object
    if (profileColorHex != null) {
      setState(() {
        profileColor = Color(
          int.parse(profileColorHex, radix: 16),
        ).withAlpha(255);
      });
    }
  }

  void _initializeAnimationController() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    if (!_isPaused) {
      _animationController.repeat();
    }
  }

  void _initializeUsbConnection() {
    _usbService.setUsbSerialListener(
      onConnectionStatusChanged: (status) {
        bool isConnected = status == "connected";
        if (!mounted) return;

        setState(() {
          _isConnected = isConnected;
        });

        if (!_isConnected && !_isDisposed) {
          Future.delayed(const Duration(milliseconds: 500)).then((_) {
            if (!_isConnected) {
              _pauseProcesses();
              _handleDisconnection();
            }
          });
        }
      },
      onDataReceived: _onUsbDataReceived,
      onError: (onError) {
        if (mounted) {
          _showErrorDialog("USB Error: $onError");
        }
      },
    );

    _usbDataSubscription = _usbService.dataStream.listen((data) {
      if (!_usbService.isPaused) {
        _onUsbDataReceived(data);
      }
    });
  }

  void _onUsbDataReceived(String data) {
    if (!mounted || _isDisposed || _isPaused) return;

    if (data.contains("inhale") && !_navigatedToInhaleScreen) {
      if (mounted) {
        _stopAllProcesses();
        _navigateToInhaleScreen();
      }
    }
  }

  Future<void> _startProgress() async {
    for (int i = 1; i <= 5; i++) {
      if (_isPaused || _isDisposed || _navigatedToInhaleScreen) return;
      if (i < 5) {
        // Steps 0 to 4: Process normally for 20 seconds
        for (int seconds = 20; seconds > 0; seconds--) {
          if (_isPaused || _isDisposed || _navigatedToInhaleScreen) return;

          await Future.delayed(const Duration(seconds: 1));
          if (!mounted || _navigatedToInhaleScreen) return;
        }
      } else {
        // Step 5: Keep checking until "inhale" is received

        while (!_navigatedToInhaleScreen && !_isPaused) {
          await Future.delayed(const Duration(seconds: 1));

          if (_isDisposed || _navigatedToInhaleScreen) return;
        }
      }

      if (!_isDisposed && !_isPaused) {
        setState(() => _completedSteps = i);
        _restartAnimation();

        if (!signalsAlreadySent) {
          _sendStepSpecificData(1);
          signalsAlreadySent = true;
        }
      }
    }
  }

  Future<void> _sendStepSpecificData(int step) async {
    final prefs = await SharedPreferences.getInstance();
    String signal = prefs.getString("isFirstReading") ?? "{";
    try {
      switch (step) {
        case 1:
          await _usbService.sendData("?");
          await _usbService.sendData("}");
          await _usbService.sendData(signal);
          await _usbService.sendData("+");
          break;
      }
    } catch (e) {
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
    _usbDataSubscription.cancel();
    _animationController.stop();
  }

  void _navigateToInhaleScreen() {
    _navigatedToInhaleScreen = true;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) =>
                UsbClinicalInhaleScreen(profileDetails: widget.profileDetails),
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

        _abortProcess();
        await _setCancelOrDisconnectFlag();
        Navigator.pop(context);

        await Future.delayed(const Duration(milliseconds: 300));

        await _exitToDashboard();
      },
    );

    return didCancel;
  }

  Future<void> _setCancelOrDisconnectFlag() async {
    final storage = GetStorage();
    final DateTime now = DateTime.now();
    await storage.write('cancel_or_disconnect_time', now.toIso8601String());
  }

  void _abortProcess() {
    if (_isDisposed) return;

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

  @override
  void dispose() {
    _stopAllProcesses();
    _animationController.dispose();
    super.dispose();
  }

  PreferredSizeWidget? _buildAppBar() {
    if (!widget.isDeveloper) return null;

    return AppBar(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () {},
            child: Text(
              _isConnected
                  ? "Ble device connected"
                  : "Ble device not connected",
              style: GoogleFonts.mulish(
                fontSize: 15,
                color: _isConnected ? Colors.green : Colors.red,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _completedSteps++;
                _sendStepSpecificData(_completedSteps);
              });
            },
            child: const Text("Step +"),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator(int step, BuildContext context) {
    final bool isCurrentStep = _completedSteps == step;
    final bool isCompleted = _completedSteps > step;

    final double screenWidth = MediaQuery.of(context).size.width;
    final double circleSize = screenWidth * 0.06;
    final double lineWidth = screenWidth * 0.12;

    return Row(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            if (isCurrentStep)
              SizedBox(
                height: circleSize,
                width: circleSize,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColor.textLightColor,
                  ),
                  strokeWidth: 3.0,
                ),
              ),
            SvgPicture.asset(
              isCompleted ? "assets/verified.svg" : "assets/unverified.svg",
              height: circleSize,
              width: circleSize,
            ),
          ],
        ),
        if (step < 4)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            height: 4,
            width: lineWidth,
            decoration: BoxDecoration(
              color:
                  isCompleted
                      ? AppColor.buttonGreenColor
                      : const Color(0xFFE0E0E0),
              borderRadius: BorderRadius.circular(2),
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

    return InternetConnectivityHandler(
      onConnectivityChanged: _handleConnectivityChanged,
      onRetry: () async {
        await _exitToDashboard();
      },
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) async {
          if (!didPop) {
            // Handle cancel confirmation
            final shouldExit = await _showCancelTestDialog(context);

            if (shouldExit) {
              // ✅ Do NOT pop here. Directly navigate to dashboard (handled inside _handleCancelTest)
              // Keeps the flow clean, without popping twice
            }
          }
        },

        child: Scaffold(
          backgroundColor: AppColor.whiteColor,
          appBar: _buildAppBar(),
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
                  Image(
                    image: ResizeImage(
                      AssetImage(
                        _completedSteps > 4
                            ? calibrationGifs[4]
                            : calibrationGifs[_completedSteps],
                      ),
                      width: 200,
                      height: 200,
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
                      (index) => _buildProgressIndicator(index, context),
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.06),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
