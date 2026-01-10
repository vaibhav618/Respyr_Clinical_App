import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';

class AccountCreationSuccess {
  Future<void> showMessage(
      BuildContext context, {
        required VoidCallback onContinue,
        VoidCallback? onClosed,
      }) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.white,
      isDismissible: false,
      enableDrag: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          bottom: true,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SvgPicture.asset(
                  "assets/sagar/undraw_success_288d.svg",
                  height: 100,
                ),
                const SizedBox(height: 50),
                Text(
                  "Profile is created",
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF252525),
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.8,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 38),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      // ✅ mark closed by Continue
                      Navigator.pop(context, true);
                      onContinue();
                    },
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: const Color(0xFF308BF9),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(2500),
                      ),
                    ),
                    child: Text(
                      "Continue",
                      style: GoogleFonts.mulish(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        height: 1.10,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    // result == true  => closed by Continue
    // result == null/false => closed by back / system / Navigator.pop without value
    final closedByContinue = (result == true);

    if (!closedByContinue) {
      if (onClosed != null) onClosed();
    }
  }
}
