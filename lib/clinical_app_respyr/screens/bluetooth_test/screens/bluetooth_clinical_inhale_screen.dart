import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:respyr_clinical/clinical_app_respyr/screens/bluetooth_test/screens/bluetooth_clinical_exhale_screen.dart';
import 'package:respyr_clinical/clinical_app_respyr/screens/bluetooth_test/services/clinical_bluetooth_manager.dart';
import 'package:respyr_clinical/clinical_app_respyr/services/disconnected_error.dart';
import 'package:respyr_clinical/shared/audio_helper.dart';
import 'package:respyr_clinical/shared/colors.dart';

import '../../../../new_result/data/model/result_profile_data_model.dart';
import '../../../../router/app_routers.dart';

class BluetoothInhaleScreen extends StatefulWidget {
  final bool isDeveloper;
  final ResultProfileDataModel profileDetails;
  const BluetoothInhaleScreen({
    super.key,
    this.isDeveloper = false,
    required this.profileDetails,
  });

  @override
  State<BluetoothInhaleScreen> createState() => _BluetoothInhaleScreenState();
}

class _BluetoothInhaleScreenState extends State<BluetoothInhaleScreen> {
  final ClinicalBluetoothManager _bleManager = ClinicalBluetoothManager();

  StreamSubscription<bool>? _connectionStatusSubscription;
  StreamSubscription<String>? _receivedDataSubscription;

  Timer? _timer;
  bool _isConnected = false;
  int _counter = 8;

  bool _isDisposed = false;
  bool _isDisconnectedPop = false;
  bool _hasShownDisconnectedDialog = false;

  // ✅ prevents handling blownow multiple times
  bool _handledBlowNow = false;

  // ✅ prevents attaching stream listeners multiple times
  bool _listenersAttached = false;

  final storage = GetStorage();
  final AudioHelper _audioHelper = AudioHelper();

  @override
  void initState() {
    super.initState();
    _isConnected = _bleManager.isConnected;

    _startTimer();
    _attachListenersOnce();
    _startInhaleVoice();
  }

  Future<void> _startInhaleVoice() async {
    await Future.delayed(const Duration(seconds: 1));
    if (_isDisposed) return;
    _audioHelper.playInhaleAudio();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || _isDisposed) {
        timer.cancel();
        return;
      }

      setState(() {
        _counter--;
      });

      if (kDebugMode) {
        print("Inhale Sec : $_counter");
      }

      if (_counter <= 0) {
        timer.cancel();
      }
    });
  }

  void _attachListenersOnce() {
    if (_listenersAttached) return;
    _listenersAttached = true;

    _connectionStatusSubscription =
        _bleManager.connectionStatusStream.listen((isConnected) {
          if (!mounted || _isDisposed) return;

          setState(() => _isConnected = isConnected);

          if (isConnected) {
            _isDisconnectedPop = false;
            _hasShownDisconnectedDialog = false;
          }

          if (!isConnected &&
              !_isDisposed &&
              !_isDisconnectedPop &&
              !_hasShownDisconnectedDialog) {
            Future.delayed(const Duration(milliseconds: 500)).then((_) {
              if (!mounted || _isDisposed || _isConnected) return;

              _setCancelOrDisconnectFlag();
              _timer?.cancel();
              _audioHelper.stopAudio();
              _handleDisconnection();
            });
          }
        }, onError: (_) {
          if (mounted) _showErrorDialog("Connection status error.");
        });

    _receivedDataSubscription = _bleManager.receivedDataStream.listen((data) {
      if (!mounted || _isDisposed) return;

      if (kDebugMode) {
        print("New Data Received InhaleScreen: $data");
      }

      // ✅ handle only ONCE
      if (!_handledBlowNow && data.contains("blownow")) {
        _handledBlowNow = true;

        // ✅ stop listening BEFORE navigation (prevents double receive)
        _stopAllProcesses();

        _goToExhaleScreen(baseValue: data);
      }
    }, onError: (_) {
      if (mounted) _showErrorDialog("Error receiving data from device.");
    });
  }

  void _handleDisconnection() {
    if (_isDisposed || _isConnected || _isDisconnectedPop || _hasShownDisconnectedDialog) return;

    _isDisconnectedPop = true;
    _hasShownDisconnectedDialog = true;

    showDeviceDisconnectedBox(
      context: context,
      onButtonPressed: () async {
        Get.back();
        _isDisconnectedPop = false;
        await Future.delayed(const Duration(milliseconds: 300));
        _setCancelOrDisconnectFlag();
        abortProcess();
        _navigateToDashboard();
      },
    );
  }

  void _goToExhaleScreen({required String baseValue}) {
    // ✅ replace route so inhale screen is disposed
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => BluetoothExhaleScreen(
          baseValue: baseValue,
          profileDetails: widget.profileDetails,
        ),
      ),
    );
  }

  Future<void> _setCancelOrDisconnectFlag() async {
    final DateTime now = DateTime.now();
    await storage.write('cancel_or_disconnect_time', now.toIso8601String());
  }

  void _stopAllProcesses() {
    _timer?.cancel();
    _timer = null;

    _audioHelper.stopAudio();

    _connectionStatusSubscription?.cancel();
    _connectionStatusSubscription = null;

    _receivedDataSubscription?.cancel();
    _receivedDataSubscription = null;
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
        _setCancelOrDisconnectFlag();
        await _exitToDashboard();
      },
    );

    return didCancel;
  }

  Future<void> _exitToDashboard() async {
    _stopAllProcesses();
    await _setCancelOrDisconnectFlag();
    if (mounted) _navigateToDashboard();
  }

  void _navigateToDashboard() {
    if (Get.isOverlaysOpen) Get.back();
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

  void _showErrorDialog(String message) {
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

  Future<void> _connectToDevice() async {
    try {
      await _bleManager.scanAndConnect();
    } catch (e) {
      _showErrorDialog("Failed to connect to the device.");
    }
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
          ElevatedButton(
            onPressed: _connectToDevice,
            child: const Text("Connect"),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _isDisposed = true;
    _stopAllProcesses();
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

    return PopScope(
      canPop: false,
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
                    child: _counter > 4
                        ? const SizedBox(
                      height: 350,
                      width: 375,
                      child: Image(
                        image: AssetImage('assets/gif_images/inhale.gif'),
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
    );
  }
}
