import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../utils/score_color_helper.dart';
import '../../data/model/corporate_interpretation.dart';
import '../../data/model/result_model.dart';
import 'card_settings.dart';

class CustomResultScorecardCorporate extends StatelessWidget {
  final String scoreTitle;
  final double scoreVal;
  final String category;
  final String timeStamp;
  final NewResultModel userResultData;
  final ScoreInterpretation corporateInterpretation;

  /// Shows a "Back to top" footer — reading a card ends a long way from the
  /// score selector above it.
  final VoidCallback? onBackToTop;

  const CustomResultScorecardCorporate({
    super.key,
    required this.scoreTitle,
    required this.scoreVal,
    required this.category,
    required this.timeStamp,
    required this.userResultData,
    required this.corporateInterpretation,
    this.onBackToTop,
  });

  @override
  Widget build(BuildContext context) {
    final dateTime = DateTime.fromMillisecondsSinceEpoch(
      int.parse(timeStamp) * 1000,
    );

    final formattedDate = DateFormat('dd MMMM yyyy').format(dateTime);
    final formattedTime = DateFormat('hh:mm a').format(dateTime);

    final wellnessInsight = corporateInterpretation.wellnessInsight;
    final correlation = corporateInterpretation.correlation;
    final suggestedAction = corporateInterpretation.bandDetails.suggestedAction;
    final scoreMeaning = corporateInterpretation.bandDetails.meaning;
    final scoreInterpretationText = corporateInterpretation.bandDetails.interpretation;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Container(
        decoration: ShapeDecoration(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            side: const BorderSide(width: 0.50, color: Color(0xFFC7C6CE)),
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 13),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(formattedDate, style: CardSettings().scoreDateTime()),
                const SizedBox(width: 10),
                Container(height: 12, width: 1, color: const Color(0xFF252525)),
                const SizedBox(width: 10),
                Text(formattedTime, style: CardSettings().scoreDateTime()),
              ],
            ),
            const SizedBox(height: 20.5),
            Container(
              width: double.infinity,
              decoration: ShapeDecoration(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  side: BorderSide(
                    width: 0.50,
                    color: ScoreColorHelper.getScoreColor(scoreVal),
                  ),
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(scoreTitle, style: CardSettings().scoreTitle()),
                  const SizedBox(height: 19.5),
                  CardSettings().scoreRow(score: scoreVal),
                  const SizedBox(height: 13),
                  CardSettings().cardContent(
                    title: "Score Meaning",
                    content: scoreMeaning,
                  ),
                  const SizedBox(height: 15),
                  CardSettings().cardContent(
                    title: "Interpretation",
                    content: scoreInterpretationText,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 17),
            CardSettings().cardContent(
              title: "Suggested Action",
              content: suggestedAction,
            ),
            const SizedBox(height: 17),
            CardSettings().cardContent(
              title: "Correlation",
              content: correlation,
            ),
            const SizedBox(height: 17),
            CardSettings().cardContent(
              title: "Wellness Insight",
              content: wellnessInsight,
            ),
            if (onBackToTop != null) ...[
              const SizedBox(height: 17),
              // Same footer as the clinical card, so the gesture is one
              // habit across both roles.
              const Divider(height: 1, thickness: 1, color: Color(0xFFE5E7EB)),
              InkWell(
                onTap: onBackToTop,
                child: Padding(
                  padding: const EdgeInsets.only(top: 12, bottom: 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.keyboard_arrow_up_rounded,
                        size: 18,
                        color: Color(0xFF308BF9),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "Back to top",
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF308BF9),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ] else
              const SizedBox(height: 17),
          ],
        ),
      ),
    );
  }
}
