import 'dart:io';

import 'package:android_intent_plus/android_intent.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Asks the user (once) to exempt the app from battery optimization so
/// aggressive OEM power managers (MIUI in particular) stop killing it the
/// moment it goes to the background. On Xiaomi-family devices it also offers
/// the Autostart settings page, which is a separate MIUI switch.
///
/// This cannot make the app unkillable — nothing can — but it removes the
/// routine "killed within seconds of backgrounding" behaviour. The foreground
/// service still protects the critical result-generation flow independently.
class BatteryOptimizationHelper {
  static const String _promptedKey = 'battery_optimization_prompted_v1';

  static Future<void> ensureBackgroundReliability(BuildContext context) async {
    if (!Platform.isAndroid) return;

    final PermissionStatus status =
        await Permission.ignoreBatteryOptimizations.status;
    if (status.isGranted) return;

    // Only prompt once per install; users can always do it later via settings.
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_promptedKey) ?? false) return;
    await prefs.setBool(_promptedKey, true);

    if (!context.mounted) return;
    final bool? proceed = await _showExplainerDialog(context);
    if (proceed != true) return;

    await Permission.ignoreBatteryOptimizations.request();

    // MIUI has a second, independent switch (Autostart) that also causes
    // background kills. Offer to open its settings page directly.
    final androidInfo = await DeviceInfoPlugin().androidInfo;
    final String manufacturer = androidInfo.manufacturer.toLowerCase();
    final bool isMiui =
        manufacturer.contains('xiaomi') ||
        manufacturer.contains('redmi') ||
        manufacturer.contains('poco');
    if (!isMiui) return;

    if (!context.mounted) return;
    final bool? openAutostart = await _showAutostartDialog(context);
    if (openAutostart != true) return;

    try {
      const AndroidIntent intent = AndroidIntent(
        action: 'miui.intent.action.OP_AUTO_START',
        package: 'com.miui.securitycenter',
      );
      await intent.launch();
    } catch (_) {
      // MIUI version without that activity — fall back to app settings.
      await openAppSettings();
    }
  }

  static Future<bool?> _showExplainerDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => _brandedDialog(
        context: context,
        icon: Icons.battery_saver_outlined,
        title: "Keep Respyr running reliably",
        message:
            "Your phone's battery saver can close Respyr in the background, "
            "which interrupts test results and makes the app restart.\n\n"
            "Allow Respyr to run without battery restrictions to keep "
            "readings reliable.",
        confirmText: "Allow",
        cancelText: "Not now",
      ),
    );
  }

  static Future<bool?> _showAutostartDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => _brandedDialog(
        context: context,
        icon: Icons.settings_suggest_outlined,
        title: "One more step on Xiaomi",
        message:
            "Xiaomi phones also need Autostart enabled for Respyr.\n\n"
            "On the next screen, find Respyr Clinical and switch "
            "Autostart ON.",
        confirmText: "Open settings",
        cancelText: "Skip",
      ),
    );
  }

  static Widget _brandedDialog({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String message,
    required String confirmText,
    required String cancelText,
  }) {
    return AlertDialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 56,
            width: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFF308BF9).withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: const Color(0xFF308BF9), size: 28),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: const Color(0xFF252525),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: const Color(0xFF535359),
              fontSize: 12.5,
              height: 1.4,
            ),
          ),
        ],
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(
            cancelText,
            style: GoogleFonts.poppins(
              color: const Color(0xFF535359),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF308BF9),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          ),
          child: Text(
            confirmText,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
