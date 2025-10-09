import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';

class CheckAbortSheet {
  static void show({
    required BuildContext context,
    VoidCallback? onTakeTextClick,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.white,
      builder: (context) {
        return _CoolingDownContent(onTakeTextClick: onTakeTextClick);
      },
    );
  }
}

class _CoolingDownContent extends StatefulWidget {
  final VoidCallback? onTakeTextClick;

  const _CoolingDownContent({this.onTakeTextClick});

  @override
  State<_CoolingDownContent> createState() => _CoolingDownContentState();
}

class _CoolingDownContentState extends State<_CoolingDownContent> {
  int _remainingSeconds = 60;
  bool _isButtonEnabled = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _calculateRemainingTime();
    _startTimer();
  }

  void _calculateRemainingTime() {
    final storage = GetStorage();
    final storedTimeStr = storage.read('cancel_or_disconnect_time');

    if (storedTimeStr != null) {
      final storedTime = DateTime.tryParse(storedTimeStr);
      if (storedTime != null) {
        final now = DateTime.now();
        final diff = now.difference(storedTime).inSeconds;
        final remaining = 60 - diff;
        if (remaining > 0) {
          _remainingSeconds = remaining;
        } else {
          _remainingSeconds = 0;
          _isButtonEnabled = true;
        }
      }
    }
  }

  void _startTimer() {
    if (_remainingSeconds <= 0) return;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds <= 1) {
        timer.cancel();
        setState(() {
          _remainingSeconds = 0;
          _isButtonEnabled = true;
        });
      } else {
        setState(() {
          _remainingSeconds--;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: const CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.close, size: 24, color: Colors.black),
                ),
              ),
            ),
            const SizedBox(height: 10),
            _isButtonEnabled
                ? SvgPicture.asset("assets/sagar/device_ready.svg")
                : SvgPicture.asset("assets/sagar/device_error.svg"),
            const SizedBox(height: 10),
            Text(
              _isButtonEnabled ? "Device is Ready Now" : "Device Cooling Down",
              style: GoogleFonts.poppins(
                color: const Color(0xFF252525),
                fontSize: 25,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _isButtonEnabled
                  ? "Device is ready now. You can continue with the test."
                  : "You aborted the previous test. Respyr needs to cool down. Please wait for 1 minute before starting the next test.",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: const Color(0xFF535359),
                fontSize: 15,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 10),
            if (_remainingSeconds > 0)
              Text(
                "$_remainingSeconds seconds",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  color: const Color(0xFF252525),
                  fontSize: 25,
                  fontWeight: FontWeight.w600,
                ),
              ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                    _isButtonEnabled
                        ? () {
                          Navigator.of(context).pop();
                          widget.onTakeTextClick
                              ?.call(); // Safely call callback
                        }
                        : null,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  backgroundColor: const Color(0xFF308BF9),
                  disabledBackgroundColor: const Color(0xFFA1A1A1),
                ),
                child: Text(
                  _isButtonEnabled ? "Start Test" : "Please wait...",
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
