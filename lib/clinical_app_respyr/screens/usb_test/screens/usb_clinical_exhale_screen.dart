import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:respyr_clinical/clinical_app_respyr/screens/bluetooth_test/screens/bluetooth_clinical_exhale_screen.dart';
import 'package:respyr_clinical/clinical_app_respyr/screens/usb_test/screens/usb_clinical_generating_result.dart';
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
import '../../../../new_result/bloc/new_result_cubit.dart';
import '../../../../new_result/data/model/result_profile_data_model.dart';
import '../../../../router/app_routers.dart';

class UsbClinicalExhaleScreen extends StatefulWidget {
  final String baseValue;
  final bool isDeveloper;
  final ResultProfileDataModel profileDetails;
  const UsbClinicalExhaleScreen({
    super.key,
    required this.baseValue,
    this.isDeveloper = false,
    required this.profileDetails,
  });

  @override
  State<UsbClinicalExhaleScreen> createState() =>
      _UsbClinicalExhaleScreenState();
}

class _UsbClinicalExhaleScreenState extends State<UsbClinicalExhaleScreen> {
  double progress = 0.0;

  bool _isDisposed = false;
  late UsbBlowProcessor _usbBlowProcessor;
  double? thresholdPercentage;
  Timer? _counterTimeDown;
  int _secondsRemaining = 30;
  final AudioHelper _audioHelper = AudioHelper();

  StreamSubscription<String>? _usbDataSubscription;
  final ClinicalUsbCommunicationServices _usbService =
      ClinicalUsbCommunicationServices();
  bool _isConnected = false;
  bool _dialogShown = false;
  bool _countdownStarted = false;
  bool _hasNavigatedToDashboard = false;

  String? loginId;
  String? profileId;
  Color profileColor = const Color(0xFF99E37F);
  String? _lastReceivedData;
  bool _hasInternet = true;

  @override
  void initState() {
    super.initState();

    _usbBlowProcessor = UsbBlowProcessor();
    _startCountdownTimer();

    Future.microtask(() {
      setState(() {
        _isConnected = _usbService.isConnected;
      });

      _usbBlowProcessor.processBlowData(
        widget.baseValue,
        _usbService,
        context,
        widget.profileDetails,
      );
      _getUserId();
      _loadProfileColor();
      _initializeUsbConnection();
    });
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

  void _startCountdownTimer() {
    if (_countdownStarted || _hasNavigatedToDashboard) {
      return; // ✅ block if navigated
    }
    _countdownStarted = true;

    _counterTimeDown = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        if (!mounted || !_hasInternet) return;
        setState(() {
          _secondsRemaining--;
        });
      } else {
        timer.cancel();
        _counterTimeDown = null;
        if (!_hasNavigatedToDashboard) {
          _showExhaledTimeoutDialog();
        }
      }
    });
  }

  void _initializeUsbConnection() {
    _usbService.setUsbSerialListener(
      onConnectionStatusChanged: (status) {
        if (!mounted || _isDisposed || !_hasInternet) return;

        final bool isNowConnected = (status.toLowerCase()) == "connected";

        if (mounted && !_isDisposed) {
          setState(() {
            _isConnected = isNowConnected;
          });
        }

        if (isNowConnected) {
          _startCountdownTimer();
        } else {
          _counterTimeDown?.cancel();
          _counterTimeDown = null;
          _countdownStarted = false;
          Future.delayed(const Duration(milliseconds: 500)).then((_) {
            if (!mounted || _isDisposed) return;

            if (!_isConnected) {
              _audioHelper.stopAudio();
              _handleDisconnection();
            }
          });
        }
      },
      // onDataReceived is intentionally removed!
      onError: (onError) {
        if (mounted) {
          _showErrorDialog("USB Error: $onError");
        }
      },
    );

    // Cancel previous subscription if exists, then listen for new data.
    _usbDataSubscription?.cancel();
    _usbDataSubscription = _usbService.dataStream.listen(_onUsbDataReceived);
  }

  void _onUsbDataReceived(String data) async {
    if (data == _lastReceivedData) return;
    _lastReceivedData = data;
    if (data.contains("analize")) {
      if (mounted || !_hasInternet) {
        _stopAllProcesses();
      }
    }
    _receivedDataSubscriptionHandler(data);
  }

  void _receivedDataSubscriptionHandler(String data) {
    _usbBlowProcessor.processBlowData(
      data,
      _usbService,
      context,
      widget.profileDetails,
    );
    if (_usbBlowProcessor.isBlown) {
      setState(() {
        progress = (_usbBlowProcessor.blowP ?? 0) / 100.0; // Normalize to 0-1
      });
      if (_secondsRemaining > 0) {
        _counterTimeDown?.cancel();
        _counterTimeDown = null;
      }
    }
  }

  Future<bool> _showCancelTestDialog(context) async {
    bool didCancel = false;
    showCancelTestBox(
      context: context,
      cancelTestButtonPressed: () async {
        _exitToDashboard();
        Navigator.pop(context);
      },
    );
    return didCancel;
  }

  Future<void> _exitToDashboard() async {
    _abortProcess();
    await _setCancelOrDisconnectFlag();
    if (mounted) {
      _navigateToDashboard();
    }
  }

  void _abortProcess() {
    _usbService.sendData("&");
  }

  void _navigateToDashboard() {
    if (_hasNavigatedToDashboard) return;
    _hasNavigatedToDashboard = true;

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

  // Method to load profile color from GetStorage
  void _loadProfileColor() {
    final storage = GetStorage();
    final String? profileColorHex = storage.read(
      GetStoredDataText.isProfileColorChanged,
    );
    loginId = storage.read(GetStoredDataText.profileCreationLoginId) ?? '';

    // If profile color is available, convert from hex string to Color object
    if (profileColorHex != null) {
      setState(() {
        profileColor = Color(
          int.parse(profileColorHex, radix: 16),
        ).withAlpha(255);
      });
    }
  }

  void _stopAllProcesses() {
    if (_isDisposed) return;
    _isDisposed = true;
    _usbDataSubscription?.cancel();
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
      _usbService.sendData("/");
    }
  }

  @override
  void dispose() {
    _usbDataSubscription?.cancel(); // very important
    _counterTimeDown?.cancel();
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

    double? threBaseVal = _usbBlowProcessor.blowThresholdValue;

    if (threBaseVal != null) {
      thresholdPercentage = Thresholds.calculateThresholdPercentage(
        threBaseVal,
      );
    } else {
      // Handle the null case appropriately
      if (kDebugMode) {
        print("Warning: blowThresholdValue is null");
      }
      thresholdPercentage = 0; // or some default/fallback value
    }
    return PopScope(
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
      child: InternetConnectivityHandler(
        onConnectivityChanged: (hasInternet) {
          setState(() {
            _hasInternet = hasInternet;
          });
        },
        onRetry: () async {
          await _exitToDashboard();
        },
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
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(10),
                                    ),
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
                                  child: Container(
                                    width: 2,
                                    color: Colors.black,
                                  ),
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
      ),
    );
  }

  // Method to show a dialog box for primary profile deletion attempt
  void _showExhaledTimeoutDialog() async {
    if (_dialogShown || _hasNavigatedToDashboard) return;
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
                      _abortProcess();
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
}

class UsbBlowProcessor {
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

  void processBlowData(
    String data,
    ClinicalUsbCommunicationServices usbService,
    BuildContext context,
    ResultProfileDataModel profileDetails,
  ) {
    final baseValueRegex = RegExp(r'/([0-9.]+)/');
    final blowValueRegex = RegExp(r'\{([0-9.]+)\}');

    final baseValueMatch = baseValueRegex.firstMatch(data);
    final blowValueMatch = blowValueRegex.firstMatch(data);

    if (baseValueMatch != null && !isBaseValueCaptured) {
      // Extract base value
      blowBaseValue = double.parse(baseValueMatch.group(1)!);
      baseBlowValueList.add(blowBaseValue!);
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
            blowValuesList.clear();
          }

          blowValuesList.add(blowValue);

        } else if (blowP! < thresholdPercentage!) {
          if (perfectBlowValueCaptured && isBlown && !moveToResults) {
            moveToGenerateResult(context, profileDetails, usbService);
            return;
          } else if (!perfectBlowValueCaptured &&
              isBlownInFresher &&
              blowP! <= 0.9) {
            if (!diffTStampFlag) {
              diffTStampFlag = true;
              diffTStamp = DateTime.now().millisecondsSinceEpoch;
            }

            diffTStampCurrent = DateTime.now().millisecondsSinceEpoch;
            int timeDifference = diffTStampCurrent! - diffTStamp!;

            if (timeDifference >= Thresholds.abortDifference) {
              if (!isAbort) {
                isAbort = true;
                usbService.sendData("&");
                showImproperExhale(
                  context: context,
                  tryAgainButtonClicked: () {
                    _setCancelOrDisconnectFlag();
                    _navigateToDashboard(context, profileDetails.clinicName!);
                  },
                  needHelpButtonCancel: () {},
                );
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

  void _navigateToDashboard(BuildContext context, String loginId) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder:
            (_) => BlocProvider(
              create: (_) => HealthScoreBloc(OverallDataByDateService()),
              child: ClinicalDashboardMain(loginId: loginId),
            ),
      ),
    );
  }

  Future<void> _setCancelOrDisconnectFlag() async {
    final storage = GetStorage();
    final DateTime now = DateTime.now();
    await storage.write('cancel_or_disconnect_time', now.toIso8601String());
  }

  void moveToGenerateResult(
    BuildContext context,
    ResultProfileDataModel profileDetails,
    ClinicalUsbCommunicationServices usbService,
  ) async {
    if (!moveToResults) {
      final blowEndTime = DateTime.now().millisecondsSinceEpoch;
      final finalBlowTime = blowEndTime - (blowStartTime ?? blowEndTime);

      if (finalBlowTime > 1500) {
        usbService.sendData("/");

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

        if (kDebugMode) {
          print('✅ baseBlowValueList: $baseBlowValueList');
        }
        final combinedList = [...baseBlowValueList, ...blowValuesList];
        if (kDebugMode) {
          print('✅ combinedList: $combinedList');
        }
        moveToResults = true;
        isImproperBlow = false;

        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => BlocProvider(
                  create: (_) => NewResultCubit(),
                  child: UsbClinicalGeneratingResult(
                    maxPressure: maxPR,
                    bestPressure: bestPR,
                    blowDuration: finalBlowTime,
                    profileDetails: profileDetails,
                    blowValuesList: combinedList,
                  ),
                ),
          ),
        );
      } else {
        if (!isAbort) {
          usbService.sendData("&");
          isAbort = true;
          showImproperExhale(
            context: context,
            tryAgainButtonClicked: () {
              _setCancelOrDisconnectFlag();
              _navigateToDashboard(context, profileDetails.clinicName!);
            },
            needHelpButtonCancel: () {},
          );
        }
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
