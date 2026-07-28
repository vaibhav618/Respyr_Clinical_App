import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TestDetailsWidget extends StatelessWidget {
  final Map<String, dynamic>? clinicalTestCountData;
  final int totalSubjectsOnboarded;

  const TestDetailsWidget({
    super.key,
    required this.clinicalTestCountData,
    required this.totalSubjectsOnboarded,
  });

  @override
  Widget build(BuildContext context) {
    const String testAllowKey = 'test_allow';
    const String testNoKey = 'test_no';
    const String scoreCountKey = 'clinical_score_count';

    final String isTestAllowed =
        clinicalTestCountData?[testAllowKey]?.toString().toLowerCase() ??
        "false";
    final int? testLimitCount = int.tryParse(
      clinicalTestCountData?[testNoKey]?.toString() ?? '',
    );
    final int? testTokenCount = int.tryParse(
      clinicalTestCountData?[scoreCountKey]?.toString() ?? '',
    );

    final int used = testTokenCount ?? 0;
    final int total = testLimitCount ?? 1; // avoid divide by zero
    final double progress = used / total; // corrected

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "Total tests taken",
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF535359),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "$used",
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF252525),
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        height: 1.1,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 3, left: 2),
                      child: Text(
                        "/ $total",
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF535359),
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Visibility(
              visible: isTestAllowed != "false",
              child: LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
                color:
                    progress.clamp(0.0, 1.0) <= 0.9
                        ? const Color(0xFF3EAF58)
                        : const Color(0xFFEA5455),
                backgroundColor: const Color(0xFFE5E7EB),
              ),
            ),
            Visibility(
              visible: progress >= 0.9,
              child: Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  progress == 1.0
                      ? "You're out of tests. To continue testing without interruption, contact our team for support."
                      : "Only ${total - used} tests are remaining. To continue testing without interruption, contact our team for support.",
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF535359),
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    height: 1.3,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
