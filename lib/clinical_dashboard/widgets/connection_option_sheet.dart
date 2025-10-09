import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

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
  bool isBluetoothClicked = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.32,
      padding: const EdgeInsets.all(16.0),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Take test via',
            style: GoogleFonts.mulish(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildConnectionOption(
                context: context,
                iconPath: 'assets/icon_bluetooth.svg',
                label: 'Bluetooth',
                onTap: () {
                  setState(() {
                    isBluetoothClicked = true;
                  });
                  widget.onBluetoothTap();
                },
              ),
              _buildConnectionOption(
                context: context,
                iconPath: 'assets/carbon_usb.svg',
                label: 'Cable',
                onTap: widget.onUsbTap,
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (isBluetoothClicked)
            Text(
              "Coming soon",
              style: GoogleFonts.mulish(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.green,
              ),
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildConnectionOption({
    required BuildContext context,
    required String iconPath,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.35,
        height: MediaQuery.of(context).size.height * 0.15,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(43),
              blurRadius: 9,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              iconPath,
              width: 40,
              height: 40,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.mulish(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF9A9A9A),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
