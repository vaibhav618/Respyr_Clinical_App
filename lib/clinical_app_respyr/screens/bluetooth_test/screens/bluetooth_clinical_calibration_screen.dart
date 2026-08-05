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
import 'package:respyr_clinical/clinical_app_respyr/services/test_interruption_watcher.dart';
import 'package:respyr_clinical/shared/audio_helper.dart';
import 'package:respyr_clinical/shared/colors.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  bool _inhaleReceived = false;
  bool _isDisposed = false;
  bool _isDisconnectDialogPop = false;
  bool _hasShownDisconnectedDialog = false;

  // ✅ prevents attaching listeners multiple times
  bool _listenersAttached = false;

  final AudioHelper _audioHelper = AudioHelper();

  bool allSignalSent = false;

  Timer? _timer;
  bool timerStarted = false;

  // ✅ Retry / handshake variables
  bool _handshakeDone = false; // once true => stop retry timer
  bool _awaitingPercentEcho = false;
  Timer? _percentEchoWindowTimer;

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

  @override
  void initState() {
    super.initState();

    _interruptionWatcher.start();
    _isConnected = _bleManager.isConnected;

    _initializeAnimationController();
    _attachListenersOnce();

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

  void _attachListenersOnce() {
    if (_listenersAttached) return;
    _listenersAttached = true;

    _connectionStatusSubscription =
        _bleManager.connectionStatusStream.listen((isConnected) {
          if (_isDisposed) return;

          _isConnected = isConnected;
          if (mounted) setState(() {});

          if (isConnected) {
            _hasShownDisconnectedDialog = false;
            _isDisconnectDialogPop = false;

            // Device came back after a drop: make sure the handshake timer is
            // running again. Without this a momentary disconnect left
            // calibration permanently stalled.
            if (!_navigatedToInhaleScreen &&
                !_inhaleReceived &&
                !_handshakeDone &&
                _timer == null) {
              debugPrint("🔌 BLE reconnected — restarting calibration handshake");
              _restartCalibration();
            }
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
          (data) async {
        if (_isDisposed) return;

        // ✅ handshake echo case: if we sent "%" and device echoes back "%"
        if (data.contains("%") &&
            !_inhaleReceived &&
            !_navigatedToInhaleScreen &&
            _awaitingPercentEcho &&
            !_handshakeDone) {
          _awaitingPercentEcho = false;
          _percentEchoWindowTimer?.cancel();
          _percentEchoWindowTimer = null;

          if (kDebugMode) {
            debugPrint("⚠️ Device echoed '%' back => resending initial signals");
          }

          await _sendInitialSignal(force: true);
          return;
        }

        // ✅ inhale received -> go next ONLY ONCE
        if (data.contains("inhale") && !_navigatedToInhaleScreen) {
          _inhaleReceived = true;

          // stop listening before navigation
          _stopAllProcesses();

          if (mounted) _navigateToInhaleScreen();
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
    await _sendInitialSignal();

    for (int i = 1; i <= 5; i++) {
      if (_isDisposed || _navigatedToInhaleScreen) return;

      if (i < 5) {
        for (int seconds = 20; seconds > 0; seconds--) {
          if (_isDisposed || _navigatedToInhaleScreen) return;
          await Future.delayed(const Duration(seconds: 1));
          if (!mounted || _navigatedToInhaleScreen || _isDisposed) return;
        }
      } else {
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

  Future<void> _sendInitialSignal({bool force = false}) async {
    if (_handshakeDone && !force) return;
    if (!force && allSignalSent) return;
    if (_navigatedToInhaleScreen) return;
    if (!_bleManager.isConnected) return;
    if (_isDisposed) return;

    final prefs = await SharedPreferences.getInstance();
    final String signal = prefs.getString("isFirstReading") ?? "{";

    if (_isDisposed || _navigatedToInhaleScreen) return;

    if (kDebugMode) {
      print("🚀 Sending initial signal: $signal (force=$force)");
    }

    if (force) {
      allSignalSent = false;
    }

    await _bleManager.sendData("?");
    await Future.delayed(const Duration(seconds: 2));
    if (_isDisposed || _navigatedToInhaleScreen) return;

    await _bleManager.sendData("}");
    await Future.delayed(const Duration(seconds: 2));
    if (_isDisposed || _navigatedToInhaleScreen) return;

    await _bleManager.sendData(signal);
    await Future.delayed(const Duration(seconds: 2));
    if (_isDisposed || _navigatedToInhaleScreen) return;

    await _bleManager.sendData("+");

    allSignalSent = true;

    if (!timerStarted) {
      startWaitTimer();
      timerStarted = true;
    } else if (force) {
      elapsedSeconds = 0;
      _awaitingPercentEcho = false;
      _percentEchoWindowTimer?.cancel();
      _percentEchoWindowTimer = null;
    }
  }

  Future<void> _sendStepSpecificData(int step) async {
    try {
      if (_isDisposed) return;

      if (!allSignalSent) {
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

  void startWaitTimer() {
    _timer?.cancel();
    elapsedSeconds = 0;
    _handshakeDone = false;
    _awaitingPercentEcho = false;
    _percentEchoWindowTimer?.cancel();
    _percentEchoWindowTimer = null;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      // Terminal conditions only — these mean the screen is finished with.
      if (_isDisposed || _inhaleReceived || _navigatedToInhaleScreen) {
        timer.cancel();
        _timer = null;
        return;
      }

      // A momentary BLE drop must NOT kill the timer: cancelling here left
      // calibration hung forever, since nothing restarted it on reconnect.
      if (!_bleManager.isConnected) {
        return;
      }

      elapsedSeconds++;
      _totalWaitSeconds++;
      debugPrint("⏱️ Completed Seconds: $elapsedSeconds");

      // Safety net: never let the user stare at a frozen calibration screen.
      if (_totalWaitSeconds >= _maxWaitSeconds &&
          !_handshakeDone &&
          !_timeoutShown) {
        _timeoutShown = true;
        timer.cancel();
        _timer = null;
        debugPrint("⛔ BLE calibration timed out after $_totalWaitSeconds s");
        _showCalibrationTimeout();
        return;
      }

      if (elapsedSeconds == 20 && !_handshakeDone) {
        _awaitingPercentEcho = true;

        if (kDebugMode) {
          debugPrint("📤 Sending '%' to validate initial signals");
        }

        await _bleManager.sendData("%");

        _percentEchoWindowTimer?.cancel();
        _percentEchoWindowTimer = Timer(const Duration(seconds: 3), () {
          if (_isDisposed) return;
          if (_navigatedToInhaleScreen) return;

          if (_awaitingPercentEcho && !_handshakeDone) {
            _awaitingPercentEcho = false;
            _handshakeDone = true;

            if (kDebugMode) {
              debugPrint(
                "✅ '%' not echoed back => handshake success. Stop retry timer.",
              );
            }

            _timer?.cancel();
            _timer = null;
          }
        });
      }

      if (elapsedSeconds >= 60 && !_handshakeDone) {
        elapsedSeconds = 0;
      }
    });
  }

  void _restartAnimation() {
    if (_isDisposed) return;
    _animationController
      ..reset()
      ..repeat();
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
          "The device didn't finish getting ready. Check that it is switched "
          "on and nearby, then try again.",
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
  /// dashboard re-runs the connect handshake, which is what actually resets
  /// the device.
  void _showTestInterrupted() {
    if (_isDisposed || !mounted || _interruptionShown) return;
    if (_navigatedToInhaleScreen) return;
    _interruptionShown = true;

    _timer?.cancel();
    _timer = null;
    _audioHelper.stopAudio();

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
            onPressed: () {
              Navigator.of(dialogContext).pop();
              abortProcess();
              _exitToDashboard();
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
    allSignalSent = false;
    _percentEchoWindowTimer?.cancel();
    _percentEchoWindowTimer = null;
    await _sendInitialSignal(force: true);
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
    _connectionStatusSubscription?.cancel();
    _connectionStatusSubscription = null;

    _receivedDataSubscription?.cancel();
    _receivedDataSubscription = null;

    _animationController.stop();
    _audioHelper.stopAudio();

    _timer?.cancel();
    _timer = null;

    _percentEchoWindowTimer?.cancel();
    _percentEchoWindowTimer = null;
  }

  void _navigateToInhaleScreen() {
    if (_navigatedToInhaleScreen) return;
    _navigatedToInhaleScreen = true;

    // ✅ replace route so calibration is disposed (no background listeners)
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) =>
            BluetoothInhaleScreen(profileDetails: widget.profileDetails),
      ),
    );
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
      arguments: {'profile_details': widget.profileDetails},
    );
  }

  void abortProcess() {
    if (_isConnected) {
      _bleManager.sendData("&");
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _interruptionWatcher.stop();
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
