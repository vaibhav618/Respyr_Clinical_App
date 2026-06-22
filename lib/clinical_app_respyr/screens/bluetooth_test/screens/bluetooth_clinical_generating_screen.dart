import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:respyr_clinical/clinical_app_respyr/screens/bluetooth_test/services/clinical_bluetooth_manager.dart';
import 'package:respyr_clinical/clinical_app_respyr/screens/result_screen_clinical_app.dart';
import 'package:respyr_clinical/clinical_app_respyr/services/clinical_score_api.dart';
import 'package:respyr_clinical/clinical_app_respyr/services/device_battery_utils.dart';
import 'package:respyr_clinical/clinical_app_respyr/services/disconnected_error.dart';
import 'package:respyr_clinical/clinical_app_respyr/services/raw_data_service.dart';
import 'package:respyr_clinical/clinical_dashboard/views/clinical_dashboard.dart';
import 'package:respyr_clinical/shared/colors.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../clinical_dashboard/bloc/health_score_bloc.dart';
import '../../../../clinical_dashboard/service/overall_data_by_date_service.dart';
import '../../../../new_result/data/model/result_model.dart';
import '../../../../new_result/data/model/result_profile_data_model.dart';
import '../../../../new_result/presentation/view/overall_result.dart';
import '../../../../new_result/presentation/view_model/result_view_model.dart';
import '../../../../router/app_routers.dart';
import '../../../../utils/blow_values_helper.dart';
import '../services/result_service.dart';

class BluetoothGeneratingScreen extends StatefulWidget {
  final double maxPressure;
  final double bestPressure;
  final int blowDuration;
  final ResultProfileDataModel profileDetails;
  final List<double> blowValuesList;

  const BluetoothGeneratingScreen({
    super.key,
    required this.maxPressure,
    required this.bestPressure,
    required this.blowDuration,
    required this.profileDetails,
    required this.blowValuesList,
  });

  @override
  State<BluetoothGeneratingScreen> createState() =>
      _BluetoothGeneratingScreenState();
}

// 👇 ADDED WidgetsBindingObserver
class _BluetoothGeneratingScreenState extends State<BluetoothGeneratingScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _controller;

  // 👇 ADDED Hidden Variables for Retry Logic & Ghost Tracking
  bool _needsRetry = false;
  String _savedRawData = "";
  bool _isApiRunning = false;
  int _apiRequestId = 0;

  int completedSteps = 0;
  bool isErrorOccurred = false;
  String errorMessage = '';
  String bestPressure = '';
  String maxPressure = '';
  String blowTime = '';

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
    WidgetsBinding.instance.addObserver(this); // 👇 ADDED OBSERVER LISTENER
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
    WidgetsBinding.instance.removeObserver(
      this,
    ); // 👇 REMOVED OBSERVER LISTENER
    _isDisposed = true;

    _controller.dispose();

    _receivedDataSubscription?.cancel();
    _receivedDataSubscription = null;

    super.dispose();
  }

  // 👇 ADDED LIFECYCLE HOOK FOR RESURRECTION & GHOST REQUESTS
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_needsRetry && _savedRawData.isNotEmpty) {
        setState(() {
          _needsRetry = false;
          isErrorOccurred = false;
        });
        print("🚀🚀🚀 APP WOKE UP. Retrying the dead API call! 🚀🚀🚀");
        processRawData1(_savedRawData);
      } else if (_isApiRunning && _savedRawData.isNotEmpty) {
        setState(() {
          isErrorOccurred = false;
        });
        print(
          "⚡⚡⚡ APP WOKE UP. Old request is frozen. Firing a fresh one! ⚡⚡⚡",
        );
        processRawData1(_savedRawData);
      }
    }
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
    if (Get.isOverlaysOpen) {
      Get.back();
    }
    Get.offAllNamed(
      AppRoutes.mainDashboard,
      arguments: {'profile_details': widget.profileDetails},
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
            final regex = RegExp(r'\{\d+(\.\d+)?\}');
            final blowDataPattern = regex.hasMatch(data);
            final containsAnalise = data.contains("analize");

            if (data == "120") {
              received120 =
                  true; // ✅ Ensure this is set BEFORE checking dialogs
              _isDisconnectPop = false; // Prevent the dialog from showing

              if (Get.isOverlaysOpen) {
                Get.back(); // ✅ Close any open dialogs
              }

              return; // ✅ STOP further processing
            } else if (blowDataPattern || containsAnalise) {
              return;
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

            if (blowDataPattern) {
              print("blowDataPattern" + accumulatedData);
              accumulatedData.replaceAll(regex, "");
            }

            if (containsAnalise) {
              print("blowDataPattern" + accumulatedData);
              accumulatedData.replaceAll("analize", "");
            }

            if (containsDollar ||
                containsMaxPressure ||
                containsBDur ||
                containsBestPr ||
                containsNumber ||
                containsStar) {
              if (accumulatedData.contains("*")) {
                print("accumulatedData : " + accumulatedData);
                print("rawData : f" + rawData);

                processFinalData(accumulatedData.trim());
                rawDataBuffer.clear();
                rawData = "";

                // if (accumulatedData == rawData) {
                //   if (kDebugMode) {
                //     print(
                //       '✅ Raw Data String: ${rawDataBuffer.toString().trim()}',
                //     );
                //   }
                //
                //   final cleanedData = accumulatedData.replaceAll("analize", " ");
                //

                //
                // }

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

    print("finalData3 : " + finalData3);

    if (!isDataBeingProcessing) {
      isDataBeingProcessing = true;
      completedSteps = 3;
      processRawData1(finalData3);
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false, // 👈 prevents tap outside dismiss
      builder:
          (context) => WillPopScope(
            onWillPop: () async => false, // 👈 disables back button
            child: AlertDialog(
              title: const Text("Error"),
              content: Text(message),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // close dialog
                    _navigateToDashboard();
                  },
                  child: const Text("OK"),
                ),
              ],
            ),
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
    // batteryPercentage = storage.read('batteryPercentage');
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

  void processRawData1(String deviceRawData) async {
    _savedRawData = deviceRawData; // 👇 1. SAVE THE BACKUP DATA HERE
    _isApiRunning = true; // 👇 2. MARK API AS RUNNING
    _apiRequestId++; // 👇 3. INCREMENT TICKET NUMBER
    final int thisRequestId = _apiRequestId; // 👇 SAVE THIS RUN'S TICKET

    ResultService resultService = ResultService();
    final profile = widget.profileDetails;
    String testdata = deviceRawData;
    String subId = "${profile.clinicName!}\$${profile.subjectId!}";
    String gender = profile.gender!;
    String age = profile.age.toString();
    String height = profile.height.toString();
    String region = profile.region.toString();

    try {
      final NewResultModel result = await resultService.fetchResults1(
        testdata: testdata,
        subjectId: subId,
        gender: gender,
        age: age,
        height: height,
        region: region,
        blowData: BlowValuesHelper().getBlowString(widget.blowValuesList),
      );

      // 👇 4. IGNORE IF A NEWER REQUEST WAS FIRED
      if (thisRequestId != _apiRequestId) return;

      _isApiRunning = false; // API finished successfully
      _navigateToResultScreen1(result);
    } catch (e) {
      // 👇 5. IGNORE ERRORS FROM OLD GHOST REQUESTS
      if (thisRequestId != _apiRequestId) return;

      _isApiRunning = false; // API finished with error

      // THE COVER-UP (Check if minimized)
      final appState = WidgetsBinding.instance.lifecycleState;
      final isMinimized =
          appState == AppLifecycleState.paused ||
          appState == AppLifecycleState.inactive ||
          appState == AppLifecycleState.hidden;

      if (isMinimized) {
        _needsRetry = true;
        print("🤫 API died while minimized. Flagging for retry.");
      } else {
        if (e.toString().contains("Error in breath sample")) {
          _showErrorDialog("Error in breath sample");
        } else {
          _showErrorDialog(e.toString());
        }
      }
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

  void _navigateToResultScreen1(NewResultModel lifestyleJson) {
    if (Get.isOverlaysOpen) {
      Get.back(); // Close any open overlays/dialogs
    }
    saveCurrentTime();
    received120 = true;

    Navigator.of(context).popUntil((route) => route.isFirst);
    _abortProcess();
    Get.offAll(
      () => ChangeNotifierProvider(
        create: (_) => ResultViewModel()..initialize(widget.profileDetails),
        child: ResultScreen(
          userResultData: lifestyleJson,
          userProfileData: widget.profileDetails,
          blowValuesList: widget.blowValuesList,
        ),
      ),
    );
  }

  Future<void> saveCurrentTime() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now().millisecondsSinceEpoch;

    await prefs.setInt('last_reading_time', now);
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
