import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../clinical_dashboard/widgets/clinical_logo_widget.dart';
import '../shared/colors.dart';

class LogoutBox {
  Future<bool?> showDialogBox({
    required BuildContext context,
    required String clinicName,
    required VoidCallback? onLogoutClick,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: AppColor.whiteColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Logo Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SvgPicture.asset(
                      "assets/svg_icons/logout_icon.svg",
                      height: 35,
                      width: 35,
                    ),
                    const SizedBox(width: 10),
                    Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: ClinicLogoWidget(
                        clinicName: clinicName,
                        size: 36,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.03),

                // Logout text
                Text(
                  "Logout from $clinicName's account",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColor.primaryBlackColor,
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                Text(
                  "This will logout from all profiles connected to your account.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.mulish(
                    color: AppColor.textLightColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.03),

                const Divider(),
                SizedBox(height: MediaQuery.of(context).size.height * 0.02),

                // Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: MediaQuery.of(context).size.height * 0.055,
                        child: TextButton(
                          onPressed: () {
                            Navigator.of(context).pop(false);
                          },
                          style: ButtonStyle(
                            backgroundColor:
                            WidgetStateProperty.all(Colors.transparent),
                            overlayColor: WidgetStateProperty.resolveWith<Color?>(
                                  (Set<WidgetState> states) {
                                if (states.contains(WidgetState.pressed)) {
                                  return Colors.blue.withAlpha(47);
                                }
                                if (states.contains(WidgetState.hovered)) {
                                  return Colors.blue.withAlpha(26);
                                }
                                return null;
                              },
                            ),
                          ),
                          child: Text(
                            "Cancel",
                            style: GoogleFonts.mulish(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColor.primaryBlackColor,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: MediaQuery.of(context).size.width * 0.015),
                    Expanded(
                      child: SizedBox(
                        height: MediaQuery.of(context).size.height * 0.055,
                        child: TextButton(
                          onPressed: () {
                            if (onLogoutClick != null) {
                              onLogoutClick();
                              Navigator.of(context).pop(true);
                            }
                          },
                          style: ButtonStyle(
                            side: WidgetStateProperty.all(
                              const BorderSide(color: Color(0xFFDF2F32)),
                            ),
                            backgroundColor:
                            WidgetStateProperty.all(Colors.transparent),
                            overlayColor: WidgetStateProperty.resolveWith<Color?>(
                                  (Set<WidgetState> states) {
                                if (states.contains(WidgetState.pressed)) {
                                  return Colors.red.withAlpha(47);
                                }
                                if (states.contains(WidgetState.hovered)) {
                                  return Colors.red.withAlpha(26);
                                }
                                return null;
                              },
                            ),
                          ),
                          child: Text(
                            "Logout",
                            style: GoogleFonts.mulish(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              color: const Color(0xFFEA5455),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
