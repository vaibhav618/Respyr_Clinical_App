import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:respyr_clinical/authentication/screens/login_with_password.dart';


import '../authentication/screens/login_screen.dart';
import '../utils/logout.dart'; // ✅ update with correct path

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class JwtHttpClient extends http.BaseClient {
  final http.Client _inner = http.Client();
  final String jwtToken;
  static bool _handledOnce = false;

  JwtHttpClient(this.jwtToken);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    request.headers['Authorization'] = 'Bearer $jwtToken';

    final response = await _inner.send(request);

    if (response.statusCode == 401 && !_handledOnce) {
      _handledOnce = true;
      _handleTokenExpired();
    }

    return response;
  }

  void _handleTokenExpired() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final context = navigatorKey.currentContext;
      if (context != null) {
        showDialog(
          context: context,
          barrierDismissible: false, // ❌ user can't dismiss the dialog
          builder: (_) => AlertDialog(
            title: const Text("Session Expired"),
            content: const Text("Your session has expired. Please login again."),
            actions: [
              TextButton(
                onPressed: () async {
                  Navigator.of(context).pop(); // close dialog

                  // ✅ Clear all app data
                  await clearAllAppData();

                  // ✅ Navigate to login and remove all routes
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginWithPassword()),
                        (route) => false,
                  );
                },
                child: const Text("OK"),
              ),
            ],
          ),
        );
      }
    });
  }
}
