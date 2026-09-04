import 'dart:io';

import 'package:respyr_clinical/widgets/shimmer_placeholders.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:respyr_clinical/shared/colors.dart';
import 'package:respyr_clinical/shared/nodeurl.dart';
import 'package:webview_flutter/webview_flutter.dart';

class PrivacyPolicy extends StatefulWidget {
  const PrivacyPolicy({super.key});

  @override
  State<PrivacyPolicy> createState() => _PrivacyPolicyState();
}

class _PrivacyPolicyState extends State<PrivacyPolicy> {
  late WebViewController _webViewController;
  final Uri uri = Uri.parse(NodeUrls.privacyPolicy);
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
                    isLoading = true;
                  });
                  debugPrint("Page started loading: $url");
                },
                onPageFinished: (url) {
                  setState(() {
                    isLoading = false;
                  });
                  debugPrint("Page finished loading: $url");
                },
                onNavigationRequest: (NavigationRequest request) {
                  // Handle navigation requests if needed
                  return NavigationDecision.navigate;
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
          if (isLoading) // Article-shaped skeleton while the page loads
            const Positioned.fill(child: ArticleShimmer()),
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
