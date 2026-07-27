import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:respyr_clinical/utils/score_color_helper.dart';
import 'package:respyr_clinical/utils/score_status_helper.dart';

import '../../../../shared/images_string.dart';

class ScoreCard extends StatelessWidget {
  final String scoreName;
  final double score;
  const ScoreCard({super.key, required this.scoreName, required this.score});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        decoration: ShapeDecoration(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        padding: EdgeInsets.fromLTRB(16, 20, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              scoreName.replaceAll(" ", "\n"),
              style: GoogleFonts.poppins(
                color: const Color(0xFF252525),
                fontSize: 15,
                fontWeight: FontWeight.w600,
                height: 1.10,
              ),
            ),
            SizedBox(height: 20),
            Text(
              ScoreStatusHelper.getScoreTitle(score),
              style: GoogleFonts.poppins(
                color: ScoreColorHelper.getScoreColor(score),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "${score.toStringAsFixed(0)}%",
                  style: GoogleFonts.poppins(
                    color: ScoreColorHelper.getScoreColor(score),
                    fontSize: 24,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                SvgPicture.asset(scoreIcon(scoreName), width: 28),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String scoreIcon(String scoreName) {
    switch (scoreName) {
      case ("Sugar score"):
        return ResSvg.sugarPancreas;
      case ("Respiratory score"):
        return ResSvg.respiratory;
      case ("Liver score"):
        return ResSvg.liver;
      case ("Gut score"):
        return ResSvg.gutVital;
      default:
        return ResSvg.sugarPancreas;
    }
  }
}
