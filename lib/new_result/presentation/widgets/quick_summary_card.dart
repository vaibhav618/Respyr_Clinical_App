import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:respyr_clinical/new_result/presentation/widgets/quick_summary_table.dart';

import '../../data/model/result_model.dart';

/// Card around the quick summary.
///
/// Its header used to be a blue "Quick Interpretation →" button whose only
/// job was driving the table's horizontal scrollbar to the far column; the
/// summary is vertical now, so the header is simply the card's title.
class QuickSummary extends StatelessWidget {
  final NewResultModel userResultData;
  const QuickSummary({super.key, required this.userResultData});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Text(
                "Quick Interpretation",
                style: GoogleFonts.poppins(
                  color: const Color(0xFF252525),
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.3,
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Divider(height: 1, thickness: 1, color: Color(0xFFE5E7EB)),
            ),
            const SizedBox(height: 8),
            QuickSummaryTable(userResultData: userResultData),
          ],
        ),
      ),
    );
  }
}
