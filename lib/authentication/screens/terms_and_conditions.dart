import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:respyr_clinical/shared/colors.dart';
import 'package:respyr_clinical/shared/urls.dart';
import 'package:webview_flutter/webview_flutter.dart';

class TermsAndConditions extends StatefulWidget {
  const TermsAndConditions({super.key});

  @override
  State<TermsAndConditions> createState() => _TermsAndConditionsState();
}

class _TermsAndConditionsState extends State<TermsAndConditions> {
  late WebViewController _webViewController;
  final Uri uri = Uri.parse(Urls.termsAndConditions);
  bool isLoading = true;
  @override
  void initState() {
    super.initState();

    // Initialize WebViewController only on Android or iOS
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      _webViewController =
          WebViewController()
            ..setJavaScriptMode(JavaScriptMode.unrestricted)
            ..setBackgroundColor(
              Colors.transparent,
            ) // Avoid potential rendering issues
            ..setNavigationDelegate(
              NavigationDelegate(
                onPageStarted: (url) {
                  setState(() {
                    isLoading =
                        true; // Hide loading indicator when page finishes loading
                  });
                  debugPrint("Page started loading: $url");
                },
                onPageFinished: (url) {
                  setState(() {
                    isLoading =
                        false; // Hide loading indicator when page finishes loading
                  });
                  debugPrint("Page finished loading: $url");
                },
                onNavigationRequest: (NavigationRequest request) {
                  debugPrint("Navigation request: ${request.url}");
                  return NavigationDecision
                      .navigate; // Allow all navigation requests
                },
              ),
            )
            ..loadRequest(uri);
    }
  }

  Widget _buildBodyContent() {
    if (kIsWeb) {
      // Web platform does not support WebView
      return Center(
        child: Text(
          'Web platform not supported for WebView',
          style: GoogleFonts.mulish(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            color: AppColor.primaryBlackColor,
          ),
        ),
      );
    } else if (Platform.isAndroid || Platform.isIOS) {
      // Render WebView on supported platforms
      return Stack(
        children: [
          WebViewWidget(controller: _webViewController), // WebView content
          if (isLoading) // Show loading indicator when loading
            Container(
              color: AppColor.whiteColor,
              child: Center(
                child: CircularProgressIndicator(
                  color: AppColor.primaryBlueColor,
                ),
              ),
            ),
        ],
      );
    } else {
      // Fallback for unsupported platforms
      return Center(
        child: Text(
          'Unsupported platform',
          style: GoogleFonts.mulish(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            color: AppColor.primaryBlackColor,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            '',
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColor.primaryBlackColor,
            ),
          ),
          backgroundColor: AppColor.whiteColor,
          surfaceTintColor: AppColor.whiteColor,
        ),
        backgroundColor: AppColor.whiteColor,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: _buildBodyContent(),
          ),
        ),
      ),
    );
  }
}
