import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:respyr_clinical/shared/urls.dart';
import 'package:webview_flutter/webview_flutter.dart';

class ForgotPassword extends StatefulWidget {
  const ForgotPassword({super.key});

  @override
  State<ForgotPassword> createState() => _ForgotPasswordState();
}

class _ForgotPasswordState extends State<ForgotPassword> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)

    // 🔗 JavaScript to Flutter Channel
      ..addJavaScriptChannel(
        'FlutterChannel',
        onMessageReceived: (JavaScriptMessage message) {


          if (message.message == "password_updated") {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("✅ Password updated successfully."),
                duration: Duration(seconds: 2),
              ),
            );

            Future.delayed(const Duration(seconds: 2), () {
              Navigator.pop(context); // 👈 Go back after 2 seconds
            });

          } else if (message.message == "update_failed") {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("❌ Password update failed.")),
            );

          } else if (message.message == "update_error") {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("⚠️ Error occurred while updating password.")),
            );
          }



        },
      )

      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (NavigationRequest request) {
            return NavigationDecision.navigate; // Allow all links
          },
        ),
      )
      ..loadRequest(
        Uri.parse(Urls.forgotPasswordPortal),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:  Text("Reset your password", style: GoogleFonts.poppins(
          color: const Color(0xFF5A5A5A),
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.80,
        ),),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 1,
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}
