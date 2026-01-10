import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';

import '../router/app_routers.dart';

class AuthLogout {
  AuthLogout._();

  static Future<void> logout(BuildContext context) async {
    // ✅ Show feedback immediately
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Logging out..."),
        duration: Duration(seconds: 2),
      ),
    );

    // ⏳ Wait for 2 seconds
    await Future.delayed(const Duration(seconds: 2));

    final storage = GetStorage();

    // 🔥 Clear auth/session data
    await storage.remove('corporate_email');
    await storage.remove('clinic_name');
    await storage.remove('loginClinicalName');
    await storage.remove('isOtpVerified');
    await storage.remove('role');

    if (!context.mounted) return;

    // 🚀 Clear stack & go to Sign In
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.signIn,
          (route) => false,
    );
  }
}
