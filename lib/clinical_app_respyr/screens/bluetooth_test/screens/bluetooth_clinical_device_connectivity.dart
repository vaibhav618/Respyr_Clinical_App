import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:respyr_clinical/clinical_app_respyr/screens/bluetooth_test/screens/bluetooth_clinical_breathe_tube.dart';
import 'package:respyr_clinical/clinical_app_respyr/screens/bluetooth_test/services/clinical_bluetooth_manager.dart';
import 'package:respyr_clinical/clinical_app_respyr/screens/usb_test/services/clinical_usb_communication_services.dart';
import 'package:respyr_clinical/clinical_app_respyr/services/device_battery_utils.dart';
import 'package:respyr_clinical/clinical_app_respyr/services/device_last_reading_time.dart';
import 'package:respyr_clinical/clinical_app_respyr/services/disconnected_error.dart';
import 'package:respyr_clinical/clinical_dashboard/views/clinical_dashboard.dart';
import 'package:respyr_clinical/shared/colors.dart';
import 'package:respyr_clinical/shared/otg_connection.dart';
import 'package:respyr_clinical/shared/text_string.dart';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../../new_result/data/model/result_profile_data_model.dart';

class BluetoothClinicalDeviceConnectivity extends StatefulWidget {
  final ResultProfileDataModel profileDetails;

  const BluetoothClinicalDeviceConnectivity({
    super.key,
    required this.profileDetails,
  });

  @override
  State<BluetoothClinicalDeviceConnectivity> createState() =>
      _BluetoothClinicalDeviceConnectivityState();
}

class _BluetoothClinicalDeviceConnectivityState
    extends State<BluetoothClinicalDeviceConnectivity> {
  final ClinicalBluetoothManager _bleManager = ClinicalBluetoothManager();
  final ClinicalUsbCommunicationServices _usbService =
      ClinicalUsbCommunicationServices();

  StreamSubscription<String>? _dataStreamSubscription;

  bool _isConnected = false;
  bool isHardwareIdProcessed = false;
  bool isHardwareIdProcessedErrorOccurred = false;
  bool isHardwareIdProcessing = false;
  bool isScanningDevice = false;
  bool _isButtonEnabled = false;
  bool _isDisposed = false;
  bool _isDialogShowing = false;
  bool _hasShownDisconnectedDialog = false;
  bool _hasShownRetryDialog = false;
  bool _isBatteryCaptured = false;
  bool _navigatedToNext = false;
  bool _hasSentBraceCommand = false;
  bool _receivedPercentResponse = false;
  bool _voltageStreamActive = false;
  bool _isBatteryCaptureDelayCompleted = false;

  Timer? _connectingTimer;
  Timer? _connectionCheckTimer;
  Timer? _batteryCaptureTimeoutTimer;
  String _connectionStatusText = "Not Connected";
  final storage = GetStorage();
  int batteryPercentage = 0;

  @override
  void initState() {
    super.initState();
    _setupConnectionStatusListener();
    _startDataListener();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _isDialogShowing = false;
    _dataStreamSubscription?.cancel();
    _connectingTimer?.cancel();
    _connectionCheckTimer?.cancel();
    _batteryCaptureTimeoutTimer?.cancel();
    super.dispose();
  }

  void _setupConnectionStatusListener() {
    _bleManager.connectionStatusStream.listen((isConnected) {
      if (!mounted) return;

      if (isConnected) {
        _hasShownDisconnectedDialog = false;
      } else if (!_isDisposed &&
          !_isDialogShowing &&
          !_hasShownDisconnectedDialog &&
          !isScanningDevice) {
        Future.delayed(const Duration(milliseconds: 500)).then((_) {
          _handleDisconnection();
        });
      }

      setState(() {
        _isConnected = isConnected;
        isScanningDevice = false;
        _connectionStatusText = isConnected ? "Connected" : "Not Connected";
      });
    });

    // Prevent false disconnection detections
    _connectionCheckTimer?.cancel();
  }

  void _handleDisconnection() {
    if (_isDisposed ||
        _isConnected ||
        isScanningDevice ||
        _isDialogShowing ||
        _hasShownDisconnectedDialog ||
        _hasShownRetryDialog) {
      return;
    }

    _isDialogShowing = true;
    _hasShownDisconnectedDialog = true;

    showDeviceDisconnectedBox(
      context: context,
      onButtonPressed: () async {
        if (!_isDisposed) {
          _isDialogShowing = false;
          Navigator.pop(context);
          await Future.delayed(const Duration(milliseconds: 300));
          _connect();
        }
      },
    );
  }

  void _startDataListener() {
    _dataStreamSubscription?.cancel();

    _dataStreamSubscription = _bleManager.receivedDataStream.listen(
      (data) async {
        if (!mounted || _isDisposed) return;

        data = data.trim();
        debugPrint("📨 Received: '$data'");

        // Step 1: Confirm device ON
        if (data == "%" && !_receivedPercentResponse && _hasSentBraceCommand) {
          _receivedPercentResponse = true;
          debugPrint("✅ Device turned ON, requesting battery voltage...");
          await _sendData("@"); // Start voltage stream
          _voltageStreamActive = true;
          return;
        }

        // Step 2: Parse voltage data (latest valid value only)
        if (_receivedPercentResponse &&
            !_isBatteryCaptured &&
            data != "%" &&
            data.contains(RegExp(r'[0-9]'))) {
          final cleanedData = data.replaceAll("@", "").trim();
          final voltage = double.tryParse(cleanedData);

          if (voltage != null) {
            final percentage = BatteryUtils.calculateBatteryPercentage(voltage);

            setState(() {
              batteryPercentage = percentage;
              _isBatteryCaptured = true;
            });

            await storage.write('batteryPercentage', percentage);
            debugPrint("🔋 Voltage: $voltage → Battery %: $percentage");

            // Stop voltage stream
            if (_voltageStreamActive) {
              await _sendData("@");
              _voltageStreamActive = false;
            }

            // ✅ Immediately enable the button here
            if (mounted && !_isDisposed && !_isButtonEnabled) {
              setState(() {
                _isButtonEnabled = true;
              });
            }

            return;
          }

          return;
        }

        if (_isBatteryCaptured) {
          _isBatteryCaptureDelayCompleted = false; // Reset first
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              setState(() {
                _isBatteryCaptureDelayCompleted = true;
              });
            }
          });
        }

        // Step 4: Handle Hardware ID
        if (data.startsWith("H") && !isHardwareIdProcessed) {
          final id = data.replaceAll("H", "").trim();
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('hardware_id', id);

          _processHardwareId(id);
          setState(() => isHardwareIdProcessed = true);

          if (!_navigatedToNext && mounted) {
            setState(() => isHardwareIdProcessed = true);
            await _dataStreamSubscription?.cancel();
            if (!_isDisposed && mounted) {
              _navigatedToNext = true;
              Get.offAll(
                () =>
                    BluetoothBreatheTube(profileDetails: widget.profileDetails),
              );
            }
          }
        }
      },
      onError: (e) => debugPrint("❌ Stream Error: $e"),
      onDone: () => debugPrint("ℹ️ Stream closed"),
    );
  }

  Future<void> _connect() async {
    if (_isDisposed) return;

    try {
      await checkAndRequestPermissions();

      try {
        final usbDevices = await _usbService.listDevices();
        if (usbDevices.isNotEmpty) {
          if (!mounted) return;
          _showUsbAlreadyConnectedDialog();
          return;
        }
      } catch (e) {
        // Optionally handle USB service failure here
      }

      if (_isConnected) {
        await _bleManager.disconnect();
        await Future.delayed(const Duration(seconds: 2));
        _bleManager.reset();
      }

      setState(() {
        isScanningDevice = true;
        _isConnected = false;
        _connectionStatusText = "Scanning...";
        _hasSentBraceCommand = false;
      });

      _connectingTimer?.cancel();
      _connectingTimer = Timer(const Duration(seconds: 30), () {
        if (!_isConnected && mounted) {
          setState(() {
            isScanningDevice = false;
            _connectionStatusText = "Not Connected";
            _hasShownRetryDialog = true;
          });
          _showRetryDialog();
        }
      });

      await _bleManager.scanAndConnect();

      setState(() {
        _isConnected = true;
        _connectionStatusText = "Connected";
        _isButtonEnabled = true;
        isScanningDevice = false;
      });

      _connectingTimer?.cancel();

      if (!_hasSentBraceCommand) {
        await Future.delayed(const Duration(seconds: 1));
        await _sendData("{");
        _hasSentBraceCommand = true;
      }

      _batteryCaptureTimeoutTimer?.cancel();
      _batteryCaptureTimeoutTimer = Timer(const Duration(seconds: 90), () {
        if (!_isBatteryCaptured && mounted && !_isDisposed) {
          _showTechnicalErrorDialog();
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          isScanningDevice = false;
          _connectionStatusText = "Not Connected";
        });
      }
      _handleError("Failed to connect to the device.");
    }
  }

  Future<void> _sendData(String data) async {
    if (_isDisposed) return;
    debugPrint("📤 Sending: $data");
    await _bleManager.sendData(data);
    debugPrint("📤 Sent: $data");
  }

  Future<void> _processHardwareId(String hardwareId) async {
    try {
      if (!mounted) return;
      setState(() => isHardwareIdProcessing = true);

      String response = await fetchDeviceLastDataTime(hardwareId);
      if (response.contains("Error")) {
        if (!mounted) return;
        setState(() {
          isHardwareIdProcessed = false;
          isHardwareIdProcessedErrorOccurred = true;
          isHardwareIdProcessing = false;
          _isButtonEnabled = true;
        });
      } else {
        await _sendData(getDeviceStartSignal(response));
        if (!mounted) return;
        setState(() {
          isHardwareIdProcessed = true;
          _isButtonEnabled = false;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error processing hardware ID: $e");
      }
      if (!mounted) return;
      setState(() {
        isHardwareIdProcessing = false;
        isHardwareIdProcessed = false;
        isHardwareIdProcessedErrorOccurred = true;
      });
      _handleError("Failed to process hardware ID.");
    }
  }

  void _handleError(String message) {
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

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;

    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: AppColor.whiteColor,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          _handlePop(context);
        }
      },
      child: Scaffold(
        backgroundColor: AppColor.whiteColor,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Spacer(),
                    if (_isBatteryCaptured)
                      Text(
                        "$batteryPercentage%",
                        style: GoogleFonts.mulish(
                          color: AppColor.primaryBlackColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 8,
                        ),
                      ),
                    const SizedBox(width: 2),
                    if (_isBatteryCaptured)
                      BatteryUtils.batteryIndicatorWidget(batteryPercentage),
                    IconButton(
                      onPressed: () => _handlePop(context),
                      icon: SvgPicture.asset("assets/svg_icons/close_icon.svg"),
                    ),
                  ],
                ),
                Align(
                  alignment: Alignment.topCenter,
                  child: SvgPicture.asset(
                    _isConnected
                        ? "assets/connected_devices.svg"
                        : "assets/not_connected.svg",
                  ),
                ),
                SizedBox(height: height * 0.01),
                _buildConnectionSubtitle(),
                SizedBox(height: height * 0.05),
                _buildConnectionTitle(),
                SizedBox(height: height * 0.05),
                _buildOtgButton(width),
                SizedBox(height: height * 0.05),
              ],
            ),
          ),
        ),
        bottomNavigationBar: SafeArea(child: _buildBottomNavigationBar(height, width)),
      ),
    );
  }

  void _handlePop(BuildContext context) async {
    bool shouldExit = await _handleCancelTest();
    if (shouldExit) {
      // Using GetX for both levels of pop if desired:
      if (Get.isOverlaysOpen) Get.back(); // Close dialog if still open
      Get.back(result: true); // Pop the screen
    }
  }

  Future<bool> _handleCancelTest() async {
    bool confirmed = await showCancelTestDialog(Get.context!);
    if (confirmed) {
      Get.offAll(() => const ClinicalDashboardMain(loginId: ''));
    }
    return confirmed;
  }

  Widget _buildConnectionSubtitle() {
    return Center(
      child: Text(
        _isConnected
            ? ResString.connectedDeviceSubTitle
            : ResString.notConnectedDeviceSubTitle,
        textAlign: TextAlign.center,
        style: GoogleFonts.mulish(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          color: AppColor.textLightColor,
        ),
      ),
    );
  }

  Widget _buildConnectionTitle() {
    return Center(
      child: Text(
        _connectionStatusText,
        textAlign: TextAlign.center,
        style: GoogleFonts.poppins(
          fontSize: 25,
          fontWeight: FontWeight.w600,
          color: AppColor.primaryBlackColor,
        ),
      ),
    );
  }

  Widget _buildOtgButton(double width) {
    return !_isConnected && isScanningDevice
        ? Visibility(
          visible: true,
          child: Center(
            child: SizedBox(
              width: width * 0.5,
              child: TextButton(
                onPressed:
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const OtgConnection()),
                    ),
                style: ButtonStyle(
                  side: WidgetStateProperty.all(
                    BorderSide(color: AppColor.primaryBlueColor),
                  ),
                  backgroundColor: WidgetStateProperty.all(Colors.transparent),
                  overlayColor: WidgetStateProperty.resolveWith<Color?>((
                    Set<WidgetState> states,
                  ) {
                    if (states.contains(WidgetState.pressed)) {
                      return Colors.blue.withAlpha(47);
                    } else if (states.contains(WidgetState.hovered)) {
                      return Colors.blue.withAlpha(26);
                    }
                    return null;
                  }),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Text(
                      ResString.issuewithDevice,
                      style: GoogleFonts.mulish(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColor.primaryBlueColor,
                      ),
                    ),
                    SvgPicture.asset("assets/svg_icons/right_arrow_button.svg"),
                  ],
                ),
              ),
            ),
          ),
        )
        : const SizedBox.shrink();
  }

  Widget _buildBottomNavigationBar(double height, double width) {
    return SizedBox(
      height: height * 0.1,
      child: Column(
        children: [
          _buildHardwareIdProcessingMessage(),
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: SizedBox(
              height: height * 0.06,
              width: width * 0.9,
              child: _buildConnectOrProceedButton(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHardwareIdProcessingMessage() {
    if (isHardwareIdProcessedErrorOccurred) {
      return Text(
        "Something went wrong!! Please try again",
        style: GoogleFonts.roboto(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: Colors.redAccent.shade200,
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildConnectOrProceedButton() {
    if (_isConnected) {
      return ElevatedButton(
        onPressed:
            (isHardwareIdProcessing && !_isButtonEnabled) ||
                    !_isBatteryCaptured ||
                    !_isBatteryCaptureDelayCompleted
                ? null
                : () async {
                  setState(() {
                    _isButtonEnabled = false;
                    isHardwareIdProcessing = true;
                  });

                  try {
                    if (_bleManager.isConnected && !isHardwareIdProcessed) {
                      await _sendData("!");
                    }
                  } catch (e) {
                    if (mounted) {
                      setState(() {
                        isHardwareIdProcessing = false;
                        _isButtonEnabled = true;
                      });
                    }
                  }
                },
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor:
              isHardwareIdProcessing && !_isButtonEnabled
                  ? AppColor.textLightColor.withAlpha(74)
                  : AppColor.primaryBlueColor,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            isHardwareIdProcessing
                ? Text(
                  "Device getting ready!! Please wait",
                  style: GoogleFonts.roboto(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                )
                : Text(
                  ResString.next,
                  style: GoogleFonts.mulish(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            Icon(
              Icons.chevron_right_outlined,
              size: 24,
              color:
                  isHardwareIdProcessed && !_isButtonEnabled
                      ? AppColor.textLightColor.withAlpha(74)
                      : AppColor.whiteColor,
            ),
          ],
        ),
      );
    }

    return ElevatedButton(
      onPressed:
          isScanningDevice
              ? null
              : () async {
                bool isPermissionGranted = await checkAndRequestPermissions();
                if (isPermissionGranted) {
                  await _connect();
                } else {
                  _handleError(
                    "Permissions are required to connect to the device.",
                  );
                }
              },
      style: ElevatedButton.styleFrom(
        elevation: 0,
        shadowColor: Colors.transparent,
        backgroundColor:
            isScanningDevice
                ? const Color(0xFFD9D9D9)
                : AppColor.primaryBlueColor,
      ),
      child:
          isScanningDevice
              ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Connecting...",
                    style: GoogleFonts.mulish(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColor.textLightColor,
                    ),
                  ),
                  Icon(Icons.bluetooth, color: AppColor.textLightColor),
                ],
              )
              : Text(
                "Connect Device",
                style: GoogleFonts.mulish(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColor.whiteColor,
                ),
              ),
    );
  }

  void _showTechnicalErrorDialog() {
    if (!_isDialogShowing && mounted) {
      _isDialogShowing = true;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (_) => Dialog(
              backgroundColor: AppColor.whiteColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      "Technical Error",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFEA5455),
                      ),
                    ),
                    SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                    Text(
                      "The device could not respond properly. Please try again or check the device.",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        color: AppColor.textLightColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildHelpLink(),
                    SizedBox(height: MediaQuery.of(context).size.height * 0.01),
                    const Divider(),
                    _buildRetryButton(),
                  ],
                ),
              ),
            ),
      );
    }
  }

  void _showUsbAlreadyConnectedDialog() {
    if (!_isDialogShowing && mounted) {
      _isDialogShowing = true;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (_) => Dialog(
              backgroundColor: AppColor.whiteColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      "Device Connected via USB",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFEA5455),
                      ),
                    ),
                    SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                    Text(
                      "The device could not respond properly. Please try again or check the device.",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        color: AppColor.textLightColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildHelpLink(),
                    SizedBox(height: MediaQuery.of(context).size.height * 0.01),
                    const Divider(),
                    _buildRetryButton(),
                  ],
                ),
              ),
            ),
      ).then((_) {
        _isDialogShowing = false; // Reset flag after dialog closes
      });
    }
  }

  void _showRetryDialog() {
    if (_isDisposed || _isConnected || isScanningDevice || _isDialogShowing) {
      return;
    }

    _isDialogShowing = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => Dialog(
            backgroundColor: AppColor.whiteColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Scanning Timeout',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFEA5455),
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                  Text(
                    'Please re-try the Device Scanning',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      color: AppColor.textLightColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildHelpLink(),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.01),
                  const Divider(),
                  _buildRetryButton(),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildHelpLink() {
    return TextButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const OtgConnection()),
        );
      },
      style: TextButton.styleFrom(padding: EdgeInsets.zero),
      child: Text(
        "Still facing issue with connection",
        style: GoogleFonts.mulish(
          color: const Color(0xFF308BF9),
          fontSize: 12,
          fontWeight: FontWeight.w400,
          decoration: TextDecoration.underline,
          decorationColor: const Color(0xFF308BF9),
        ),
      ),
    );
  }

  Widget _buildRetryButton() {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.045,
      width: double.infinity,
      child: TextButton(
        onPressed: () async {
          Navigator.of(context).pop();
          Get.offAll(() => ClinicalDashboardMain(loginId: ''));
        },
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.all(Colors.transparent),
          foregroundColor: WidgetStateProperty.all(AppColor.primaryBlackColor),
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) {
              return AppColor.primaryBlueColor.withAlpha(47);
            }
            if (states.contains(WidgetState.hovered)) {
              return AppColor.primaryBlueColor.withAlpha(47);
            }
            return null;
          }),
        ),
        child: Text(
          'Ok',
          style: GoogleFonts.mulish(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: AppColor.primaryBlackColor,
          ),
        ),
      ),
    );
  }

  Future<bool> checkAndRequestPermissions() async {
    if (Platform.isAndroid) {
      if (kDebugMode) print("Checking Android permissions...");

      // Request Location permission
      var locationStatus = await Permission.location.status;
      if (!locationStatus.isGranted) {
        // Show custom dialog first
        bool? userConsent = await _showCustomLocationDialog();
        if (userConsent != true) {
          if (kDebugMode) print('User declined location permission.');
          return false;
        }
        locationStatus = await Permission.location.request();
        if (!locationStatus.isGranted) {
          if (kDebugMode) print('Location permission denied');
          if (locationStatus.isPermanentlyDenied) {
            openAppSettings();
          }
          return false;
        }
      } else {
        if (kDebugMode) print("Location permission already granted");
      }

      // Bluetooth Scan permission (Android 12+)
      var bluetoothScanStatus = await Permission.bluetoothScan.status;
      if (!bluetoothScanStatus.isGranted) {
        bluetoothScanStatus = await Permission.bluetoothScan.request();
        if (!bluetoothScanStatus.isGranted) return false;
      }

      // Bluetooth Connect permission (Android 12+)
      var bluetoothConnectStatus = await Permission.bluetoothConnect.status;
      if (!bluetoothConnectStatus.isGranted) {
        bluetoothConnectStatus = await Permission.bluetoothConnect.request();
        if (!bluetoothConnectStatus.isGranted) return false;
      }

      if (kDebugMode) print('All required Android permissions granted.');
      return true; // ✅ All permissions granted
    } else {
      if (kDebugMode) print("Not Android, skipping permission checks.");
      return true; // iOS or other platforms
    }
  }

  Future<bool?> _showCustomLocationDialog() async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Text("Location Permission Needed"),
          content: const Text(
            "To connect to nearby devices, we need access to your location. "
            "This is required for Bluetooth device scanning. Please grant permission.",
          ),
          actions: [
            TextButton(
              child: const Text("Cancel"),
              onPressed: () {
                Navigator.of(context).pop(false); // return false
              },
            ),
            ElevatedButton(
              child: const Text("Continue"),
              onPressed: () {
                Navigator.of(context).pop(true); // return true
              },
            ),
          ],
        );
      },
    );
  }
}
