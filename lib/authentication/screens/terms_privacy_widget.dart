import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:respyr_clinical/authentication/screens/privacy_policy.dart';
import 'package:respyr_clinical/authentication/screens/terms_and_conditions.dart';

Widget buildPrivacyText(BuildContext context) {
  return RichText(
    textAlign: TextAlign.center,
    text: TextSpan(
      children: [
        TextSpan(
          text: "By continuing, you agree to our ",
          style: GoogleFonts.mulish(fontSize: 12, color: const Color(0xFF535359)),
        ),
        TextSpan(
          text: "Terms and Conditions",
          style: GoogleFonts.mulish(
            fontSize: 12,
            decoration: TextDecoration.underline,
            color: const Color(0xFF308BF9),
          ),
          recognizer: TapGestureRecognizer()
            ..onTap = () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => const TermsAndConditions())),
        ),
        const TextSpan(text: " and ", style: TextStyle(color: Color(0xFF535359))),
        TextSpan(
          text: "Privacy Policy",
          style: GoogleFonts.mulish(
            fontSize: 12,
            decoration: TextDecoration.underline,
            color: const Color(0xFF308BF9),
          ),
          recognizer: TapGestureRecognizer()
            ..onTap = () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => const PrivacyPolicy())),
        ),
      ],
    ),
  );
}