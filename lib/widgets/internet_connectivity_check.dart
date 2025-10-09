import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:respyr_clinical/shared/colors.dart';

class InternetConnectivityHandler extends StatefulWidget {
  final Widget child;
  final Function(bool hasInternet)? onConnectivityChanged;
  final bool isBody;
  final VoidCallback? onRetry;

  const InternetConnectivityHandler({
    super.key,
    required this.child,
    this.onConnectivityChanged,
    this.isBody = false,
    this.onRetry,
  });

  @override
  State<InternetConnectivityHandler> createState() =>
      _InternetConnectivityHandlerState();
}

class _InternetConnectivityHandlerState
    extends State<InternetConnectivityHandler> {
  late StreamSubscription<List<ConnectivityResult>> _subscription;
  bool _dialogShown = false;
  bool _hasInternet = true;

  @override
  void initState() {
    super.initState();
    _checkInitialConnection();

    // ✅ Using List<ConnectivityResult> as per your requirement
    _subscription = Connectivity().onConnectivityChanged.listen((
      List<ConnectivityResult> results,
    ) {
      final result =
          results.isNotEmpty ? results.first : ConnectivityResult.none;
      _handleConnectivityChanged(result);
    });
  }

  void _checkInitialConnection() async {
    final results = await Connectivity().checkConnectivity();
    final result = results.isNotEmpty ? results.first : ConnectivityResult.none;
    _handleConnectivityChanged(result);
  }

  void _handleConnectivityChanged(ConnectivityResult result) {
    final hasInternet = result != ConnectivityResult.none;

    if (_hasInternet != hasInternet) {
      setState(() {
        _hasInternet = hasInternet;
      });

      widget.onConnectivityChanged?.call(hasInternet);

      // ✅ Only show dialog when not in body mode
      if (!widget.isBody) {
        if (!hasInternet) {
          if (!_dialogShown && mounted) {
            _dialogShown = true;
            NoInternetDialog.show(
              context: context,
              onRetry: widget.onRetry,
            ).then((_) => _dialogShown = false);
          }
        } else {
          // Internet restored → close dialog if showing
          if (_dialogShown && mounted) {
            Navigator.of(context, rootNavigator: true).pop();
            _dialogShown = false;
          }
        }
      }
    }
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ✅ When isBody = true and offline, show only image + text (no retry)
    if (widget.isBody && !_hasInternet) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              "assets/sagar/undraw_server-down_lxs9.svg",
              height: 120,
            ),
            const SizedBox(height: 20),
            Text(
              "No Internet Connection",
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "Please check your connection and try again.",
              style: GoogleFonts.poppins(fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return widget.child;
  }
}

class NoInternetDialog {
  static Future<void> show({
    required BuildContext context,
    VoidCallback? onRetry,
  }) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          contentPadding: const EdgeInsets.all(30),
          backgroundColor: AppColor.whiteColor,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset(
                "assets/sagar/undraw_server-down_lxs9.svg",
                height: 100,
              ),
              const SizedBox(height: 20),
              Text(
                "Something went wrong",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 15),
              Text(
                "No internet connection detected. Please check your connection and try again.",
                style: GoogleFonts.poppins(fontSize: 12),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 25),
              ElevatedButton(
                onPressed: () async {
                  final prefs = await SharedPreferences.getInstance();
                  final loginId = prefs.getString('userLoginId') ?? "";

                  if (loginId.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("No Clinic ID found, please login again"),
                      ),
                    );
                    return;
                  }

                  Navigator.of(dialogContext).pop();
                  onRetry?.call();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF308BF9),
                ),
                child: Text(
                  "Try Again",
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
