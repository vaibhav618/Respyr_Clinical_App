import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:respyr_clinical/clinical_app_respyr/screens/usb_test/screens/usb_clinical_exhale_screen.dart';
import 'package:respyr_clinical/clinical_app_respyr/screens/usb_test/services/clinical_usb_communication_services.dart';
import 'package:respyr_clinical/clinical_app_respyr/services/disconnected_error.dart';
import 'package:respyr_clinical/widgets/internet_connectivity_check.dart';
import 'package:respyr_clinical/shared/audio_helper.dart';
import 'package:respyr_clinical/shared/colors.dart';
import 'package:respyr_clinical/shared/get_stored_data_text.dart';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../../new_result/data/model/result_profile_data_model.dart';
import '../../../../router/app_routers.dart';

class UsbClinicalInhaleScreen extends StatefulWidget {
  final bool isDeveloper;
  final ResultProfileDataModel profileDetails;
  const UsbClinicalInhaleScreen({
    super.key,
    this.isDeveloper = false,
    required this.profileDetails,
  });

  @override
  State<UsbClinicalInhaleScreen> createState() =>
      _UsbClinicalInhaleScreenState();
}

class _UsbClinicalInhaleScreenState extends State<UsbClinicalInhaleScreen> {
  Timer? _timer;
  int _counter = 8;

  /// Fires if the device never sends "blownow" after the countdown ends.
  Timer? _blowWatchdogTimer;
  bool _timeoutShown = false;
  bool _navigationToExhaleScreen = false;
  bool _isDisposed = false;
  String? _lastExtractedValue;

  final AudioHelper _audioHelper = AudioHelper();
  late StreamSubscription<String>? _usbDataSubscription;

  final ClinicalUsbCommunicationServices _usbService =
      ClinicalUsbCommunicationServices();
  bool _isConnected = false;
  bool _dialogShown = false;

  String? loginId;
  String? profileId;
  Color profileColor = const Color(0xFF99E37F);
  bool _hasInternet = true;
  bool _screenActive = true;
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted && _usbService.isConnected) {
        setState(() {
          _isConnected = true;
          _startTimer();
          _getUserId();
          _loadProfileColor();
          _initializeUsbConnection();
          _startInhaleVoice();
        });
      } else {
        _handleDisconnection();
      }
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
        _abortProcess();
        _exitToDashboard();
      },
    );
  }

  Future<void> _startInhaleVoice() async {
    await Future.delayed(const Duration(seconds: 1));
    _audioHelper.playInhaleAudio();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || _isDisposed || _navigationToExhaleScreen) {
        timer.cancel();
        return;
      }

      setState(() {
        _counter--;
      });

      if (_counter <= 0) {
        timer.cancel();
        // Countdown done — from here we're purely waiting on the device.
        _startBlowWatchdog();
      }
    });
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
              _audioHelper.stopAudio();
              _timer!.cancel();
              _timer = null;
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
    _usbDataSubscription = _usbService.dataStream.listen(_onUsbDataReceived);
  }

  void _onUsbDataReceived(String data) {
    if (!mounted || _isDisposed || !_screenActive) return;

    final match = RegExp(r'/[\d.]+/').firstMatch(data);
    final extractedValue = match?.group(0);

    if (extractedValue != null) {
      _lastExtractedValue = extractedValue;
    }

    // Check for blownow command
    if (data.contains("blownow") &&
        !_navigationToExhaleScreen &&
        _lastExtractedValue != null) {
      // Don't tear anything down before we know we can actually proceed:
      // cancelling the USB subscription here and then bailing out on the
      // internet check left the screen permanently stuck with no data feed.
      if (!_hasInternet) {
        debugPrint("❌ No internet — holding at inhale screen, will retry.");
        _pendingBlowValue = _lastExtractedValue;
        return;
      }

      _stopAllProcesses();
      _usbDataSubscription?.cancel();
      _navigateToUsbExhaleScreen(
        _lastExtractedValue!,
      ); // Use the last stored value
    }
  }

  /// A "blownow" that arrived while offline. Once connectivity returns we
  /// continue from it instead of stranding the user on this screen.
  String? _pendingBlowValue;

  void _resumePendingBlowIfAny() {
    if (_isDisposed || _navigationToExhaleScreen) return;
    final String? pending = _pendingBlowValue;
    if (pending == null || !_hasInternet) return;

    _pendingBlowValue = null;
    debugPrint("🔄 Internet back — resuming held blownow.");
    _stopAllProcesses();
    _usbDataSubscription?.cancel();
    _navigateToUsbExhaleScreen(pending);
  }

  /// Watchdog: the countdown finishes at 0 and then this screen simply waits
  /// for the device's "blownow". If that message never arrives — e.g. it was
  /// emitted while the app was backgrounded — the screen used to sit at 00
  /// forever with no feedback. Surface it instead.
  void _startBlowWatchdog() {
    _blowWatchdogTimer?.cancel();
    _blowWatchdogTimer = Timer(const Duration(seconds: 45), () {
      if (_isDisposed || _navigationToExhaleScreen || !mounted) return;
      if (_pendingBlowValue != null) return; // waiting on internet, not device
      debugPrint("⛔ Inhale screen: no blownow received — prompting user.");
      _showInhaleTimeout();
    });
  }

  void _showInhaleTimeout() {
    if (_isDisposed || !mounted || _timeoutShown) return;
    _timeoutShown = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Didn't get a response"),
        content: const Text(
          "We didn't receive the blow signal from the device. This can happen "
          "if the app was minimised during the test. Please start the test "
          "again.",
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              _abortProcess();
              await _exitToDashboard();
            },
            child: const Text("Back to dashboard"),
          ),
        ],
      ),
    );
  }

  void _navigateToUsbExhaleScreen(String data) {
    final baseValue = data;

    _navigationToExhaleScreen = true;
    Navigator.of(context).popUntil((route) => route.isFirst);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => UsbClinicalExhaleScreen(
              baseValue: baseValue,
              profileDetails: widget.profileDetails,
            ),
      ),
    ).then((_) {
      if (mounted) {
        setState(() {
          _navigationToExhaleScreen = false;
        });
      }
    });
  }

  Future<void> _setCancelOrDisconnectFlag() async {
    final storage = GetStorage();
    final DateTime now = DateTime.now();
    await storage.write('cancel_or_disconnect_time', now.toIso8601String());
  }

  void _stopAllProcesses() {
    _isDisposed = true;
    _usbDataSubscription?.cancel();
  }

  Future<bool> _showCancelTestDialog(context) async {
    bool didCancel = false;

    showCancelTestBox(
      context: context,
      cancelTestButtonPressed: () {
        didCancel = true;
        Navigator.pop(context);
        _timer!.cancel();
        _audioHelper.stopAudio();
        _abortProcess();
        _exitToDashboard();
      },
    );
    return didCancel;
  }

  Future<void> _exitToDashboard() async {
    _stopAllProcesses();
    _setCancelOrDisconnectFlag();
    if (mounted) {
      _navigateToDashboard();
    }
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

  void _navigateToDashboard() {
    if (Get.isOverlaysOpen) {
      Get.back(); // close any dialog/bottomsheet if open
    }

    Get.offAllNamed(
      AppRoutes.mainDashboard,
      arguments: {
        'profile_details': widget.profileDetails, // full ResultProfileDataModel
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

  PreferredSizeWidget? _buildAppBar() {
    if (!widget.isDeveloper) return null;

    return AppBar(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _isConnected
              ? Text(
                "Ble device connected",
                style: GoogleFonts.mulish(fontSize: 15, color: Colors.green),
              )
              : Text(
                "Ble device not connected",
                style: GoogleFonts.mulish(fontSize: 15, color: Colors.red),
              ),
          ElevatedButton(onPressed: () {}, child: const Text("Connect")),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _isDisposed = true;
    _timer?.cancel();
    _blowWatchdogTimer?.cancel();
    _usbDataSubscription?.cancel();
    _screenActive = false;

    super.dispose();
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
      onConnectivityChanged: (hasInternet) {
        if (!_screenActive) return;
        setState(() {
          _hasInternet = hasInternet;
        });
        // If a blow arrived while we were offline, continue it now.
        _resumePendingBlowIfAny();
      },
      onRetry: () async {
        _abortProcess();
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Stack(
                  children: [
                    Center(
                      child:
                          _counter > 4
                              ? const SizedBox(
                                height: 350,
                                width: 375,
                                child: Image(
                                  image: AssetImage(
                                    'assets/gif_images/inhale.gif',
                                  ),
                                ),
                              )
                              : SvgPicture.asset("assets/inhale_hold.svg"),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
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
                  ],
                ),
                Text(
                  _counter > 4 ? 'Deep Inhale' : 'Hold',
                  style: GoogleFonts.poppins(
                    fontSize: 25,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFA1A1A1),
                  ),
                ),
                Column(
                  children: [
                    Text(
                      '0$_counter',
                      style: GoogleFonts.roboto(
                        fontSize: 40,
                        fontWeight: FontWeight.w400,
                        color: AppColor.primaryBlackColor,
                      ),
                    ),
                    Text(
                      'sec',
                      style: GoogleFonts.roboto(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: AppColor.primaryBlackColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
