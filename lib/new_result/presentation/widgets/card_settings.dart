import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../utils/score_color_helper.dart';
import '../../../utils/score_status_helper.dart';

class CardSettings {
  Widget cardContent({required String title, required String content}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            color: const Color(0xFF252525),
            fontSize: 12,
            fontWeight: FontWeight.w600,
            height: 1.30,
            letterSpacing: -0.24,
          ),
        ),
        SizedBox(height: 5),
        Text(
          content,
          style: GoogleFonts.poppins(
            color: const Color(0xFF252525),
            fontSize: 12,
            fontWeight: FontWeight.w400,
            height: 1.26,
            letterSpacing: -0.24,
          ),
        ),
      ],
    );
  }

  TextStyle scoreTitle() {
    return GoogleFonts.poppins(
      color: const Color(0xFF252525),
      fontSize: 15,
      fontWeight: FontWeight.w600,
      height: 1.10,
      letterSpacing: -0.30,
    );
  }

  TextStyle scoreDateTime() {
    return GoogleFonts.poppins(
      color: const Color(0xFF252525),
      fontSize: 12,
      fontWeight: FontWeight.w400,
      height: 1.10,
      letterSpacing: -0.24,
    );
  }

  Widget scoreRow({required double score}) {
    String scoreStatus = ScoreStatusHelper.getScoreTitle(score);

    Color clinicalStatusScoreColor = ScoreColorHelper.getScoreColor(score);

    return Row(
      children: [
        Text(
          "${score.toStringAsFixed(0)}%",
          style: GoogleFonts.poppins(
            color: const Color(0xFF252525),
            fontSize: 30,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.60,
          ),
        ),
        SizedBox(width: 12),
        Container(height: 22, width: 2, color: Color(0xFF252525)),
        SizedBox(width: 12),
        Text(
          scoreStatus,
          style: GoogleFonts.poppins(
            color: clinicalStatusScoreColor,
            fontSize: 30,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.60,
          ),
        ),
      ],
    );
  }

  TextStyle tableDataTextStyle() {
    return GoogleFonts.poppins(
      color: Color(0xFF252525),
      fontSize: 12,
      fontWeight: FontWeight.w400,
      height: 1.10,
      letterSpacing: -0.24,
    );
  }

  TextStyle tableHeaderTextStyle() {
    return GoogleFonts.poppins(
      color: const Color(0xFF252525),
      fontSize: 12,
      fontWeight: FontWeight.w600,
      height: 1.10,
    );
  }
}
