import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../utils/score_color_helper.dart';
import '../../../../utils/score_status_helper.dart';

/// One score tile on the corporate dashboard: name, band-coloured value with
/// its status word, and a fill bar.
///
/// Restyled to the app's card idiom — white with a hairline border instead of
/// a borderless block, natural title wrapping instead of one word per line,
/// and a bar so the value reads against the 0-100 scale at a glance.
class ScoreCard extends StatelessWidget {
  final String scoreName;
  final double score;

  const ScoreCard({super.key, required this.scoreName, required this.score});

  @override
  Widget build(BuildContext context) {
    final Color band = ScoreColorHelper.getScoreColor(score);

    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 34,
              child: Text(
                scoreName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  color: const Color(0xFF535359),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  height: 1.25,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  "${score.toStringAsFixed(0)}%",
                  style: GoogleFonts.poppins(
                    color: band,
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    height: 1.1,
                  ),
                ),
                const Spacer(),
                Text(
                  ScoreStatusHelper.getScoreTitle(score),
                  style: GoogleFonts.poppins(
                    color: band,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: SizedBox(
                height: 4,
                width: double.infinity,
                child: Stack(
                  children: [
                    Container(color: const Color(0xFFE5E7EB)),
                    FractionallySizedBox(
                      widthFactor: (score / 100).clamp(0.0, 1.0),
                      child: Container(color: band),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
