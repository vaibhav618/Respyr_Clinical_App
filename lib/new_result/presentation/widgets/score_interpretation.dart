import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';

Widget scoreInterpretation() {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Scores Interpretation',
          style: GoogleFonts.poppins(
            color: const Color(0xFF252525),
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        RichText(
          text: const TextSpan(
            children: [
              TextSpan(
                text:
                'Scores interpretations are based on the values recorded by Respyr device. Please refer to the reference ',
                style: TextStyle(
                  color: Color(0xFF252525),
                  fontSize: 12,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w400,
                  height: 1.26,
                  letterSpacing: -0.24,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}