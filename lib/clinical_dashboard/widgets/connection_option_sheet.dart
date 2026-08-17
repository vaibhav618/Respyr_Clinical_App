import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

/// "Take test via" chooser: Bluetooth or USB, as two tappable option rows in
/// the same style as the dashboard's take-test sheet — drag handle, icon in a
/// tinted rounded square, label, chevron.
///
/// On iOS only Bluetooth exists, so the sheet auto-forwards there without
/// drawing anything.
class ConnectionOptionSheet extends StatefulWidget {
  final VoidCallback onBluetoothTap;
  final VoidCallback onUsbTap;

  const ConnectionOptionSheet({
    super.key,
    required this.onBluetoothTap,
    required this.onUsbTap,
  });

  @override
  State<ConnectionOptionSheet> createState() => _ConnectionOptionSheetState();
}

class _ConnectionOptionSheetState extends State<ConnectionOptionSheet> {
  bool _autoTriggered = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (Platform.isIOS && !_autoTriggered) {
      _autoTriggered = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onBluetoothTap();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (Platform.isIOS) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              "Take test via",
              style: GoogleFonts.poppins(
                color: const Color(0xFF252525),
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 14),
            _option(
              iconPath: 'assets/icon_bluetooth.svg',
              label: 'Bluetooth',
              onTap: widget.onBluetoothTap,
            ),
            const SizedBox(height: 10),
            _option(
              iconPath: 'assets/carbon_usb.svg',
              label: 'USB cable',
              onTap: widget.onUsbTap,
            ),
          ],
        ),
      ),
    );
  }

  Widget _option({
    required String iconPath,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Row(
            children: [
              Container(
                height: 40,
                width: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFF308BF9).withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SvgPicture.asset(
                  iconPath,
                  height: 22,
                  width: 22,
                  colorFilter: const ColorFilter.mode(
                    Color(0xFF308BF9),
                    BlendMode.srcIn,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF252525),
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFFA1A1A1),
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
