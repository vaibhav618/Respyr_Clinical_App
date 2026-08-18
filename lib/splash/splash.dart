import 'dart:async';
import 'dart:io'; // 👇 ADDED for secure Internet check

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
import '../router/app_routers.dart';
import '../shared/get_stored_data_text.dart';
import '../widgets/error.dart';

/// The launch screen, choreographed as a curtain piece:
///
/// OPEN — five dark-blue blinds slide up in stagger, unveiling the brand-blue
/// stage; the wordmark rises out of a mask line and its underline draws in.
/// HOLD — a sheen sweeps across the wordmark while the underline doubles as
/// the loader, a bright segment travelling it.
/// EXIT — the wordmark sinks back into its mask, then the whole blue sheet
/// lifts like a curtain, revealing the canvas the next screen enters on.
class Splash extends StatefulWidget {
  const Splash({super.key});

  @override
  State<Splash> createState() => _SplashState();
}

class _SplashState extends State<Splash>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  Timer? _timeoutTimer;

  /// Entrance: blinds, wordmark rise, underline draw — one timeline.
  late final AnimationController _intro;

  /// Ambient loop: the wordmark sheen and the loader segment.
  late final AnimationController _loop;

  /// Departure: wordmark sinks, curtain lifts.
  late final AnimationController _exit;

  /// When the splash appeared. On a fast network the session check resolves
  /// in well under a second — navigation used to cut away before the
  /// entrance had even finished, so the animation effectively never showed.
  final DateTime _shownAt = DateTime.now();

  /// Long enough for the entrance plus a couple of loader sweeps.
  static const Duration _minSplashTime = Duration(milliseconds: 2800);

  static const Color _blue = Color(0xFF308BF9);
  static const Color _blindBlue = Color(0xFF2578E5);

  /// Waits out whatever remains of the minimum display time.
  Future<void> _holdForIntro() async {
    final Duration elapsed = DateTime.now().difference(_shownAt);
    if (elapsed < _minSplashTime) {
      await Future.delayed(_minSplashTime - elapsed);
    }
  }

  /// The full departure: hold for the intro, play the exit, then hand off.
  Future<void> _exitAndNavigate(VoidCallback navigate) async {
    await _holdForIntro();
    if (!mounted) return;
    await _exit.forward();
    if (!mounted) return;
    navigate();
  }

  /// Incoming pages fade up over the white the curtain revealed — a soft
  /// landing that finishes the lift, instead of a route snap.
  Route<T> _fadeUpRoute<T>(Widget page) {
    return PageRouteBuilder<T>(
      transitionDuration: const Duration(milliseconds: 350),
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, animation, __, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween(
              begin: const Offset(0, 0.02),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  String? errorMessage;
  bool isLoading = true;
  bool unauthorized = false;
  bool _hasInternet = true; // 👇 NEW: Tracks internet state
  bool _retrying = false; // A retry from the no-internet screen is running.

  /// Finishes the choreography before a status screen appears: completes the
  /// entrance, stops the loop, lifts the curtain — so the no-internet and
  /// error states arrive on the revealed canvas instead of replacing the
  /// animation mid-frame with a hard cut.
  Future<void> _revealForStatus() async {
    if (_exit.value >= 1) return;
    await _intro.forward();
    if (!mounted) return;
    _loop.stop();
    await _exit.forward();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _intro = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _loop = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _exit = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );

    // The ambient loop begins exactly when the HOLD phase does. Free-running
    // it from launch meant the sheen and loader joined mid-cycle — popping
    // in partway through a sweep instead of starting one.
    _intro.addStatusListener((status) {
      if (status == AnimationStatus.completed &&
          mounted &&
          _exit.value == 0 &&
          !_loop.isAnimating) {
        _loop.repeat();
      }
    });

    // Motion waits for the engine's first frame plus a beat. Starting the
    // blinds in initState meant they animated through startup itself —
    // shader compilation, SVG parse, font load — which is exactly where
    // frames drop. Until then the screen is the closed curtain: a solid
    // sheet identical to the OS splash, so the wait is invisible.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // The launch log is an http POST on the UI isolate — it has no place
      // in the frames the blinds animate through.
      LogManager().logEvent(
        event: 'APP_LAUNCH',
        status: 'SUCCESS',
        details: 'Splash screen loaded',
      );
      Future.delayed(const Duration(milliseconds: 80), () {
        if (!mounted) return;
        _intro.forward();
      });
    });

    _initializeApp(); // 👇 NEW: Start controlled initialization
  }

  // 👇 NEW: Check Internet BEFORE checking user or fetching tokens
  Future<void> _initializeApp() async {
    setState(() {
      isLoading = true;
      // On a retry the no-internet page stays up (button spinning) rather
      // than flashing back to a splash whose curtain has already lifted.
      _retrying = !_hasInternet;
      errorMessage = null;
    });

    bool isConnected = await _checkInternetConnection();

    if (!isConnected) {
      if (mounted) {
        await _revealForStatus(); // Curtain up first — no hard cut.
        if (!mounted) return;
        setState(() {
          _hasInternet = false;
          _retrying = false;
          isLoading = false;
        });
      }
      return; // 🛑 Stop here. Don't check the user yet.
    }

    // Internet is good! Start the timeout timer and fetch data. A recovered
    // retry keeps the status page (spinner) until navigation replaces it.
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
    _timeoutTimer = Timer(const Duration(seconds: 10), () async {
      if (mounted && isLoading) {
        await _revealForStatus(); // Curtain up first — no hard cut.
        if (!mounted) return;
        setState(() {
          _hasInternet = false; // Show No Internet UI
          _retrying = false;
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
    _intro.dispose();
    _loop.dispose();
    _exit.dispose();
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

    // (The unauthorized/error log events fire once, at the setState sites
    // that raise these flags — not here in build, which re-ran them on
    // every rebuild.)
    if (unauthorized) {
      return _errorScaffold("Unauthorized: Session expired");
    }

    if (errorMessage != null) {
      return _errorScaffold(errorMessage!);
    }

    // The underlay: what the lifting curtain reveals, and what the next
    // screen fades up on — the exit shows it by MOVING to it, never by
    // cutting to it. Same canvas color as the destinations, so the route
    // swap lands on identical ground.
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final double screenH = constraints.maxHeight;

          // Each controller rebuilds only what it moves: the exit shifts the
          // sheet, the intro drives the blinds, and the small stage subtree
          // listens to all three. The full-screen Container/Stack/SafeArea
          // are built once and reused via `child` — not re-laid-out on every
          // tick of a 60fps loop.
          return AnimatedBuilder(
            animation: _exit,
            child: Container(
              color: _blue,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  SafeArea(
                    child: Center(
                      child: AnimatedBuilder(
                        animation: Listenable.merge([_intro, _loop, _exit]),
                        builder: (context, _) => _stage(),
                      ),
                    ),
                  ),
                  // The opening blinds, above the stage.
                  AnimatedBuilder(
                    animation: _intro,
                    builder: (context, _) => _blinds(screenH),
                  ),
                ],
              ),
            ),
            builder: (context, sheet) {
              // Curtain lift occupies the latter part of the exit, after the
              // wordmark has sunk away.
              final double lift = Curves.easeInOutCubic.transform(
                ((_exit.value - 0.30) / 0.70).clamp(0.0, 1.0),
              );

              return Transform.translate(
                offset: Offset(0, -screenH * lift),
                child: sheet,
              );
            },
          );
        },
      ),
    );
  }

  /// Five vertical blinds sliding up in stagger to unveil the stage.
  Widget _blinds(double screenH) {
    // The last blind clears the screen at 4 * 0.07 + 0.55 = 0.83 — past
    // that, nothing is visible, so nothing gets built.
    if (_intro.value >= 0.83) return const SizedBox.shrink();

    Widget blind(int i) {
      final double p = Curves.easeInOutCubic.transform(
        ((_intro.value - i * 0.07) / 0.55).clamp(0.0, 1.0),
      );
      // A blind that has finished its slide is fully off-screen: drop it
      // instead of compositing a translated screen-sized layer per frame.
      if (p >= 1) return const SizedBox.shrink();
      return Transform.translate(
        offset: Offset(0, -screenH * p),
        child: Container(color: _blindBlue),
      );
    }

    return IgnorePointer(
      child: Row(
        children: [for (int i = 0; i < 5; i++) Expanded(child: blind(i))],
      ),
    );
  }

  /// Wordmark rising out of its mask line, underline/loader beneath.
  Widget _stage() {
    const double markWidth = 190;
    const double markHeight = 50;

    final double rise = Curves.easeOutCubic.transform(
      ((_intro.value - 0.35) / 0.5).clamp(0.0, 1.0),
    );
    // On exit the mark sinks back into the mask before the curtain lifts.
    final double sink = Curves.easeIn.transform(
      (_exit.value / 0.35).clamp(0.0, 1.0),
    );
    final double lineIn = Curves.easeOutCubic.transform(
      ((_intro.value - 0.7) / 0.3).clamp(0.0, 1.0),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // The mask: the wordmark exists only above this line, so it rises
        // into view and sinks out of it, like type on a press.
        ClipRect(
          child: SizedBox(
            width: markWidth,
            height: markHeight,
            child: Transform.translate(
              offset: Offset(0, markHeight * (1 - rise) + markHeight * sink),
              child: _sheenedWordmark(markWidth),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _underlineLoader(lineIn, (1 - sink).clamp(0.0, 1.0)),
      ],
    );
  }

  /// The wordmark with a soft sheen band sweeping across it on loop.
  Widget _sheenedWordmark(double width) {
    // The sheen only means anything during the HOLD phase. Skipping the
    // ShaderMask outside it removes a per-frame saveLayer from the blinds
    // entrance and the curtain lift — the two moments least able to afford
    // one.
    if (!_intro.isCompleted || _exit.value > 0) {
      return Align(
        alignment: Alignment.bottomCenter,
        child: SvgPicture.asset("assets/respyr_logo_white.svg", width: width),
      );
    }

    final double sweep = _loop.value;

    return ShaderMask(
      shaderCallback: (bounds) {
        // A fixed-width band translated across the mark at constant speed,
        // entering from off-left and leaving off-right (clamp tiling keeps
        // everything outside the band transparent). The controller's 1 → 0
        // wrap happens while the band is off-canvas, so the sweep never
        // squashes against an edge or snaps.
        final double bandW = bounds.width * 0.45;
        final double dx = -bandW + (bounds.width + 2 * bandW) * sweep;
        return const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Colors.transparent, Color(0x33124B9E), Colors.transparent],
        ).createShader(
          Rect.fromLTWH(bounds.left + dx, bounds.top, bandW, bounds.height),
        );
      },
      blendMode: BlendMode.srcATop,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: SvgPicture.asset("assets/respyr_logo_white.svg", width: width),
      ),
    );
  }

  /// Draws in centre-out, then serves as the loader: a bright segment
  /// travelling the line. [fade] folds the exit fade-out into the paint
  /// colors — cheaper than an Opacity layer over the stack.
  Widget _underlineLoader(double lineIn, double fade) {
    const double lineWidth = 120;
    const double segWidth = 34;

    // Triangle-wave the loop value so the segment sweeps to the right and
    // glides back, instead of snapping to the left edge each time the
    // controller wraps 1 → 0.
    final double travel = Curves.easeInOut.transform(
      1 - (2 * _loop.value - 1).abs(),
    );

    return SizedBox(
      width: lineWidth,
      height: 3,
      child: Align(
        alignment: Alignment.center,
        child: FractionallySizedBox(
          widthFactor: lineIn,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Container(color: Colors.white.withValues(alpha: 0.30 * fade)),
                if (lineIn >= 1)
                  Align(
                    alignment: Alignment(-1 + 2 * travel, 0),
                    child: Container(
                      width: segWidth,
                      color: Colors.white.withValues(alpha: fade),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 👇 NEW: Dedicated No Internet Screen UI (Stays strictly inside Splash)
  Widget _buildNoInternetUI() {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        // Fades up onto the canvas the curtain revealed, the same landing
        // every other post-splash screen gets — not a pop.
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
          builder: (context, t, child) {
            return Opacity(
              opacity: t,
              child: Transform.translate(
                offset: Offset(0, 12 * (1 - t)),
                child: child,
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Spacer(),
                // Same empty-state shape as everywhere else in the app: icon in
                // a tinted circle, title, one-line explanation.
                Container(
                  height: 72,
                  width: 72,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFF308BF9).withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.wifi_off_rounded,
                    size: 34,
                    color: Color(0xFF308BF9),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  "No internet connection",
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF252525),
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Check your mobile data or Wi-Fi and try again.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF535359),
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    height: 1.4,
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    // 👇 Retries check without routing; spins while it runs.
                    onPressed: _retrying ? null : _initializeApp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF308BF9),
                      disabledBackgroundColor: const Color(
                        0xFF308BF9,
                      ).withValues(alpha: 0.5),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child:
                        _retrying
                            ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: Colors.white,
                              ),
                            )
                            : Text(
                              "Try again",
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -0.2,
                              ),
                            ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _errorScaffold(String message) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: ErrorsWidgets.otherError(errorMessage: message, context: context),
    );
  }

  Future<void> _checkUserAndNavigate() async {
    final storage = GetStorage();

    // ALL roles pass through this splash now. The router used to branch
    // here itself — saved-clinical users got this screen, corporate users a
    // separate static one, and everyone else (fresh installs, logged-out)
    // was thrown straight at sign-in, so the launch animation never played
    // for them at all.
    final String role = (storage.read('role') ?? '').toString().toLowerCase();

    if (role == 'corporate') {
      _timeoutTimer?.cancel();
      final String email = (storage.read('corporate_email') ?? '').toString();
      final String clinicName = (storage.read('clinic_name') ?? '').toString();

      await _exitAndNavigate(() {
        if (email.isNotEmpty && clinicName.isNotEmpty) {
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
      });
      return;
    }

    if (role != 'clinical') {
      // No session at all: on to the role chooser, after the intro.
      _timeoutTimer?.cancel();
      await _exitAndNavigate(() {
        Navigator.pushReplacementNamed(context, AppRoutes.signIn);
      });
      return;
    }

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

      await _exitAndNavigate(() {
        Navigator.pushReplacement(
          context,
          _fadeUpRoute(const LoginWithPassword()),
        );
      });
    } else if (isOtpVerified && loginId != "NA") {
      LogManager().setUserId(loginId);
      await _getJwtTokenAndFetchData(loginId);
    } else {
      _timeoutTimer?.cancel();
      await _revealForStatus(); // Curtain up first — no hard cut.
      if (!mounted) return;
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
          await _revealForStatus(); // Curtain up first — no hard cut.
          if (!mounted) return;
          setState(() {
            _hasInternet = false;
            _retrying = false;
            isLoading = false;
          });
        }
        return;
      }

      // If it's a real API logic error (like invalid user), show the error screen.
      await _revealForStatus(); // Curtain up first — no hard cut.
      if (!mounted) return;
      final bool isUnauthorized =
          result.message?.toLowerCase().contains("unauthorized") ?? false;
      setState(() {
        errorMessage = result.message;
        isLoading = false;
        unauthorized = isUnauthorized;
      });
      LogManager().logEvent(
        event: isUnauthorized ? 'UNAUTHORIZED_SESSION' : 'SPLASH_ERROR',
        status: 'FAILED',
        details: result.message ?? 'Unknown splash error',
      );
      return;
    }

    // Navigate to dashboard if token is stored
    await _exitAndNavigate(() {
      Navigator.pushReplacement(
        context,
        _fadeUpRoute(
          BlocProvider(
            create: (_) => HealthScoreBloc(OverallDataByDateService()),
            child: ClinicalDashboardMain(loginId: loginId),
          ),
        ),
      );
    });
  }
}
