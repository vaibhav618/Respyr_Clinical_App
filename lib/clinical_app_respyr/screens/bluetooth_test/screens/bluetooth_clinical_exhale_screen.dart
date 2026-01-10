import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:respyr_clinical/clinical_app_respyr/screens/bluetooth_test/screens/bluetooth_clinical_generating_screen.dart';
import 'package:respyr_clinical/clinical_app_respyr/screens/bluetooth_test/services/clinical_bluetooth_manager.dart';
import 'package:respyr_clinical/clinical_app_respyr/services/disconnected_error.dart';
import 'package:respyr_clinical/shared/audio_helper.dart';
import 'package:respyr_clinical/shared/colors.dart';
import '../../../../new_result/data/model/result_profile_data_model.dart';
import '../../../../router/app_routers.dart';

class BluetoothExhaleScreen extends StatefulWidget {
  final String baseValue;
  final bool isDeveloper;
  final ResultProfileDataModel profileDetails;
  const BluetoothExhaleScreen({
    super.key,
    required this.baseValue,
    this.isDeveloper = false,
    required this.profileDetails,
  });

  @override
  State<BluetoothExhaleScreen> createState() => _BluetoothExhaleScreenState();
}

class _BluetoothExhaleScreenState extends State<BluetoothExhaleScreen> {
  double progress = 0.0;
  final ClinicalBluetoothManager _bleManager = ClinicalBluetoothManager();
  late StreamSubscription<bool> _connectionStatusSubscription;
  late StreamSubscription<String> _receivedDataSubscription;
  bool _isConnected = false;
  bool _isDisconnectDialogPop = false;
  bool _hasShownDisconnectedDialog = false;
  bool _isDisposed = false;
  late DummyBluetoothBlowPressure _blowProcessor;
  double? thresholdPercentage;
  Timer? _counterTimeDown;
  int _secondsRemaining = 30;


  final storage = GetStorage();

  final AudioHelper _audioHelper = AudioHelper();

  @override
  void initState() {
    super.initState();
    _isConnected = _bleManager.isConnected;
    _blowProcessor = DummyBluetoothBlowPressure();
    _blowProcessor.processBlowData(
      widget.baseValue,
      _bleManager,
      context,
      widget.profileDetails,
    );

    _startCountdownTimer();
    _checkBluetoothDeviceConnectivity();
  }

  void _startCountdownTimer() {
    if (!_isConnected) return;
    _counterTimeDown = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        _counterTimeDown?.cancel();
        _showExhaledTimeoutDialog();
      }
    });
  }

  // Method to show a dialog box for primary profile deletion attempt
  void _showExhaledTimeoutDialog() async {
    if (_isDisconnectDialogPop) return;
    _counterTimeDown?.cancel();

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: AppColor.whiteColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              20,
            ), // Rounded corners for the dialog
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Exhale Session Timed Out!',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFEA5455),
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                Text(
                  'Please start the test procedure from the beginning.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: AppColor.textLightColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                Text(
                  'Note: Will be redirect to dashboard screen, your food data will be stored securely in our database.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.mulish(
                    color: AppColor.textLightColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w400,
                  ),
                ),

                SizedBox(height: MediaQuery.of(context).size.height * 0.01),
                const Divider(),
                // Action buttons
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.045,
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _setCancelOrDisconnectFlag();
                      abortProcess();
                      _navigateToDashboard();
                    },
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.all(
                        Colors.transparent,
                      ), // Default background
                      foregroundColor: WidgetStateProperty.all(
                        AppColor.primaryBlackColor,
                      ), // Default text color
                      overlayColor: WidgetStateProperty.resolveWith<Color?>((
                        Set<WidgetState> states,
                      ) {
                        if (states.contains(WidgetState.pressed)) {
                          return Colors.blue.withAlpha(
                            47,
                          ); // Background color when pressed
                        }
                        if (states.contains(WidgetState.hovered)) {
                          return Colors.blue.withAlpha(
                            26,
                          ); // Background color on hover
                        }
                        return null; // Default transparent
                      }),
                    ),
                    child: Text(
                      'OK',
                      style: GoogleFonts.mulish(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color:
                            AppColor.primaryBlackColor, // Logout button color
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
        _setCancelOrDisconnectFlag();
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



  void _handleDisconnection() {
    if (_isDisposed ||
        _isConnected ||
        _isDisconnectDialogPop ||
        _hasShownDisconnectedDialog) {
      return;
    }

    _counterTimeDown?.cancel(); // ✅ Cancel countdown to prevent timeout dialog
    _counterTimeDown = null;
    _isDisconnectDialogPop = true;
    _hasShownDisconnectedDialog = true;

    showDeviceDisconnectedBox(
      context: context,
      onButtonPressed: () async {
        _isDisconnectDialogPop = false;
        Navigator.pop(context);
        await Future.delayed(const Duration(milliseconds: 300));
        _setCancelOrDisconnectFlag();
        abortProcess();
        _navigateToDashboard(); // Attempt reconnect
      },
    );
  }

  void _checkBluetoothDeviceConnectivity() {
    _connectionStatusSubscription = _bleManager.connectionStatusStream.listen((
      isConnected,
    ) {
      if (kDebugMode) {
        print("BLE Connection Status Changed: $isConnected");
      }

      if (_isDisposed) return;

      setState(() => _isConnected = isConnected);

      if (isConnected) {
        _isDisconnectDialogPop = false;
        _hasShownDisconnectedDialog = false;
      }

      if (!isConnected &&
          !_isDisposed &&
          !_isDisconnectDialogPop &&
          !_hasShownDisconnectedDialog) {
        _counterTimeDown?.cancel();
        _counterTimeDown = null;

        Future.delayed(const Duration(milliseconds: 500)).then((_) {
          if (!_isConnected) {
            // Double-check before showing the dialog

            _setCancelOrDisconnectFlag();

            _audioHelper.stopAudio();
            _handleDisconnection();
          }
        });
      }
      _hasShownDisconnectedDialog = false;
    }, onError: (error) => _showErrorDialog("Connection status error."));

    _audioHelper.playExhaleAudio();
    // Handle received data
    _receivedDataSubscription = _bleManager.receivedDataStream.listen(
      (data) {
        _receivedDataSubscriptionHandler(data);

        if (data.contains("analize")) {
          if (mounted) {
            _stopAllProcesses();
          }
        }
      },
      onError: (error) => _showErrorDialog("Error receiving data from device."),
    );
  }

  void _receivedDataSubscriptionHandler(String data) {
    if (kDebugMode) {
      print("New Data Received ExhaleScreen: $data");
    }

    // Process data using BlowProcessor
    _blowProcessor.processBlowData(
      data,
      _bleManager,
      context,
      widget.profileDetails,
    );

    // Update progress bar and UI text based on BlowProcessor state
    if (_blowProcessor.isBlown) {
      setState(() {
        progress = (_blowProcessor.blowP ?? 0) / 100.0; // Normalize to 0-1
      });

      // ❌ Do not reset the countdown if the user has already exhaled
      if (_secondsRemaining > 0) {
        _counterTimeDown?.cancel();
        _counterTimeDown = null;
      }
    }
  }

  void _stopAllProcesses() {
    _isDisposed = true;
    _connectionStatusSubscription.cancel();
    _receivedDataSubscription.cancel();
  }

  void _showErrorDialog(String message) {
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

  void stopExhale() {
    if (_isConnected) {
      _bleManager.sendData("/");
    }
  }

  @override
  void dispose() {
    _counterTimeDown?.cancel();
    _stopAllProcesses();
    super.dispose();
  }

  PreferredSizeWidget? _buildAppBar() {
    if (!widget.isDeveloper) return null;

    return AppBar(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () {},
            child:
                _isConnected
                    ? Text(
                      "Ble device connected",
                      style: GoogleFonts.mulish(
                        fontSize: 15,
                        color: Colors.green,
                      ),
                    )
                    : Text(
                      "Ble device not connected",
                      style: GoogleFonts.mulish(
                        fontSize: 15,
                        color: Colors.red,
                      ),
                    ),
          ),
          ElevatedButton(
            onPressed: () {
              stopExhale();
            },
            child: const Text("Stop Exhale"),
          ),
        ],
      ),
      automaticallyImplyLeading: false,
    );
  }

  Future<void> _setCancelOrDisconnectFlag() async {
    final storage = GetStorage();
    final DateTime now = DateTime.now();
    await storage.write('cancel_or_disconnect_time', now.toIso8601String());
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: AppColor.whiteColor,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    final width = MediaQuery.of(context).size.width;

    // Function to get the color based on progress
    Color getColor() {
      double threshold = thresholdPercentage! / 120;

      if (progress >= 0.0 && progress < 0.10 && progress < threshold) {
        return const Color(0xFFD9D9D9); // Gray
      } else if (progress >= 0.10 && progress < threshold) {
        return const Color(0xFFEA5455); // Red
      } else {
        return const Color(0xFF3FAF58); // Green
      }
    }

    // Function to get the text based on progress
    String getText() {
      double threshold = thresholdPercentage! / 120;

      if (progress >= 0.0 && progress < 0.10 && progress < threshold) {
        return 'Start Exhaling...';
      } else if (progress >= 0.10 && progress < threshold) {
        return 'Exhale Harder';
      } else {
        return 'Keep Exhaling';
      }
    }

    double threBaseVal = _blowProcessor.blowThresholdValue!;

    thresholdPercentage = Thresholds.calculateThresholdPercentage(threBaseVal);


    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColor.whiteColor,
        appBar: _buildAppBar(),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Stack(
                  children: [
                    SizedBox(
                      height: 350,
                      width: MediaQuery.of(context).size.width * 0.96,
                      child: Image.asset('assets/gif_images/exhale.gif'),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            onPressed: () => _showCancelTestDialog(context),
                            icon: Container(
                              height: 20,
                              width: 20,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(5),
                                color: AppColor.whiteColor,
                              ),
                              child: SvgPicture.asset(
                                "assets/svg_icons/close_icon.svg",
                              ),
                            ),
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
                          // BatteryUtils.batteryIndicatorWidget(
                          //   batteryPercentage,
                          // ),
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
                    ),
                    if (progress > 0.2 && progress < 0.49)
                      Positioned(
                        bottom: 50,
                        left: width * 0.09,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 15,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(25),
                            color: AppColor.whiteColor,
                          ),
                          child: Row(
                            children: [
                              Text(
                                "Having trouble with exhale?\t",
                                textAlign: TextAlign.center,
                                style: GoogleFonts.mulish(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColor.textLightColor,
                                ),
                              ),
                              InkWell(
                                onTap: () {},
                                child: Text(
                                  "Try practice test",
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.mulish(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColor.primaryBlueColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: GoogleFonts.mulish(
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                        color: AppColor.textLightColor,
                      ),
                      children: [
                        const TextSpan(
                          text: "Exhale into device until scale turns\t",
                        ),
                        TextSpan(
                          text: "GREEN",
                          style: GoogleFonts.mulish(
                            color: const Color(0xFF3EAF58),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      // Isolated Progress Bar Update
                      StatefulBuilder(
                        builder: (context, setState) {
                          return Stack(
                            children: [
                              SizedBox(
                                width: width,
                                height: 60,
                                child: LinearProgressIndicator(
                                  value: progress,
                                  backgroundColor: const Color(0xFFF3F3F3),
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    getColor(),
                                  ),
                                ),
                              ),
                              Positioned(
                                right: width * 0.05,
                                top: 10,
                                child: SvgPicture.asset(
                                  "assets/svg_icons/take_test.svg",
                                  colorFilter: ColorFilter.mode(
                                    progress >= 0.75
                                        ? AppColor.whiteColor
                                        : AppColor.textLightColor,
                                    BlendMode.srcIn,
                                  ),
                                ),
                              ),
                              Positioned(
                                left: (thresholdPercentage! / 120) * width,
                                top: 0,
                                bottom: 0,
                                child: Container(width: 2, color: Colors.black),
                              ),
                            ],
                          );
                        },
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Poor Pressure",
                              style: GoogleFonts.mulish(
                                fontSize: 12,
                                color: const Color(0xFFA1A1A1),
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            Text(
                              "Good Pressure",
                              style: GoogleFonts.mulish(
                                fontSize: 12,
                                color: const Color(0xFFA1A1A1),
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  getText(),
                  style: GoogleFonts.poppins(
                    fontSize: 25,
                    color: getColor(),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        _secondsRemaining.toString(),
                        style: GoogleFonts.roboto(
                          fontSize: 40,
                          fontWeight: FontWeight.w400,
                          color:
                              _secondsRemaining <= 10
                                  ? Colors.red
                                  : AppColor.primaryBlackColor,
                        ),
                      ),
                      Text(
                        'sec',
                        style: GoogleFonts.roboto(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color:
                              _secondsRemaining <= 10
                                  ? Colors.red
                                  : AppColor.primaryBlackColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class Thresholds {
  static const double blowThreshold = 5.0;
  static const double abortDifference = 1500;

  static double calculateThresholdPercentage(double baseValue) {
    double valueThreshold = baseValue + blowThreshold;
    double valueDiff = valueThreshold - baseValue;
    return (valueDiff / (valueDiff * 2)) * 100;
  }

  static double calculateBlowPercentage(double baseValue, double blowValue) {
    double valueThreshold = baseValue + blowThreshold;
    double valueDiff1 = valueThreshold - blowValue;
    valueDiff1 = blowThreshold - valueDiff1;
    double valueDiff = valueThreshold - baseValue;
    return (valueDiff1 / (valueDiff * 2)) * 100;
  }
}

class DummyBluetoothBlowPressure {
  double? blowBaseValue;
  double? blowThresholdValue;
  double? blowP;
  bool isBaseValueCaptured = false;
  bool isBlowThresholdSet = false;
  bool firstDataValueCaptured = false;
  bool perfectBlowValueCaptured = false;
  bool isBlown = false;
  bool isBlownInFresher = false;
  bool isBlowStartTimeCaptured = false;
  bool isAbort = false;
  bool diffTStampFlag = false;
  bool moveToResults = false;
  bool isImproperBlow = false;

  double? firstDataValue;
  double? finalBlowValue;
  double? thresholdPercentage;

  int? blowStartTime;
  int? diffTStamp;
  int? diffTStampCurrent;

  List<double> blowValuesList = [];
  List<double> baseBlowValueList = [];

  Future<void> _setCancelOrDisconnectFlag() async {
    final storage = GetStorage();
    final DateTime now = DateTime.now();
    await storage.write('cancel_or_disconnect_time', now.toIso8601String());
  }

  void processBlowData(
    String data,
    ClinicalBluetoothManager bleManager,
    BuildContext context,
    ResultProfileDataModel profileDetails,
  ) {
    final baseValueRegex = RegExp(r'/([0-9.]+)/');
    final blowValueRegex = RegExp(r'\{([0-9.]+)\}');

    final baseValueMatch = baseValueRegex.firstMatch(data);
    final blowValueMatch = blowValueRegex.firstMatch(data);

    if (baseValueMatch != null) {
      // Extract base value
      blowBaseValue = double.parse(baseValueMatch.group(1)!);
      blowThresholdValue = blowBaseValue! + 20;
      isBaseValueCaptured = true;

      if (!isBlowThresholdSet) {
        thresholdPercentage = Thresholds.calculateThresholdPercentage(
          blowBaseValue!,
        );
      }
    } else if (blowValueMatch != null) {
      if (isBaseValueCaptured) {
        // Retrieve blow value
        double blowValue = double.parse(blowValueMatch.group(1)!);

        // Capture first data
        if (!firstDataValueCaptured) {
          firstDataValue = blowValue;
          firstDataValueCaptured = true;
        }

        // Ensure no inhale progress
        if (blowValue < firstDataValue!) {
          blowValue = firstDataValue!;
        }

        // Calculate blow progress
        blowP = Thresholds.calculateBlowPercentage(blowBaseValue!, blowValue);

        if (blowP! > 10) {
          isBlown = true;
        }

        // Handle exhale harder
        if (blowP! > 10 && blowP! < thresholdPercentage!) {
          if (blowP! >= 10) {
            isBlownInFresher = true;
          }
        } else if (blowP! >= thresholdPercentage!) {
          perfectBlowValueCaptured = true;

          if (!isBlowStartTimeCaptured) {
            blowStartTime = DateTime.now().millisecondsSinceEpoch;
            isBlowStartTimeCaptured = true;
          }

          int currentTime = DateTime.now().millisecondsSinceEpoch;
          int futureTime = currentTime - blowStartTime!;

          if (futureTime >= 500 && futureTime <= 5000) {
            finalBlowValue = blowValue;
          }

          if (futureTime <= 1500) {
            blowValuesList.add(blowValue);
          }
        }

        if (blowP! < thresholdPercentage!) {
          if (perfectBlowValueCaptured && isBlown) {
            bleManager.sendData("/");
            moveToGenerateResult(context, profileDetails);
          }

          if (!perfectBlowValueCaptured && isBlownInFresher && blowP! <= 0.9) {
            if (!diffTStampFlag) {
              diffTStampFlag = true;
              diffTStamp = DateTime.now().millisecondsSinceEpoch;
            }

            diffTStampCurrent = DateTime.now().millisecondsSinceEpoch;
            int timeDifference = diffTStampCurrent! - diffTStamp!;
            if (timeDifference >= Thresholds.abortDifference) {
              if (!isAbort) {
                isAbort = true;
                bleManager.sendData("&");
                showImproperExhale(
                  context: context,
                  tryAgainButtonClicked: () {
                    _setCancelOrDisconnectFlag();
                    _navigateToDashboard(profileDetails);
                  },
                  needHelpButtonCancel: () {},
                );
                showAbort();
              }
            }
          } else {
            diffTStampFlag = false;
            diffTStamp = DateTime.now().millisecondsSinceEpoch;
          }
        }
      }
    }
  }


  void _navigateToDashboard(ResultProfileDataModel profileDetails) {
    if (Get.isOverlaysOpen) {
      Get.back();
    }
    Get.offAllNamed(
      AppRoutes.mainDashboard,
      arguments: {
        'profile_details': profileDetails,
      },
    );
  }


  void showAbort() {}

  // void moveToGenerateResult() {
  //   print("Move to generate result");
  // }

  // Move to Generate Result
  void moveToGenerateResult(
    BuildContext context,
    ResultProfileDataModel profileDetails,
  ) async {
    final ClinicalBluetoothManager bleManager = ClinicalBluetoothManager();

    if (!moveToResults) {
      // Stop the blow process
      stopBlow();

      // Mark the blow end time as captured
      final blowEndTime = DateTime.now().millisecondsSinceEpoch;

      // Calculate total blow time
      final finalBlowTime = blowEndTime - (blowStartTime ?? blowEndTime);
      if (kDebugMode) {
        print('Final Blow time : $finalBlowTime');
      }

      // Check if the blow time is below 1.5 seconds
      if (finalBlowTime < 1500) {
        if (!isImproperBlow) {
          isAbort = true;
          isImproperBlow = true;
          bleManager.sendData("&");
          showImproperExhale(
            context: context,
            tryAgainButtonClicked: () {
              _setCancelOrDisconnectFlag();
              _navigateToDashboard(profileDetails);
            },
            needHelpButtonCancel: () {},
          );
          showAbort();
        }

        return; // Exit the function if the time is below 1.5 seconds
      }
      if (finalBlowTime >= 16000) return;

      // Extract best and max pressure from blow values
      double sum = blowValuesList.fold(
        0,
        (previous, number) => previous + number,
      );
      double bestPR = sum / blowValuesList.length;
      if (kDebugMode) {
        print('Blow data List: $blowValuesList');
      }
      if (kDebugMode) {
        print('Best PR : $bestPR');
      }
      double maxPR = blowValuesList.reduce((a, b) => a > b ? a : b);
      if (kDebugMode) {
        print('Max PR : $maxPR');
      }

      final combinedList = [...baseBlowValueList, ...blowValuesList];
      if (kDebugMode) {
        print('✅ combinedList: $combinedList');
      }


      if (finalBlowTime >= 1500) {
        moveToResults = true;
        isImproperBlow = false;

        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => BluetoothGeneratingScreen(
                  maxPressure: maxPR,
                  bestPressure: bestPR,
                  blowDuration: finalBlowTime,
                  profileDetails: profileDetails,
                  blowValuesList: combinedList,
                ),
          ),
        );
      } else {
        abort('Abortion for moveToGenerateResult');
      }
    }
  }

  // Helper Functions
  void stopBlow() {
    if (kDebugMode) {
      print("Blow stopped.");
    }
    // Add implementation for stopping the blow signal
  }

  void abort(String text) {
    if (kDebugMode) {
      print(text);
    }
  }
}
