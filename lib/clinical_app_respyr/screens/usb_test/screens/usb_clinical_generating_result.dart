import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:respyr_clinical/clinical_app_respyr/screens/usb_test/services/clinical_usb_communication_services.dart';
import 'package:respyr_clinical/clinical_app_respyr/services/disconnected_error.dart';
import 'package:respyr_clinical/clinical_dashboard/views/clinical_dashboard.dart';
import 'package:respyr_clinical/widgets/internet_connectivity_check.dart';
import 'package:respyr_clinical/shared/colors.dart';
import '../../../../clinical_dashboard/bloc/health_score_bloc.dart';
import '../../../../clinical_dashboard/service/overall_data_by_date_service.dart';
import '../../../../new_result/bloc/new_result_bloc.dart';
import '../../../../new_result/bloc/new_result_cubit.dart';
import '../../../../new_result/data/model/result_model.dart';
import '../../../../new_result/data/model/result_profile_data_model.dart';
import '../../../../new_result/presentation/view/overall_result.dart';
import '../../../../new_result/presentation/view_model/result_view_model.dart';
import '../../../../utils/blow_values_helper.dart';

class UsbClinicalGeneratingResult extends StatefulWidget {
  final double maxPressure;
  final double bestPressure;
  final int blowDuration;
  final ResultProfileDataModel profileDetails;
  final List<double> blowValuesList;
  const UsbClinicalGeneratingResult({
    super.key,
    required this.maxPressure,
    required this.bestPressure,
    required this.blowDuration,
    required this.profileDetails,
    required this.blowValuesList,
  });

  @override
  State<UsbClinicalGeneratingResult> createState() =>
      _UsbClinicalGeneratingResultState();
}

class _UsbClinicalGeneratingResultState
    extends State<UsbClinicalGeneratingResult>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  int completedSteps = 0;
  bool isErrorOccurred = false;
  String bestPressure = '';
  String maxPressure = '';
  String blowTime = '';
  String _lastProcessedData = "";

  final ClinicalUsbCommunicationServices _usbService =
      ClinicalUsbCommunicationServices();
  StreamSubscription<String>? _usbDataSubscription;
  bool _isConnected = false;
  bool _isDisposed = false;
  bool _dialogShown = false;
  String? _lastProcessedPacket;
  bool received120 = false;
  bool navigationToResultScreen = false;
  StringBuffer rawDataBuffer = StringBuffer();
  String errorText = "";
  String rawData = "";
  String loginId = "";
  String profileId = "";
  String profileName = "";
  int age = 0;
  String gender = 'No data';
  double height = 0.0;
  double weight = 0.0;
  Timer? responseTimer;
  bool _hasInternet = true;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(vsync: this);

    _initialUsbConnection();
    bestPressure = widget.bestPressure.toStringAsFixed(2);
    maxPressure = widget.maxPressure.toStringAsFixed(2);
    blowTime = widget.blowDuration.toString();
    _loadProfileDetails();
    setState(() {
      startWaitForResponse();
      completedSteps = 1;
    });
  }

  void _loadProfileDetails() {
    debugPrint("Profile Details: ${widget.profileDetails}");

    height = widget.profileDetails.height ?? 0;
    weight = widget.profileDetails.weight ?? 0;
    profileName = widget.profileDetails.profileName ?? '';
    age = widget.profileDetails.age ?? 0;
    gender = widget.profileDetails.gender ?? '';
    loginId = widget.profileDetails.clinicName ?? '';
    profileId = widget.profileDetails.subjectId ?? '';
    debugPrint("Gender: $gender");
    debugPrint("Age: $age");
    debugPrint("Height: $height");
    debugPrint("Weight: $weight");
    debugPrint("profileName: $profileName");
    debugPrint("loginId: $loginId");
    debugPrint("profileId: $profileId");
  }

  void _handleDisconnected() {
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
    _abortProcess();
    await _setCancelOrDisconnectFlag();
    if (mounted) {
      _navigateToDashboard();
    }
  }

  void _abortProcess() {
    if (_isConnected) {
      _usbService.sendData("&");
    }
  }

  void stopExhale() {
    if (_isConnected) {
      _usbService.sendData("/");
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

  Future<void> _setCancelOrDisconnectFlag() async {
    final storage = GetStorage();
    final DateTime now = DateTime.now();
    await storage.write('cancel_or_disconnect_time', now.toIso8601String());
  }

  void _initialUsbConnection() {
    if (!mounted) return;
    setState(() {
      completedSteps = 1;
    });

    _usbService.setUsbSerialListener(
      onConnectionStatusChanged: (status) {
        bool isConnected = status == "connected";

        if (mounted && !_isDisposed) {
          setState(() {
            _isConnected = isConnected;
          });
        }

        if (!isConnected) {
          if (received120) return;
          if (!isConnected && !_isDisposed) {
            Future.delayed(const Duration(milliseconds: 500)).then((_) {
              if (!mounted || _isDisposed) return;
              _handleDisconnected();
            });
          }
        }
      },
      onDataReceived: _onUsbDataReceived,
      onError: (onError) {
        if (mounted) {
          _showErrorDialog("USB Error: $onError");
        }
      },
    );
    _usbDataSubscription?.cancel();
    _usbDataSubscription = _usbService.dataStream.listen(_onUsbDataReceived);
  }

  void _onUsbDataReceived(String data) {
    if (!mounted || _isDisposed) return;

    try {
      if (data == "120") {
        received120 = true;
        if (Get.isOverlaysOpen) {
          Get.back();
        }
        return;
      }

      if (completedSteps < 2) {
        setState(() {
          completedSteps = 2;
        });
      }

      // Handle start keyword only once
      final isAnalize = data.trim() == "analize";
      final bufferStr = rawDataBuffer.toString();

      if (isAnalize) {
        if (!bufferStr.startsWith("analize")) {
          rawDataBuffer.write(data);
          rawData += data;
        }
      } else {
        // Avoid repeated chunks: if buffer already ends with this data, skip
        if (!bufferStr.endsWith(data)) {
          rawDataBuffer.write(data);
          rawData += data;
        }
      }

      if (data == _lastProcessedData) return;
      _lastProcessedData = data;

      final accumulatedData = rawDataBuffer.toString();

      if (kDebugMode) {
        print("📩 Data: $data");
        print("📊 Buffer: $accumulatedData");
      }

      final hasAllParts =
          accumulatedData.contains("analize") &&
          accumulatedData.contains("\$") &&
          accumulatedData.contains("MAXPR") &&
          accumulatedData.contains("BDur") &&
          accumulatedData.contains("Best_pr") &&
          accumulatedData.contains("*");

      if (!hasAllParts) return;

      // Extract first full packet from analize to *
      final startIndex = accumulatedData.indexOf("analize");
      final endIndex = accumulatedData.indexOf("*", startIndex);
      if (startIndex == -1 || endIndex == -1) return;

      final fullPacket = accumulatedData.substring(startIndex, endIndex + 1);

      // Check for duplicates
      if (fullPacket == _lastProcessedPacket) {
        if (kDebugMode) {
          print("🔁 Duplicate packet ignored");
        }
        return;
      }

      _lastProcessedPacket = fullPacket;

      final cleaned =
          fullPacket.replaceFirst("analize", "").replaceAll("*", "").trim();

      if (kDebugMode) {
        print('✅ Cleaned Final Data: $cleaned');
      }

      processFinalData(cleaned);

      rawDataBuffer.clear();
      rawData = "";

      _usbDataSubscription?.cancel();
      _usbDataSubscription = null;
    } catch (e) {
      if (_isDisposed) return;
      _showErrorDialog("Error processing received data: $e");
      if (kDebugMode) {
        print("❌ Error processing data: $e");
      }
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
      // processRawData(finalData3);

      debugPrint("Called");
      debugPrint("deviceRawData :$finalData3");
      _callApi(context, finalData3);
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
      errorText = message;
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
    return InternetConnectivityHandler(
      onConnectivityChanged: (hasInternet) {
        setState(() {
          _hasInternet = hasInternet;
        });
      },
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
        child: BlocListener<NewResultCubit, NewResultState>(
          listener: (context, state) {
            setState(() {
              completedSteps = 3;
            });
            if (state is NewResultSuccess) {
              _navigateToResultScreen(state.result);
            }
          },

          child: Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
              automaticallyImplyLeading: false,
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.white,
              leading: Align(
                alignment: Alignment.topLeft,
                child: IconButton(
                  onPressed: () => _showCancelTestDialog(context),
                  icon: SvgPicture.asset("assets/svg_icons/close_icon.svg"),
                ),
              ),
            ),
            body: SafeArea(
              child: BlocBuilder<NewResultCubit, NewResultState>(
                builder: (context, state) {
                  responseTimer?.cancel();

                  if (state is NewResultFailure) {
                    final isProfileError = state.error.contains(
                      "Profile data is incomplete.",
                    );
                    final iconAsset =
                        isProfileError
                            ? "assets/sagar/undraw_warning_tl76.svg"
                            : "assets/sagar/undraw_server-down_lxs9.svg";

                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 50,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Align(
                            alignment: Alignment.center,
                            child: SvgPicture.asset(iconAsset, height: 100),
                          ),
                          const SizedBox(height: 100),
                          Text(
                            "Something went wrong",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              color: const Color(0xFF252525),
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              height: 1.10,
                            ),
                          ),
                          const SizedBox(height: 15),
                          Visibility(
                            visible: state.error != "Error in breath sample",
                            replacement: Text(
                              "Error in breath sample",
                              style: GoogleFonts.poppins(
                                color: const Color(0xFF535359),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                height: 1.40,
                              ),
                            ),
                            child: RichText(
                              textAlign: TextAlign.center,
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: state.error,
                                    style: GoogleFonts.poppins(
                                      color: const Color(0xFF535359),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      height: 1.40,
                                    ),
                                  ),
                                  TextSpan(
                                    text:
                                        'Please try to take test again. If it still happens, please contact the support team.',
                                    style: GoogleFonts.poppins(
                                      color: const Color(0xFF535359),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w400,
                                      height: 1.40,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 25),
                          ElevatedButton(
                            onPressed: () {
                              _setCancelOrDisconnectFlag();
                              _navigateToDashboard();
                            },
                            style: ElevatedButton.styleFrom(
                              elevation: 0,
                              backgroundColor: const Color(0xFF308BF9),
                            ),
                            child: Text(
                              "Try Again (recommended)",
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: () {
                              // _setCancelOrDisconnectFlag();
                              // _navigateToDashboard();
                            },
                            child: Text(
                              "Contact support team",
                              style: GoogleFonts.poppins(
                                color: const Color(0xFF308BF9),
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                                decoration: TextDecoration.underline,
                                decorationColor: const Color(0xFF308BF9),
                                decorationThickness: 2,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return Center(
                    child: Stack(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 35,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildProgressIndicator(
                                1,
                                "Calculating your result",
                              ),
                              _buildProgressIndicator(
                                2,
                                "Analyzing your result",
                              ),
                              _buildProgressIndicator(
                                3,
                                "Generating your report",
                              ),
                              const Spacer(),
                              const Image(
                                image: AssetImage("assets/searching_file.gif"),
                              ),
                              const Spacer(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _callApi(BuildContext context, String deviceRawData) {
    try {
      deviceRawData = deviceRawData.replaceAll("/analize", "");
      final profile = widget.profileDetails;
      if (profile.clinicName == null ||
          profile.subjectId == null ||
          profile.gender == null ||
          profile.age == null ||
          profile.height == null) {
        context.read<NewResultCubit>().emitDataEmpty(
          400,
          "Profile data is incomplete.",
        );
        return;
      }

      setState(() {
        completedSteps = 2;
      });

      String testdata = deviceRawData;
      String subId = "${profile.clinicName!}\$${profile.subjectId!}";
      String gender = profile.gender!;
      String age = profile.age.toString();
      String height = profile.height.toString();
      String region = profile.region.toString();

      context.read<NewResultCubit>().fetchResults(
        testdata: testdata,
        subjectId: subId,
        gender: gender,
        age: age,
        height: height,
        region: region,
        blowData: BlowValuesHelper().getBlowString(widget.blowValuesList),
      );
    } catch (e) {
      if (_isDisposed) return;
    }
  }

  void _navigateToResultScreen(NewResultModel lifestyleJson) {
    if (Get.isOverlaysOpen) {
      Get.back(); // Close any open overlays/dialogs
    }

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

  Future<bool> _showCancelTestDialog(context) async {
    bool didCancel = false;

    showCancelTestBox(
      context: context,
      cancelTestButtonPressed: () {
        didCancel = true;
        Navigator.pop(context);
        _exitToDashboard();
      },
    );
    return didCancel;
  }

  @override
  void dispose() {
    _isDisposed = true;
    _controller.dispose();
    _usbDataSubscription?.cancel();
    _usbDataSubscription = null;
    responseTimer?.cancel();
    super.dispose();
  }

  void startWaitForResponse() {
    responseTimer = Timer(const Duration(minutes: 1), () {
      context.read<NewResultCubit>().emitNoResponse(
        408,
        "Timeout! No response from the server",
      );
    });
  }
}
