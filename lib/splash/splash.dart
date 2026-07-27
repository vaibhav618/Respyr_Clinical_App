import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../clinical_dashboard/bloc/health_score_bloc.dart';
import '../../clinical_dashboard/views/clinical_dashboard.dart';
import '../authentication/screens/login_with_password.dart';
import '../authentication/services/clinical_token_generating_api.dart';
import '../clinical_dashboard/service/overall_data_by_date_service.dart';
import '../log_manager/log_manager.dart';
import '../shared/get_stored_data_text.dart';
import '../widgets/error.dart';

class Splash extends StatefulWidget {
  const Splash({super.key});

  @override
  State<Splash> createState() => _SplashState();
}

class _SplashState extends State<Splash> with WidgetsBindingObserver {
  String loadingText = "Loading";
  int dotCount = 0;
  Timer? _loadingTimer;
  Timer? _timeoutTimer;

  String? errorMessage;
  bool isLoading = true;
  bool unauthorized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Log app launch
    LogManager().logEvent(
      event: 'APP_LAUNCH',
      status: 'SUCCESS',
      details: 'Splash screen loaded',
    );

    // Animate loading dots
    _loadingTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (mounted) {
        setState(() {
          dotCount = (dotCount + 1) % 4;
        });
      }
    });

    // Timeout after 10 seconds if still loading
    _timeoutTimer = Timer(const Duration(seconds: 10), () {
      if (mounted && isLoading) {
        setState(() {
          errorMessage = "Something took too long. Please try again.";
          isLoading = false;
        });
        LogManager().logEvent(
          event: 'SPLASH_TIMEOUT',
          status: 'FAILED',
          details: 'Splash loading exceeded 10 seconds.',
        );
      }
    });

    _checkUserAndNavigate();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _loadingTimer?.cancel();
    _timeoutTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (unauthorized) {
      // Log unauthorized state
      LogManager().logEvent(
        event: 'UNAUTHORIZED_SESSION',
        status: 'FAILED',
        details: 'Session expired, redirecting to login.',
      );
      return _errorScaffold("Unauthorized: Session expired");
    }

    if (errorMessage != null) {
      // Log error
      LogManager().logEvent(
        event: 'SPLASH_ERROR',
        status: 'FAILED',
        details: errorMessage!,
      );
      return _errorScaffold(errorMessage!);
    }

    return Scaffold(
      backgroundColor: Color(0xFF308BF9),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            SvgPicture.asset("assets/business_logo.svg", height: 160),
            const Spacer(),
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
    );
  }

  Widget _errorScaffold(String message) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: ErrorsWidgets.otherError(errorMessage: message, context: context),
    );
  }

  Future<void> _checkUserAndNavigate() async {
    final storage = GetStorage();

    final bool isOtpVerified = storage.read('isOtpVerified') ?? false;
    final String loginId = storage.read('loginClinicalName') ?? "NA";

    LogManager().logEvent(
      event: 'CHECK_USER_STATUS',
      status: 'SUCCESS',
      details: 'Checking OTP verification: $isOtpVerified, loginId: $loginId',
      extra: {'isOtpVerified': isOtpVerified, 'loginId': loginId},
    );

    if (!isOtpVerified) {
      // Mark as not first launch, redirect to login
      await storage.write(GetStoredDataText.isFirstLaunch, false);
      await storage.write('isOtpVerified', true);

      LogManager().logEvent(
        event: 'NAVIGATE_TO_LOGIN',
        status: 'SUCCESS',
        details: 'OTP not verified, moving to login.',
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginWithPassword()),
        );
      }
    } else if (isOtpVerified && loginId != "NA") {
      LogManager().setUserId(loginId); // Set user for next logs
      await _getJwtTokenAndFetchData(loginId);
    } else {
      setState(() {
        errorMessage = "Session expired or incomplete. Please login again.";
        isLoading = false;
      });
      LogManager().logEvent(
        event: 'SPLASH_SESSION_ERROR',
        status: 'FAILED',
        details: 'Session expired or incomplete. loginId: $loginId',
      );
    }
  }

  Future<void> _getJwtTokenAndFetchData(String loginId) async {
    final result = await JwtApiHelper.fetchAndStoreJwtToken(loginId: loginId);

    if (!result.success) {
      setState(() {
        errorMessage = result.message;
        isLoading = false;
        unauthorized =
            result.message?.toLowerCase().contains("unauthorized") ?? false;
      });
      return;
    }

    // Navigate to dashboard if token is stored
    if (mounted) {
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
  }
}
