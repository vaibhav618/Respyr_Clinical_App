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
import 'package:shared_preferences/shared_preferences.dart';

// ✅ ADDED
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import 'package:respyr_clinical/clinical_app_respyr/screens/bluetooth_test/screens/bluetooth_clinical_breathe_tube.dart';
import 'package:respyr_clinical/clinical_app_respyr/screens/bluetooth_test/services/clinical_bluetooth_manager.dart';
import 'package:respyr_clinical/clinical_app_respyr/screens/usb_test/services/clinical_usb_communication_services.dart';
import 'package:respyr_clinical/clinical_app_respyr/services/device_last_reading_time.dart';
import 'package:respyr_clinical/clinical_app_respyr/services/disconnected_error.dart';
import 'package:respyr_clinical/shared/colors.dart';
import 'package:respyr_clinical/shared/otg_connection.dart';
import 'package:respyr_clinical/shared/text_string.dart';

import '../../../../router/app_routers.dart';
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
  StreamSubscription<bool>? _connectionSub;

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

  bool _navigatedToNext = false;
  bool _hasSentBraceCommand = false;
  bool _receivedPercentResponse = false;

  bool _isConnectingInProgress = false;

  Timer? _connectingTimer;
  Timer? _batteryCaptureTimeoutTimer;

  String _connectionStatusText = "Not Connected";

  final storage = GetStorage();
  Key _freshKey = UniqueKey();

  // ✅ prevents attaching multiple listeners
  bool _listenersAttached = false;

  // ✅ de-dup quick repeats (prevents “same message printed twice”)
  String _lastMsg = "";
  int _lastMsgAtMs = 0;
  static const int _dedupWindowMs = 200;

  @override
  void initState() {
    super.initState();

    _attachListenersOnce();

    // Sync UI with existing BLE connection
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncUiWithExistingConnection();
    });
  }

  void _attachListenersOnce() {
    if (_listenersAttached) return;
    _listenersAttached = true;

    _setupConnectionStatusListener();
    _startDataListener();
  }

  void _syncUiWithExistingConnection() {
    if (!mounted || _isDisposed) return;

    final alreadyConnected = _bleManager.isConnected;

    setState(() {
      _isConnected = alreadyConnected;
      isScanningDevice = false;
      _connectionStatusText = alreadyConnected ? "Connected" : "Not Connected";
      _isButtonEnabled = alreadyConnected;
    });
  }

  @override
  void dispose() {
    _stopAllProcesses();
    super.dispose();
  }

  void _stopAllProcesses() {
    _isDisposed = true;
    _isDialogShowing = false;

    _dataStreamSubscription?.cancel();
    _dataStreamSubscription = null;

    _connectionSub?.cancel();
    _connectionSub = null;

    _connectingTimer?.cancel();
    _connectingTimer = null;

    _batteryCaptureTimeoutTimer?.cancel();
    _batteryCaptureTimeoutTimer = null;
  }

  // -----------------------------
  // ✅ UPDATED: Ensure Bluetooth is ON (Android + iOS)
  // -----------------------------
  Future<bool> _ensureBluetoothOn() async {
    if (!mounted || _isDisposed) return false;

    BluetoothAdapterState state;
    try {
      state = await FlutterBluePlus.adapterState.first;
    } catch (_) {
      state = BluetoothAdapterState.unknown;
    }

    if (state == BluetoothAdapterState.on) return true;

    if (Platform.isIOS) {
      final openSettings = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          title: const Text("Turn on Bluetooth"),
          content: const Text(
            "Bluetooth is turned OFF. Please turn it ON from iPhone Settings to connect with the device.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Open Settings"),
            ),
          ],
        ),
      );

      if (openSettings == true) {
        await openAppSettings();
      }
      return false;
    }

    if (Platform.isAndroid) {
      final turnOn = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          title: const Text("Turn on Bluetooth"),
          content: const Text(
            "Bluetooth is turned OFF. Please turn it ON to connect with the device.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Turn ON"),
            ),
          ],
        ),
      );

      if (turnOn != true) return false;

      try {
        await FlutterBluePlus.turnOn();
      } catch (_) {}

      await Future.delayed(const Duration(seconds: 2));

      BluetoothAdapterState newState;
      try {
        newState = await FlutterBluePlus.adapterState.first;
      } catch (_) {
        newState = BluetoothAdapterState.unknown;
      }

      if (newState != BluetoothAdapterState.on) {
        await openAppSettings();
        return false;
      }

      return true;
    }

    return true;
  }

  // -----------------------------
  // Connection Listener
  // -----------------------------
  void _setupConnectionStatusListener() {
    _connectionSub?.cancel();

    _connectionSub = _bleManager.connectionStatusStream.listen((isConnected) {
      if (!mounted || _isDisposed) return;

      if (isConnected) {
        _hasShownDisconnectedDialog = false;
        _hasShownRetryDialog = false;
        _isConnectingInProgress = false;
        _connectingTimer?.cancel();
      } else {
        if (!_isDisposed &&
            !isScanningDevice &&
            !_isDialogShowing &&
            !_hasShownDisconnectedDialog &&
            !_navigatedToNext) {
          Future.delayed(const Duration(milliseconds: 350)).then((_) {
            if (!mounted || _isDisposed || _navigatedToNext) return;
            _handleDisconnection();
          });
        }
      }

      setState(() {
        _isConnected = isConnected;
        if (!isConnected && isScanningDevice == false) {
          _connectionStatusText = "Not Connected";
        } else if (isConnected) {
          _connectionStatusText = "Connected";
        }
      });
    });
  }

  void _handleDisconnection() {
    if (_isDisposed ||
        _isConnected ||
        isScanningDevice ||
        _isDialogShowing ||
        _hasShownDisconnectedDialog ||
        _hasShownRetryDialog ||
        _navigatedToNext) {
      return;
    }

    _isDialogShowing = true;
    _hasShownDisconnectedDialog = true;

    showDeviceDisconnectedBox(
      context: context,
      onButtonPressed: () async {
        if (_isDisposed) return;

        _isDialogShowing = false;
        if (Navigator.of(context).canPop()) {
          Navigator.pop(context);
        }

        await Future.delayed(const Duration(milliseconds: 250));
        await _connect();
      },
    );
  }

  // -----------------------------
  // Data Listener
  // -----------------------------
  void _startDataListener() {
    _dataStreamSubscription?.cancel();

    _dataStreamSubscription = _bleManager.receivedDataStream.listen(
          (raw) async {
        if (!mounted || _isDisposed || _navigatedToNext) return;

        String data = raw.trim();

        // ✅ de-dup: ignore same msg within small window
        final now = DateTime.now().millisecondsSinceEpoch;
        if (data.isNotEmpty &&
            data == _lastMsg &&
            (now - _lastMsgAtMs) <= _dedupWindowMs) {
          return;
        }
        _lastMsg = data;
        _lastMsgAtMs = now;

        debugPrint("📨 Received: '$data'");

        if (data.contains("120")) {
          if (mounted) {
            setState(() {
              _freshKey = UniqueKey();
            });
          }
        }

        // Step 1: Confirm device ON
        if (data == "%" && !_receivedPercentResponse && _hasSentBraceCommand) {
          _receivedPercentResponse = true;
          debugPrint(
              "✅ Device turned ON. Skipping battery, waiting for Hardware ID...");

          if (mounted && !_isDisposed && !_isButtonEnabled) {
            setState(() {
              _isButtonEnabled = true;
            });
          }

          await _navigateToNextIfNeeded();
          return;
        }

        // Step 2: Hardware ID
        if (data.startsWith("H") && !isHardwareIdProcessed) {
          final id = data.replaceFirst("H", "").trim();

          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('hardware_id', id);

          _processHardwareId(id);

          if (mounted) {
            setState(() => isHardwareIdProcessed = true);
          }

          await _navigateToNextIfNeeded();
        }
      },
      onError: (e) => debugPrint("❌ Stream Error: $e"),
      onDone: () => debugPrint("ℹ️ Stream closed"),
    );
  }

  Future<void> _navigateToNextIfNeeded() async {
    if (_navigatedToNext) return;
    if (!mounted || _isDisposed) return;

    _navigatedToNext = true;

    // ✅ Cancel BOTH streams before navigation
    await _dataStreamSubscription?.cancel();
    _dataStreamSubscription = null;

    await _connectionSub?.cancel();
    _connectionSub = null;

    _connectingTimer?.cancel();
    _connectingTimer = null;

    if (!mounted || _isDisposed) return;

    Get.offAll(
          () => BluetoothBreatheTube(
        profileDetails: widget.profileDetails,
      ),
    );
  }

  // -----------------------------
  // Connect Flow
  // -----------------------------
  Future<void> _connect() async {
    if (_isDisposed || !mounted) return;
    if (_isConnectingInProgress) return;

    _isConnectingInProgress = true;

    try {
      final isPermissionGranted = await checkAndRequestPermissions();
      if (!isPermissionGranted) {
        _isConnectingInProgress = false;
        _handleError("Permissions are required to connect to the device.");
        return;
      }

      final btOn = await _ensureBluetoothOn();
      if (!btOn) {
        _isConnectingInProgress = false;
        if (mounted && !_isDisposed) {
          setState(() {
            isScanningDevice = false;
            _connectionStatusText = "Not Connected";
            _isButtonEnabled = false;
          });
        }
        return;
      }

      _hasShownRetryDialog = false;
      _hasShownDisconnectedDialog = false;

      _hasSentBraceCommand = false;
      _receivedPercentResponse = false;

      if (mounted) {
        setState(() {
          isScanningDevice = true;
          _connectionStatusText = "Scanning...";
          _isButtonEnabled = false;
          isHardwareIdProcessing = false;
          isHardwareIdProcessed = false;
          isHardwareIdProcessedErrorOccurred = false;
        });
      }

      if (_bleManager.isConnected) {
        await _bleManager.disconnect();
        await Future.delayed(const Duration(milliseconds: 600));
        _bleManager.reset();
      }

      _connectingTimer?.cancel();
      _connectingTimer = Timer(const Duration(seconds: 30), () {
        if (_isDisposed || !mounted) return;

        if (!_bleManager.isConnected && !_hasShownRetryDialog) {
          setState(() {
            isScanningDevice = false;
            _connectionStatusText = "Not Connected";
            _hasShownRetryDialog = true;
          });
          _showRetryDialog();
        }
      });

      await _bleManager.scanAndConnect();

      if (_isDisposed || !mounted) return;

      final connectedNow = _bleManager.isConnected;
      setState(() {
        _isConnected = connectedNow;
        isScanningDevice = false;
        _connectionStatusText = connectedNow ? "Connected" : "Not Connected";
        _isButtonEnabled = connectedNow;
      });

      _connectingTimer?.cancel();
      _connectingTimer = null;
    } catch (e) {
      if (kDebugMode) print("❌ _connect() error: $e");
      if (mounted && !_isDisposed) {
        setState(() {
          isScanningDevice = false;
          _connectionStatusText = "Not Connected";
          _isButtonEnabled = false;
        });
      }
      _handleError("Failed to connect to the device.");
    } finally {
      _isConnectingInProgress = false;
    }
  }

  Future<void> _sendData(String data) async {
    if (_isDisposed || !mounted) return;
    debugPrint("📤 Sending: $data");
    await _bleManager.sendData(data);
    debugPrint("📤 Sent: $data");
  }

  Future<void> _processHardwareId(String hardwareId) async {
    try {
      if (!mounted || _isDisposed) return;

      debugPrint("🟢 _processHardwareId START");
      debugPrint("🔹 Hardware ID: $hardwareId");

      setState(() => isHardwareIdProcessing = true);

      debugPrint("📡 Calling fetchDeviceLastDataTime...");
      final response = await fetchDeviceLastDataTime(hardwareId);

      debugPrint("⬅️ API Raw Response: $response");

      final bool canUpdateUi = mounted && !_isDisposed;

      if (response.contains("Error")) {
        debugPrint("❌ API returned error");

        if (canUpdateUi) {
          setState(() {
            isHardwareIdProcessed = false;
            isHardwareIdProcessedErrorOccurred = true;
            isHardwareIdProcessing = false;
            _isButtonEnabled = true;
          });
        }
        return;
      }

      final String signal = getDeviceStartSignal(response);
      debugPrint("✅ Final Signal Selected: $signal");

      debugPrint("📤 Sending signal to device: $signal");
      await _sendData(signal);

      final prefs = await SharedPreferences.getInstance();
      debugPrint("🧹 Clearing old SharedPreference: isFirstReading");
      await prefs.remove("isFirstReading");

      debugPrint("💾 Saving new signal to SharedPreferences: $signal");
      await prefs.setString("isFirstReading", signal);

      // Re-check liveness here: several awaits (_sendData, SharedPreferences)
      // occur after `canUpdateUi` was captured, so the widget may have been
      // disposed in the meantime. Using the stale flag would call setState()
      // after dispose().
      if (mounted && !_isDisposed) {
        setState(() {
          isHardwareIdProcessed = true;
          isHardwareIdProcessing = false;
          _isButtonEnabled = false;
        });
      }

      debugPrint("🟢 _processHardwareId SUCCESS");
    } catch (e) {
      debugPrint("🔥 Exception in _processHardwareId: $e");

      if (mounted && !_isDisposed) {
        setState(() {
          isHardwareIdProcessing = false;
          isHardwareIdProcessed = false;
          isHardwareIdProcessedErrorOccurred = true;
          _isButtonEnabled = true;
        });

        _handleError("Failed to process hardware ID.");
      }
    }
  }

  // -----------------------------
  // UI + Dialog Helpers
  // -----------------------------
  void _handleError(String message) {
    if (!mounted || _isDisposed) return;

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

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: AppColor.whiteColor,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
          onPressed: () {
            _showCancelTestDialog(context);
          },
          icon: const Icon(Icons.close),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(),
              SvgPicture.asset(
                _isConnected
                    ? "assets/connected_devices.svg"
                    : "assets/not_connected.svg",
              ),
              _buildConnectionSubtitle(),
              const SizedBox(height: 10),
              _buildConnectionTitle(),
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(child: _buildBottomNavigationBar()),
    );
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

  Future<bool> _showCancelTestDialog(BuildContext context) async {
    bool didCancel = false;

    showCancelTestBox(
      context: context,
      cancelTestButtonPressed: () async {
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

  void abortProcess() {
    if (_isConnected) {
      _bleManager.sendData("&");
    }
  }

  Future<void> _exitToDashboard() async {
    _stopAllProcesses();
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

  Widget _buildBottomNavigationBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHardwareIdProcessingMessage(),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: _buildConnectOrProceedButton(),
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
    if (_bleManager.isConnected) {
      return ElevatedButton(
        onPressed: (isHardwareIdProcessing && !_isButtonEnabled)
            ? null
            : () async {
          if (!mounted || _isDisposed) return;

          setState(() {
            _isButtonEnabled = false;
            isHardwareIdProcessing = true;
          });

          try {
            if (_bleManager.isConnected && !isHardwareIdProcessed) {
              _hasSentBraceCommand = true;
              await _sendData("!");
            }
          } catch (_) {
            if (!mounted || _isDisposed) return;
            setState(() {
              isHardwareIdProcessing = false;
              _isButtonEnabled = true;
            });
          }
        },
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: isHardwareIdProcessing && !_isButtonEnabled
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
              color: isHardwareIdProcessed && !_isButtonEnabled
                  ? AppColor.textLightColor.withAlpha(74)
                  : AppColor.whiteColor,
            ),
          ],
        ),
      );
    }

    return ElevatedButton(
      onPressed: isScanningDevice
          ? null
          : () async {
        final ok = await checkAndRequestPermissions();
        if (!ok) {
          _handleError("Permissions are required to connect to the device.");
          return;
        }

        final btOn = await _ensureBluetoothOn();
        if (!btOn) return;

        await _connect();
      },
      style: ElevatedButton.styleFrom(
        elevation: 0,
        shadowColor: Colors.transparent,
        backgroundColor:
        isScanningDevice ? const Color(0xFFD9D9D9) : AppColor.primaryBlueColor,
      ),
      child: isScanningDevice
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

  void _showRetryDialog() {
    if (_isDisposed || _bleManager.isConnected || isScanningDevice || _isDialogShowing) {
      return;
    }

    _isDialogShowing = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
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
              _buildOkButtonCloseDialog(),
            ],
          ),
        ),
      ),
    ).then((_) {
      _isDialogShowing = false;
    });
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

  Widget _buildOkButtonCloseDialog() {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.045,
      width: double.infinity,
      child: TextButton(
        onPressed: () {
          if (Navigator.of(context).canPop()) Navigator.pop(context);
        },
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.all(Colors.transparent),
          foregroundColor: WidgetStateProperty.all(AppColor.primaryBlackColor),
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed) ||
                states.contains(WidgetState.hovered)) {
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

  // -----------------------------
  // Permissions
  // -----------------------------
  Future<bool> checkAndRequestPermissions() async {
    if (!Platform.isAndroid) return true;

    var locationStatus = await Permission.location.status;
    if (!locationStatus.isGranted) {
      final consent = await _showCustomLocationDialog();
      if (consent != true) return false;

      locationStatus = await Permission.location.request();
      if (!locationStatus.isGranted) {
        if (locationStatus.isPermanentlyDenied) {
          openAppSettings();
        }
        return false;
      }
    }

    var bluetoothScanStatus = await Permission.bluetoothScan.status;
    if (!bluetoothScanStatus.isGranted) {
      bluetoothScanStatus = await Permission.bluetoothScan.request();
      if (!bluetoothScanStatus.isGranted) return false;
    }

    var bluetoothConnectStatus = await Permission.bluetoothConnect.status;
    if (!bluetoothConnectStatus.isGranted) {
      bluetoothConnectStatus = await Permission.bluetoothConnect.request();
      if (!bluetoothConnectStatus.isGranted) return false;
    }

    return true;
  }

  Future<bool?> _showCustomLocationDialog() async {
    if (!mounted || _isDisposed) return false;

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
              onPressed: () => Navigator.of(context).pop(false),
            ),
            ElevatedButton(
              child: const Text("Continue"),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );
  }
}
