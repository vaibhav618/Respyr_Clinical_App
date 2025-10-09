import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:respyr_clinical/clinical_app_respyr/screens/bluetooth_test/services/clinical_bluetooth_manager.dart';
import 'package:respyr_clinical/clinical_app_respyr/screens/result_screen_clinical_app.dart';
import 'package:respyr_clinical/clinical_app_respyr/services/clinical_score_api.dart';
import 'package:respyr_clinical/clinical_app_respyr/services/device_battery_utils.dart';
import 'package:respyr_clinical/clinical_app_respyr/services/disconnected_error.dart';
import 'package:respyr_clinical/clinical_app_respyr/services/raw_data_service.dart';
import 'package:respyr_clinical/clinical_dashboard/views/clinical_dashboard.dart';
import 'package:respyr_clinical/shared/colors.dart';

import '../../../../new_result/data/model/result_profile_data_model.dart';

class BluetoothGeneratingScreen extends StatefulWidget {
  final double maxPressure;
  final double bestPressure;
  final int blowDuration;
  final ResultProfileDataModel profileDetails;
  const BluetoothGeneratingScreen({
    super.key,
    required this.maxPressure,
    required this.bestPressure,
    required this.blowDuration,
    required this.profileDetails,
  });

  @override
  State<BluetoothGeneratingScreen> createState() =>
      _BluetoothGeneratingScreenState();
}

class _BluetoothGeneratingScreenState extends State<BluetoothGeneratingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  int completedSteps = 0;
  bool isErrorOccurred = false;
  String errorMessage = '';
  String bestPressure = '';
  String maxPressure = '';
  String blowTime = '';

  int batteryPercentage = 0;

  final storage = GetStorage();

  String waterConsumed = 'No data';
  String cigarettesUnit = 'No data';
  String alcoholIntake = 'No data';
  String foodIntake = 'No data';
  String foodName = 'No data';
  String foodQuantity = 'No data';
  String skipMeal = 'No data';
  String exerciseMinutes = 'No data';
  String sleepHoursDailyRoutine = 'No data';

  String loginId = "";
  String profileId = "";
  String profileName = "";
  int age = 0;
  String gender = 'No data';
  double height = 0.0;
  double weight = 0.0;

  List<String> extractedFoodName = [];
  List<int> extractFoodQuantities = [];
  List<bool> extractSkipMeal = [];

  // Bluetooth Settings
  final ClinicalBluetoothManager _bleManager = ClinicalBluetoothManager();
  StreamSubscription<String>? _receivedDataSubscription;
  bool _isConnected = false;
  bool _isDisposed = false;
  bool _isDisconnectPop = false;
  bool _hasShownDisconnectedDialog = false;
  bool received120 = false;
  bool navigationToResultScreen = false;
  StringBuffer rawDataBuffer = StringBuffer();
  String errorText = "";
  String rawData = "";

  @override
  void initState() {
    super.initState();
    _isConnected = _bleManager.isConnected;
    _controller = AnimationController(vsync: this);

    _checkBluetoothDeviceConnectivity();
    bestPressure = widget.bestPressure.toStringAsFixed(0);
    maxPressure = widget.maxPressure.toStringAsFixed(0);
    blowTime = widget.blowDuration.toString();
    _loadProfileDetails();
  }

  void _loadProfileDetails() {
    // Print the full profile details map
    print("Profile Details: ${widget.profileDetails}");

    height = widget.profileDetails.height ?? 0;
    weight = widget.profileDetails.weight ?? 0;
    profileName = widget.profileDetails.profileName ?? '';
    age = widget.profileDetails.age ?? 0;
    gender = widget.profileDetails.gender ?? '';
    loginId = widget.profileDetails.clinicName ?? '';
    profileId = widget.profileDetails.subjectId ?? '';
    // Optionally print each field
    print("Gender: $gender");
    print("Age: $age");
    print("Height: $height");
    print("Weight: $weight");
    print("profileName: $profileName");
    print("loginId: $loginId");
    print("profileId: $profileId");
  }

  void stopExhale() {
    if (_isConnected) {
      _bleManager.sendData("/");
    }
  }

  @override
  void dispose() {
    _isDisposed = true;

    _controller.dispose();

    _receivedDataSubscription?.cancel();
    _receivedDataSubscription = null;

    super.dispose();
  }

  void _handleDisconnection() {
    if (!mounted ||
        _isConnected ||
        received120 ||
        _isDisconnectPop ||
        _hasShownDisconnectedDialog) {
      return;
    }

    _isDisconnectPop = true;
    _hasShownDisconnectedDialog = true;
    // print("Showing Disconnection Dialog");

    showDeviceDisconnectedBox(
      context: context,
      onButtonPressed: () async {
        _isDisconnectPop = false;
        if (mounted) {
          Navigator.pop(context);
        }
        await Future.delayed(const Duration(milliseconds: 300));
        _setCancelOrDisconnectFlag();
        abortProcess();
        _navigateToDashboard();
      },
    );
  }

  void abortProcess() {
    if (_isConnected) {
      _bleManager.sendData("&");
    }
  }

  void _navigateToDashboard() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder:
            (context) => ClinicalDashboardMain(
              loginId: '',
            ), // Replace with your DashboardScreen widget
      ),
      (Route<dynamic> route) => false, // Remove all previous screens
    );
  }

  Future<void> _setCancelOrDisconnectFlag() async {
    final storage = GetStorage();
    final DateTime now = DateTime.now();

    await storage.write('cancel_or_disconnect_time', now.toIso8601String());
  }

  void _checkBluetoothDeviceConnectivity() {
    if (!mounted) return;
    setState(() {
      completedSteps = 1;
    });

    _bleManager.connectionStatusStream.listen(
      (isConnected) {
        if (!mounted) return;

        setState(() {
          _isConnected = isConnected;
        });

        if (isConnected) {
          _isDisconnectPop = false;
          _hasShownDisconnectedDialog = false;
        }

        if (!isConnected) {
          if (received120) {
            return;
          }

          if (!isConnected &&
              !_isDisposed &&
              !_isDisconnectPop &&
              !_hasShownDisconnectedDialog) {
            Future.delayed(const Duration(milliseconds: 500)).then((_) {
              if (!mounted || _isDisposed || _isConnected) return;
              _controller.stop();
              _setCancelOrDisconnectFlag();
              _handleDisconnection();
            });
          }
          _hasShownDisconnectedDialog = false;
        }
      },
      onError: (error) {
        if (_isDisposed) return;
        _showErrorDialog("Connection status error.");
      },
    );

    if (_receivedDataSubscription == null ||
        _receivedDataSubscription!.isPaused) {
      _receivedDataSubscription = _bleManager.receivedDataStream.listen(
        (data) {
          if (_isDisposed) return;

          try {
            if (data == "120") {
              received120 =
                  true; // ✅ Ensure this is set BEFORE checking dialogs
              _isDisconnectPop = false; // Prevent the dialog from showing

              if (Get.isOverlaysOpen) {
                Get.back(); // ✅ Close any open dialogs
              }

              return; // ✅ STOP further processing
            }

            setState(() {
              completedSteps = 2;
            });

            rawDataBuffer.write(data);
            rawData += data;

            if (kDebugMode) {
              print("📩 Received Data: $data");
              print("📊 Raw Data Buffer: ${rawDataBuffer.toString()}");
            }

            String accumulatedData = rawDataBuffer.toString();

            final containsNumber = RegExp(r'\d').hasMatch(accumulatedData);
            final containsDollar = accumulatedData.contains("\$");
            final containsMaxPressure = accumulatedData.contains("MAXPR");
            final containsBDur = accumulatedData.contains("BDur");
            final containsBestPr = accumulatedData.contains("Best_pr");
            final containsStar = accumulatedData.contains("*");

            if (kDebugMode) {
              print(
                "🔎 Conditions: containsDollar=$containsDollar, "
                "containsMaxPressure=$containsMaxPressure, "
                "containsBDur=$containsBDur, containsBestPr=$containsBestPr, "
                "containsNumber=$containsNumber, containsStar=$containsStar",
              );
            }

            if (containsDollar ||
                containsMaxPressure ||
                containsBDur ||
                containsBestPr ||
                containsNumber ||
                containsStar) {
              if (accumulatedData.contains("*")) {
                if (accumulatedData == rawData) {
                  if (kDebugMode) {
                    print(
                      '✅ Raw Data String: ${rawDataBuffer.toString().trim()}',
                    );
                  }

                  final cleanedData = accumulatedData.replaceFirst(
                    RegExp(r'^analizeanalize'),
                    '',
                  );
                  processFinalData(cleanedData.trim());
                  rawDataBuffer.clear();
                  rawData = "";
                }

                _receivedDataSubscription?.cancel();
                _receivedDataSubscription = null;
              }
            }
          } catch (e) {
            if (_isDisposed) return;
            if (kDebugMode) {
              print("❌ Error processing data: $e");
            }
            _showErrorDialog("Error processing received data: $e");
          }
        },
        onError: (error) {
          if (!mounted) return;
          _showErrorDialog("Error receiving data from device: $error");
          if (kDebugMode) {
            print("🚨 Stream Error: $error");
          }
        },
      );
    }
  }

  bool isDataBeingProcessing = false;

  void processFinalData(String rawData) {
    if (kDebugMode) {
      print(
        'Best pressure: $bestPressure, Max pressure: $maxPressure, Blow time: $blowTime',
      );
    }
    String finalData = rawData.replaceAll("Best_pr", bestPressure);
    String finalData2 = finalData.replaceAll("MAXPR", maxPressure);
    String finalData3 = finalData2.replaceAll("BDur", blowTime);

    if (!isDataBeingProcessing) {
      isDataBeingProcessing = true; // ← Add this
      completedSteps = 3;
      processRawData(finalData3);
    }
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

  String? getProfileData(List<Map<String, String>> result, String key) {
    try {
      final entry = result.firstWhere(
        (map) => map.containsKey(key),
        orElse: () => {key: 'Not Found'},
      );
      return entry[key];
    } catch (e) {
      return 'Not Found';
    }
  }

  void showError(String message) {
    setState(() {
      isErrorOccurred = true;
      errorMessage = message;
    });
  }

  Widget _buildProgressIndicator(int step, String text) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                if (completedSteps == step)
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
                  completedSteps > step
                      ? "assets/verified.svg"
                      : "assets/unverified.svg",
                  height: 25,
                  width: 25,
                ),
              ],
            ),
            SizedBox(width: MediaQuery.of(context).size.width * 0.03),
            Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColor.textLightColor,
              ),
            ),
          ],
        ),
        if (step < 3)
          Container(
            margin: const EdgeInsets.only(left: 11),
            height: 50,
            width: 3,
            decoration: BoxDecoration(
              color:
                  completedSteps > step
                      ? AppColor.buttonGreenColor
                      : const Color(0xFFE0E0E0),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    batteryPercentage = storage.read('batteryPercentage');
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColor.whiteColor,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // IconButton(
                    //   onPressed: _showCancelTestDialog,
                    //   icon: SvgPicture.asset("assets/svg_icons/close_icon.svg"),
                    // ),
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
                  ],
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.1),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25),
                  child: Column(
                    children: [
                      _buildProgressIndicator(1, "Calculating your result"),
                      _buildProgressIndicator(2, "Analyzing your result"),
                      _buildProgressIndicator(3, 'Generating your report'),
                    ],
                  ),
                ),
                isErrorOccurred ? Text(errorText) : const Text(""),
                const SizedBox(height: 20),
                const Image(image: AssetImage("assets/searching_file.gif")),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void processRawData(String deviceRawData) async {
    deviceRawData = deviceRawData.replaceAll("/analize", "");
    final match = RegExp(r'H(\d{3,5})').firstMatch(deviceRawData);
    final int hardwareId = int.tryParse(match?.group(1) ?? '0') ?? 0;
    final rawDataService = RawDataService(
      'https://humorstech.com/humorscalculation/production.php',
    );
    try {
      // print('third Step started : $completedSteps');
      if (_isDisposed) return;
      setState(() {
        completedSteps = 3;
      });
      final response = await rawDataService.fetchRawData(
        bFlag2: '0',
        deviceRawData: deviceRawData,
        loginId: loginId,
        profileId: profileId,
        gender: gender,
        aboutCounter: 0,
      );

      List<Map<String, String>> rawDataProcessed = rawDataService.parseJsonData(
        response,
      );

      if (rawDataProcessed[0]['status'] == "1") {
        double acetoneMilliVolt = double.parse(
          rawDataProcessed[0]['MVacetone'] ?? '0',
        );
        double ethanolPartsPerMillion = double.parse(
          rawDataProcessed[0]['etholpp'] ?? '0',
        );

        double h2 = double.parse(rawDataProcessed[0]['h2'] ?? '0');

        // Ensure BDur is correctly assigned and does not take maxpr value
        double blowDuration = 0.0;

        if (rawDataProcessed[0].containsKey('duration') &&
            rawDataProcessed[0]['duration'] != null &&
            rawDataProcessed[0]['duration']!.isNotEmpty) {
          blowDuration = double.parse(rawDataProcessed[0]['duration']!);
          // print('Blow Duration during production.php: $blowDuration');
        } else {
          Exception("Error: 'duration' key missing or empty in response!");
        }

        if (kDebugMode) {
          print('acetoneMilliVolt: $acetoneMilliVolt');
          print('ethanolPartsPerMillion: $ethanolPartsPerMillion');
          print("hardwareId: $hardwareId");
          print('h2: $h2');
          print('blowDuration: $blowDuration');
        }

        processClinicalDiabeticScore(
          acetoneMilliVolt,
          ethanolPartsPerMillion,
          blowDuration,
          hardwareId,
          h2,
        );
      } else {
        if (_isDisposed) return;
        setState(() {
          isErrorOccurred = true;
          errorText = response;
        });
      }
    } catch (e) {
      if (_isDisposed) return;
      setState(() {
        isErrorOccurred = true;
        errorText = e.toString();
      });
    }
  }

  void processClinicalDiabeticScore(
    double acetone,
    double ethanol,
    double blow,
    int hardwareId,
    double h2,
  ) async {
    final clinicalService = ClinicalDiabeticScore();
    final clinicalResult = await clinicalService.processDiabeticScore(
      acetone: acetone,
      ethnol: ethanol,
      blow: blow,
      age: age,
      profileId: profileId,
      gender: gender,
      h2: h2,
      loginId: loginId,
      hardwareId: hardwareId.toString(),
    );

    double sugarScore =
        double.tryParse(clinicalResult['Dibetic_Score']?.toString() ?? "0") ??
        0.0;
    double blowScore =
        double.tryParse(clinicalResult['Blow_Score']?.toString() ?? "0") ?? 0.0;
    double gutScore =
        double.tryParse(clinicalResult['Gut_Score_per']?.toString() ?? "0") ??
        0.0;
    double liverScore =
        double.tryParse(clinicalResult['score_liver']?.toString() ?? "0") ??
        0.0;

    int timestamp =
        int.tryParse(clinicalResult['timestamp']?.toString() ?? '0') ?? 0;

    Map<String, dynamic> lifestyleMap = {
      'sugarScore': sugarScore,
      'blowScore': blowScore,
      'gutScore': gutScore,
      'liverScore': liverScore,
      'rawResponse': clinicalResult,
      'timestamp': timestamp,
    };

    print("lifestyle Map: $lifestyleMap");

    String lifestyleJson = jsonEncode(lifestyleMap);

    // Unsubscribe from the connection status stream before navigating
    _receivedDataSubscription?.cancel();

    _navigateToResultScreen(lifestyleJson);
  }

  void _navigateToResultScreen(String lifestyleJson) {
    if (Get.isOverlaysOpen) {
      Get.back(); // Close any open overlays/dialogs
    }

    received120 = true;

    Navigator.of(context).popUntil((route) => route.isFirst);
    _abortProcess();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => ResultScreenClinicalApp(
              lifeStyleJsonResponse: lifestyleJson,
              profileDetails: widget.profileDetails,
            ),
      ),
    );
  }

  void _abortProcess() {
    if (_isConnected) {
      _bleManager.sendData("&");
    }
  }

  int extractTimestamp(String lifestyleJson) {
    try {
      final jsonData = jsonDecode(lifestyleJson);

      // Ensure 'data' exists and is a list
      if (jsonData['data'] is List && jsonData['data'].isNotEmpty) {
        var timestampValue = jsonData['data'][0]['timestamp'];

        // Convert timestamp to int safely
        if (timestampValue is int) {
          return timestampValue;
        } else if (timestampValue is String) {
          return int.tryParse(timestampValue) ?? 0; // Handle parsing errors
        }
      }
    } catch (e) {
      Exception('Error extracting timestamp: $e');
    }
    return 0; // Default to 0 in case of error
  }

  // void _showCancelTestDialog() {
  //   showCancelTestBox(
  //       context: context,
  //       cancelTestButtonPressed: () {
  //         saveReadingAbortTime().then((_) {
  //           Get.back();
  //           _setCancelOrDisconnectFlag();
  //           abortProcess();
  //           _navigateToDashboard();
  //         });
  //       });
  // }
}
