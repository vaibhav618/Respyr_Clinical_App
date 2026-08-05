import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:respyr_clinical/clinical_app_respyr/screens/usb_test/screens/usb_clinical_inhale_screen.dart';
import 'package:respyr_clinical/clinical_app_respyr/screens/usb_test/services/clinical_usb_communication_services.dart';
import 'package:respyr_clinical/clinical_app_respyr/services/disconnected_error.dart';
import 'package:respyr_clinical/clinical_app_respyr/services/test_interruption_watcher.dart';
import 'package:respyr_clinical/widgets/internet_connectivity_check.dart';
import 'package:respyr_clinical/shared/audio_helper.dart';
import 'package:respyr_clinical/shared/colors.dart';
import 'package:respyr_clinical/shared/get_stored_data_text.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../new_result/data/model/result_profile_data_model.dart';
import '../../../../router/app_routers.dart';

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
    "Verifying Cleanliness",
    "Initiating Calibration",
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

  StreamSubscription<String>? _usbDataSubscription;

  final ClinicalUsbCommunicationServices _usbService =
  ClinicalUsbCommunicationServices();

  bool _isConnected = false;
  bool _dialogShown = false;

  String? loginId;
  String? profileId;
  Color profileColor = const Color(0xFF99E37F);

  // ✅ signal tracking
  bool signalsAlreadySent = false;

  // ✅ Retry / handshake variables (same as BLE flow)
  bool _handshakeDone = false; // once true => stop retry timer
  bool _awaitingPercentEcho = false;
  Timer? _percentEchoWindowTimer;
  Timer? _retryTimer;
  int elapsedSeconds = 0;

  /// Total time spent waiting for the device to reach the inhale stage,
  /// independent of the 60s retry cycle. Guarantees the screen can never hang
  /// silently forever — if the device never responds we surface it instead.
  int _totalWaitSeconds = 0;
  static const int _maxWaitSeconds = 90;
  bool _timeoutShown = false;

  /// Leaving the app mid-calibration desynchronises the subject from the
  /// device's prompts — see [TestInterruptionWatcher].
  late final TestInterruptionWatcher _interruptionWatcher =
      TestInterruptionWatcher(onInterrupted: _showTestInterrupted);
  bool _interruptionShown = false;

  @override
  void initState() {
    super.initState();
    _interruptionWatcher.start();
    _initializeAnimationController();

    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;

      if (_usbService.isConnected) {
        setState(() {
          _isConnected = true;
        });

        _getUserId();
        _loadProfileColor();
        _initializeUsbConnection();

        _startProgress();
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
    if (_isDisposed) return;

    _animationController.stop();
    _usbService.pauseCommunication();
    _audioHelper.stopAudio();

    // ✅ stop timers when screen paused
    _retryTimer?.cancel();
    _retryTimer = null;
    _percentEchoWindowTimer?.cancel();
    _percentEchoWindowTimer = null;
  }

  void _resumeProcesses() {
    if (_isDisposed || !_isConnected) return;

    _animationController.repeat();
    _usbService.resumeCommunication();

    if (!_navigatedToInhaleScreen) {
      _startProgress();
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
    // Stamp the abort so the dashboard holds the next test back until the
    // device has finished the cycle this one left it in. Bluetooth already did
    // this; USB did not, so leaving calibration let the user start again
    // straight away and land in a hung calibration.
    await _setCancelOrDisconnectFlag();
    if (mounted) {
      _navigateToDashboard();
    }
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

  Future<void> _getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    loginId = prefs.getString('userLoginId');
    profileId = prefs.getString('userProfileId');
  }

  void _loadProfileColor() {
    final storage = GetStorage();
    final String? profileColorHex = storage.read(
      GetStoredDataText.isProfileColorChanged,
    );

    if (profileColorHex != null) {
      setState(() {
        profileColor = Color(int.parse(profileColorHex, radix: 16))
            .withAlpha(255);
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

        // Device came back after a drop: make sure the handshake timer is
        // running again. Without this a momentary disconnect left calibration
        // permanently stalled.
        if (_isConnected &&
            !_isDisposed &&
            !_navigatedToInhaleScreen &&
            !_handshakeDone &&
            _retryTimer == null) {
          debugPrint("🔌 USB reconnected — restarting calibration handshake");
          _restartCalibration();
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

  void _onUsbDataReceived(String data) async {
    if (!mounted || _isDisposed || _isPaused) return;

    // ✅ SAME AS BLE:
    // If we sent "%" to check handshake, and we receive "%" back
    // => initial signal NOT received in device, so resend initial signals.
    if (data.contains("%") &&
        !_navigatedToInhaleScreen &&
        _awaitingPercentEcho &&
        !_handshakeDone) {
      _awaitingPercentEcho = false;
      _percentEchoWindowTimer?.cancel();
      _percentEchoWindowTimer = null;

      debugPrint("⚠️ USB echoed '%' back => resending initial signals");
      await _sendInitialSignal(force: true);
      return;
    }

    if (data.contains("inhale") && !_navigatedToInhaleScreen) {
      _stopAllProcesses();
      _navigateToInhaleScreen();
      return;
    }
  }

  // ✅ NEW: send signal at start, supports force resend like BLE
  Future<void> _sendInitialSignal({bool force = false}) async {
    if (_isDisposed || _isPaused) return;
    if (_handshakeDone && !force) return;
    if (!force && signalsAlreadySent) return;
    if (!_usbService.isConnected) return;

    final prefs = await SharedPreferences.getInstance();
    final String signal = prefs.getString("isFirstReading") ?? "{";

    debugPrint("🚀 USB Sending initial signal: $signal (force=$force)");

    if (force) {
      signalsAlreadySent = false;
    }

    await _usbService.sendData("?");
    await Future.delayed(const Duration(seconds: 2));
    await _usbService.sendData("}");
    await Future.delayed(const Duration(seconds: 2));
    await _usbService.sendData(signal);
    await Future.delayed(const Duration(seconds: 2));
    await _usbService.sendData("+");

    signalsAlreadySent = true;

    // ✅ Start retry timer once; on force resend reset counters
    if (_retryTimer == null) {
      startWaitTimer();
    } else if (force) {
      elapsedSeconds = 0;
      _awaitingPercentEcho = false;
      _percentEchoWindowTimer?.cancel();
      _percentEchoWindowTimer = null;
      _handshakeDone = false;
    }
  }

  Future<void> _startProgress() async {
    if (_isPaused || _isDisposed || _navigatedToInhaleScreen) return;

    // ✅ Send initial signal immediately
    await _sendInitialSignal();

    for (int i = 1; i <= 5; i++) {
      if (_isPaused || _isDisposed || _navigatedToInhaleScreen) return;

      // ✅ keep your old retry behavior as well
      if (!signalsAlreadySent) {
        await _sendInitialSignal();
      }

      if (i < 5) {
        for (int seconds = 20; seconds > 0; seconds--) {
          if (_isPaused || _isDisposed || _navigatedToInhaleScreen) return;
          await Future.delayed(const Duration(seconds: 1));
          if (!mounted || _navigatedToInhaleScreen) return;
        }
      } else {
        while (!_navigatedToInhaleScreen && !_isPaused) {
          await Future.delayed(const Duration(seconds: 1));
          if (_isDisposed || _navigatedToInhaleScreen) return;
        }
      }

      if (!_isDisposed && !_isPaused) {
        setState(() => _completedSteps = i);
        _restartAnimation();
      }
    }
  }

  // ✅ SAME AS BLE:
  // - counts seconds
  // - at 20s sends "%"
  // - if "%" not echoed in 3s => handshake success => stop retry timer
  void startWaitTimer() {
    _retryTimer?.cancel();
    elapsedSeconds = 0;
    _handshakeDone = false;
    _awaitingPercentEcho = false;
    _percentEchoWindowTimer?.cancel();
    _percentEchoWindowTimer = null;

    _retryTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      // Terminal conditions only — these mean the screen is finished with.
      if (_isDisposed || _navigatedToInhaleScreen) {
        timer.cancel();
        _retryTimer = null;
        return;
      }

      // Transient conditions: a momentary USB drop or a pause must NOT kill
      // the timer. Cancelling here left the screen hung forever, because
      // nothing restarted it once the device came back.
      if (_isPaused || !_usbService.isConnected) {
        return;
      }

      elapsedSeconds++;
      _totalWaitSeconds++;
      debugPrint("⏱️ USB Completed Seconds: $elapsedSeconds");

      // Safety net: never let the user stare at a frozen calibration screen.
      if (_totalWaitSeconds >= _maxWaitSeconds &&
          !_handshakeDone &&
          !_timeoutShown) {
        _timeoutShown = true;
        timer.cancel();
        _retryTimer = null;
        debugPrint("⛔ USB calibration timed out after $_totalWaitSeconds s");
        _showCalibrationTimeout();
        return;
      }

      if (elapsedSeconds == 20 && !_handshakeDone) {
        _awaitingPercentEcho = true;

        debugPrint("📤 USB Sending '%' to validate initial signals");
        await _usbService.sendData("%");

        _percentEchoWindowTimer?.cancel();
        _percentEchoWindowTimer = Timer(const Duration(seconds: 3), () {
          if (_isDisposed || _isPaused || _navigatedToInhaleScreen) return;

          // If still awaiting echo => no echo came => success
          if (_awaitingPercentEcho && !_handshakeDone) {
            _awaitingPercentEcho = false;
            _handshakeDone = true;

            debugPrint(
                "✅ USB '%' not echoed back => handshake success. Stop retry timer.");

            _retryTimer?.cancel();
            _retryTimer = null;
          }
        });
      }

      if (elapsedSeconds >= 60 && !_handshakeDone) {
        elapsedSeconds = 0;
      }
    });
  }

  // ✅ KEEP SAME: developer Step + button uses this old method
  Future<void> _sendStepSpecificData(int step) async {
    final prefs = await SharedPreferences.getInstance();
    String signal = prefs.getString("isFirstReading") ?? "{";

    try {
      print("signal :$signal");

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

  /// Shown when the device never reaches the inhale stage within
  /// [_maxWaitSeconds]. Previously the screen simply hung with no feedback.
  void _showCalibrationTimeout() {
    if (_isDisposed || !mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Device not responding"),
        content: const Text(
          "The device didn't finish getting ready. Check that it is properly "
          "connected, then try again.",
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _exitToDashboard();
            },
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _restartCalibration();
            },
            child: const Text("Retry"),
          ),
        ],
      ),
    );
  }

  /// The user left the app part-way through the test. The device keeps running
  /// its own sequence meanwhile, so by the time they return they have missed
  /// the inhale cue and the reading can no longer be valid.
  ///
  /// The only way out is the dashboard. Re-entering the flow from here would
  /// leave the device still in reading mode — it ignores the fresh signals and
  /// the user lands on the same dead end. Starting a new test from the
  /// dashboard re-runs the connect handshake ("!"), which is what actually
  /// resets the device.
  void _showTestInterrupted() {
    if (_isDisposed || !mounted || _interruptionShown) return;
    if (_navigatedToInhaleScreen) return;
    _interruptionShown = true;

    _pauseProcesses();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Test cancelled"),
        content: const Text(
          "You left the app while the test was running, so this reading has "
          "been cancelled. Please start the test again from the beginning.",
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              // Await: navigation tears the screen down, and the abort has to
              // reach the device before that happens.
              await _abortProcess();
              await _exitToDashboard();
            },
            child: const Text("Back to dashboard"),
          ),
        ],
      ),
    );
  }

  /// Full restart of the handshake after a timeout: clears the retry state and
  /// re-sends the initial signals from scratch.
  Future<void> _restartCalibration() async {
    if (_isDisposed) return;
    _timeoutShown = false;
    _totalWaitSeconds = 0;
    elapsedSeconds = 0;
    _handshakeDone = false;
    _awaitingPercentEcho = false;
    signalsAlreadySent = false;
    _percentEchoWindowTimer?.cancel();
    _percentEchoWindowTimer = null;
    await _sendInitialSignal(force: true);
  }

  void _showErrorDialog(String message) {
    if (_isDisposed) return;
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
    _usbDataSubscription?.cancel();
    _animationController.stop();

    // ✅ stop timers (important)
    _retryTimer?.cancel();
    _retryTimer = null;

    _percentEchoWindowTimer?.cancel();
    _percentEchoWindowTimer = null;
  }

  void _navigateToInhaleScreen() {
    _navigatedToInhaleScreen = true;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
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

  /// Not gated on [_isDisposed]: the interruption and cancel paths tear the
  /// screen down around this call, and skipping the abort leaves the device
  /// running its cycle — which is what strands the next test in calibration.
  Future<void> _abortProcess() async {
    debugPrint("🛑 Aborting calibration...");
    debugPrint("USB connected: $_isConnected");

    try {
      if (_isConnected) {
        // force: paused USB comms must not swallow the abort.
        final sent = await _usbService.sendData("&", force: true);
        debugPrint(
          sent ? "✅ Sent '&' to abort process" : "❌ '&' was NOT written",
        );
      } else {
        debugPrint("⚠️ Device not connected, cannot send '&'");
      }
    } catch (e) {
      debugPrint("❌ Failed to send '&': $e");
    }
  }

  @override
  void dispose() {
    _interruptionWatcher.stop();
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
              _isConnected ? "USB device connected" : "USB device not connected",
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
              color: isCompleted
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
            await _showCancelTestDialog(context);
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
