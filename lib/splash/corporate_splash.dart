import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';

import '../router/app_routers.dart';

class CorporateSplash extends StatefulWidget {
  const CorporateSplash({super.key});

  @override
  State<CorporateSplash> createState() => _CorporateSplashState();
}

class _CorporateSplashState extends State<CorporateSplash> {
  static const int _totalSeconds = 3; // ✅ 3 seconds only
  late Timer _timer;
  int _remainingSeconds = _totalSeconds;
  int dotCount = 0;

  final GetStorage _storage = GetStorage();

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {

      if (mounted) {
        setState(() {
          dotCount = (dotCount + 1) % 4;
        });
      }

      if (_remainingSeconds <= 1) {
        timer.cancel();
        _navigateNext();
      } else {
        setState(() => _remainingSeconds--);
      }
    });
  }

  void _navigateNext() {
    if (!mounted) return;

    final String role =
    (_storage.read('role') ?? '').toString().toLowerCase();
    final String email =
    (_storage.read('corporate_email') ?? '').toString();
    final String clinicName =
    (_storage.read('clinic_name') ?? '').toString();

    if (role == "corporate" && email.isNotEmpty && clinicName.isNotEmpty) {
      Navigator.pushReplacementNamed(
        context,
        AppRoutes.corporateDashboard,
        arguments: {
          "clinic_name": clinicName,
          "email": email,
          "role": role,
        },
      );
    } else {
      Navigator.pushReplacementNamed(context, AppRoutes.signIn);
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    String loadingText = "Loading";


    return Scaffold(
      backgroundColor: Color(0xFF308BF9),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Spacer(),
              SvgPicture.asset(
                "assets/business_logo.svg",
                height: 160,
              ),
              const SizedBox(height: 20),
              Spacer(),
              Padding(
                padding: const EdgeInsets.only(bottom: 32),
                child: Center(
                  child: Text(
                    "$loadingText${'.' * dotCount}",
                    style: GoogleFonts.mulish(
                      color: const Color(0xFF535359),
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      height: 1.10,
                      letterSpacing: -0.24,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
