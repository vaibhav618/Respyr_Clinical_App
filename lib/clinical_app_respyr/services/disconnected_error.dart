import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:respyr_clinical/shared/otg_connection.dart';

void showDeviceDisconnectedBox({
  required BuildContext context,
  required VoidCallback onButtonPressed, // Callback to listen for button click
}) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder:
        (context) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
            ),
            padding: const EdgeInsets.only(
              top: 50,
              left: 20,
              right: 20,
              bottom: 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min, // Adjust height based on content
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SvgPicture.asset("assets/not_connected.svg"),
                const SizedBox(height: 20),
                Text(
                  "Device Disconnected",
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF252525),
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    height: 1.10,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  "Please try connecting back respyr device to your phone and try again",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.mulish(
                    color: const Color(0xFF252525),
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 20), // Add spacing before buttons
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onButtonPressed,
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      shadowColor: Colors.transparent,
                      backgroundColor: const Color(0xFF308BF9),
                    ),
                    child: Text(
                      "Try again",
                      style: GoogleFonts.mulish(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                TextButton(
                  onPressed:
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const OtgConnection(),
                        ),
                      ),
                  style: TextButton.styleFrom(padding: EdgeInsets.zero),
                  child: Text(
                    "Still facing issue with connection",
                    style: GoogleFonts.mulish(
                      color: const Color(0xFF308BF9),
                      decoration: TextDecoration.underline,
                      decorationColor: const Color(0xFF308BF9),
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
  );
}

void showUsbReconnectionDialogBox({
  required BuildContext context,
  required VoidCallback onButtonPressed, // Callback to listen for button click
}) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder:
        (context) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
            ),
            padding: const EdgeInsets.only(
              top: 50,
              left: 20,
              right: 20,
              bottom: 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min, // Adjust height based on content
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SvgPicture.asset("assets/not_connected.svg"),
                const SizedBox(height: 20),
                Text(
                  "Usb Device Disconnected",
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF252525),
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    height: 1.10,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  "Please try connecting back respyr device to your phone and try again",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.mulish(
                    color: const Color(0xFF252525),
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 20), // Add spacing before buttons
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onButtonPressed,
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      shadowColor: Colors.transparent,
                      backgroundColor: const Color(0xFF308BF9),
                    ),
                    child: Text(
                      "Connect to USB Device",
                      style: GoogleFonts.mulish(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                TextButton(
                  onPressed:
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const OtgConnection(),
                        ),
                      ),
                  style: TextButton.styleFrom(padding: EdgeInsets.zero),
                  child: Text(
                    "Still facing issue with connection",
                    style: GoogleFonts.mulish(
                      color: const Color(0xFF308BF9),
                      decoration: TextDecoration.underline,
                      decorationColor: const Color(0xFF308BF9),
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
  );
}

void showCancelTestBox({
  required BuildContext context,
  required VoidCallback
  cancelTestButtonPressed, // Callback to listen for button click
}) {
  showDialog(
    context: context,
    barrierDismissible: true,
    builder:
        (context) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
            ),
            padding: const EdgeInsets.only(
              top: 50,
              left: 20,
              right: 20,
              bottom: 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min, // Adjust height based on content
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  "Are you sure want to cancel test?",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF252525),
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    height: 1.10,
                  ),
                ),
                const SizedBox(height: 44.5),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: OutlinedButton.styleFrom(
                      elevation: 0,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        side: const BorderSide(
                          width: 1,
                          color: Color(0xFFC7C6CE),
                        ),
                        borderRadius: BorderRadius.circular(18.50),
                      ),
                    ),
                    child: Text(
                      "Cancel",
                      style: GoogleFonts.mulish(
                        color: const Color(0xFF535359),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Add spacing before buttons
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: cancelTestButtonPressed,
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      shadowColor: Colors.transparent,
                      backgroundColor: const Color(0xFFEA5455),
                    ),
                    child: Text(
                      "Yes, Cancel test",
                      style: GoogleFonts.mulish(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
  );
}

Future<bool> showCancelTestDialog(BuildContext context) async {
  final bool? shouldCancel = await showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder:
        (context) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
            ),
            padding: const EdgeInsets.only(
              top: 50,
              left: 20,
              right: 20,
              bottom: 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  "Are you sure you want to cancel the test?",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF252525),
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    height: 1.10,
                  ),
                ),
                const SizedBox(height: 44.5),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context, false); // ❌ User cancels
                    },
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        side: const BorderSide(
                          width: 1,
                          color: Color(0xFFC7C6CE),
                        ),
                        borderRadius: BorderRadius.circular(18.50),
                      ),
                    ),
                    child: Text(
                      "Cancel",
                      style: GoogleFonts.mulish(
                        color: const Color(0xFF535359),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context, true); // ✅ Confirm
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEA5455),
                    ),
                    child: Text(
                      "Yes, Cancel test",
                      style: GoogleFonts.mulish(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
  );

  return shouldCancel ?? false;
}

void showImproperExhale({
  required BuildContext context,
  required VoidCallback
  tryAgainButtonClicked, // Callback to listen for button click
  required VoidCallback
  needHelpButtonCancel, // Callback to listen for button click
}) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder:
        (context) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
            ),
            padding: const EdgeInsets.only(
              top: 50,
              left: 20,
              right: 20,
              bottom: 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min, // Adjust height based on content
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SvgPicture.asset("assets/sagar/impropper.svg"),
                const SizedBox(height: 29.61),
                Text(
                  "Improper Exhale",
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF252525),
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    height: 1.10,
                  ),
                ),
                const SizedBox(height: 20),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: 'Your results ',
                        style: GoogleFonts.mulish(
                          color: const Color(0xFF535359),
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                          height: 1.40,
                        ),
                      ),
                      TextSpan(
                        text: 'lacks accuracy',
                        style: GoogleFonts.mulish(
                          color: const Color(0xFF535359),
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          height: 1.40,
                        ),
                      ),
                      TextSpan(
                        text:
                            ' due to low exhale. Please try again and make sure to exhale with full capacity.',
                        style: GoogleFonts.mulish(
                          color: const Color(0xFF535359),
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                          height: 1.40,
                        ),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 85), // Add spacing before buttons
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: tryAgainButtonClicked,
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      shadowColor: Colors.transparent,
                      backgroundColor: const Color(0xFF308BF9),
                    ),
                    child: Text(
                      "Try Again (recommended)",
                      style: GoogleFonts.mulish(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 48),
                Visibility(
                  visible: false,
                  child: Column(
                    children: [
                      const Divider(height: 1, color: Color(0xFFD9D9D9)),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "If not able to exhale properly",
                            style: GoogleFonts.mulish(
                              color: const Color(0xFF252525),
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              needHelpButtonCancel();
                            },
                            style: TextButton.styleFrom(padding: EdgeInsets.zero),
                            child: Text(
                              "Help",
                              style: GoogleFonts.mulish(
                                color: const Color(0xFF308BF9),
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
  );
}
