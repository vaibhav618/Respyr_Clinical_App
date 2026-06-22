import 'dart:async';
import 'dart:io'; // 👇 ADDED for secure Internet check

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:respyr_clinical/authentication/screens/login_screen.dart';
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
  bool _hasInternet = true; // 👇 NEW: Tracks internet state

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

    _initializeApp(); // 👇 NEW: Start controlled initialization
  }

  // 👇 NEW: Check Internet BEFORE checking user or fetching tokens
  Future<void> _initializeApp() async {
    setState(() {
      isLoading = true;
      _hasInternet = true;
      errorMessage = null;
    });

    bool isConnected = await _checkInternetConnection();

    if (!isConnected) {
      if (mounted) {
        setState(() {
          _hasInternet = false;
          isLoading = false;
        });
      }
      return; // 🛑 Stop here. Don't check the user yet.
    }

    // Internet is good! Start the timeout timer and fetch data.
    _startTimeoutTimer();
    _checkUserAndNavigate();
  }

  // 👇 NEW: Bulletproof internet check
  Future<bool> _checkInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        return true;
      }
    } on SocketException catch (_) {
      return false;
    }
    return false;
  }

  // 👇 CHANGED: Route timeout to No Internet UI instead of generic error
  void _startTimeoutTimer() {
    _timeoutTimer?.cancel();
    _timeoutTimer = Timer(const Duration(seconds: 10), () {
      if (mounted && isLoading) {
        setState(() {
          _hasInternet = false; // Show No Internet UI
          isLoading = false;
        });
        LogManager().logEvent(
          event: 'SPLASH_TIMEOUT',
          status: 'FAILED',
          details: 'Splash loading exceeded 10 seconds. Network assumed dead.',
        );
      }
    });
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
    // 👇 Prevent hardware back button from breaking the nav stack
    return PopScope(canPop: false, child: _buildBody());
  }

  Widget _buildBody() {
    // 👇 NEW: Block UI completely if no internet
    if (!_hasInternet) {
      return _buildNoInternetUI();
    }

    if (unauthorized) {
      LogManager().logEvent(
        event: 'UNAUTHORIZED_SESSION',
        status: 'FAILED',
        details: 'Session expired, redirecting to login.',
      );
      return _errorScaffold("Unauthorized: Session expired");
    }

    if (errorMessage != null) {
      LogManager().logEvent(
        event: 'SPLASH_ERROR',
        status: 'FAILED',
        details: errorMessage!,
      );
      return _errorScaffold(errorMessage!);
    }

    return Scaffold(
      backgroundColor: const Color(0xFF308BF9),
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

  // 👇 NEW: Dedicated No Internet Screen UI (Stays strictly inside Splash)
  Widget _buildNoInternetUI() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(),
              const Icon(
                Icons.wifi_off_rounded,
                size: 80,
                color: Color(0xFF535359),
              ),
              const SizedBox(height: 30),
              Text(
                "No Internet Connection",
                style: GoogleFonts.poppins(
                  color: const Color(0xFF252525),
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "Please check your mobile data or Wi-Fi network and try again.",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  color: const Color(0xFF757575),
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  height: 1.4,
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _initializeApp, // 👇 Retries check without routing
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF308BF9),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    "Try Again",
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
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
      _timeoutTimer?.cancel(); // Cancel timer on successful resolve
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
      LogManager().setUserId(loginId);
      await _getJwtTokenAndFetchData(loginId);
    } else {
      _timeoutTimer?.cancel();
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
    _timeoutTimer?.cancel(); // Cancel timer on response

    if (!result.success) {
      // 👇 NEW: If the API fails due to a network lag, catch it and show No Internet UI
      if (result.message?.toLowerCase().contains("socket") == true ||
          result.message?.toLowerCase().contains("timeout") == true ||
          result.message?.toLowerCase().contains("network") == true ||
          result.message?.toLowerCase().contains("connection") == true) {
        if (mounted) {
          setState(() {
            _hasInternet = false;
            isLoading = false;
          });
        }
        return;
      }

      // If it's a real API logic error (like invalid user), show the error screen.
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
