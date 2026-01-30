import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';


class TestDetailsWidget extends StatelessWidget {
  final Map<String, dynamic>? clinicalTestCountData;
  final int  totalSubjectsOnboarded;

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

    final String isTestAllowed = clinicalTestCountData?[testAllowKey]?.toString().toLowerCase() ?? "false";
    final int? testLimitCount = int.tryParse(clinicalTestCountData?[testNoKey]?.toString() ?? '');
    final int? testTokenCount = int.tryParse(clinicalTestCountData?[scoreCountKey]?.toString() ?? '');


    print("scoreCountKey :" + testTokenCount.toString() );
    print("scoreCountKey :" + clinicalTestCountData.toString() );

    final int used = testTokenCount ?? 0;
    final int total = testLimitCount ?? 1; // avoid divide by zero
    final double progress = used / total;  // corrected

    return SizedBox(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Container(
          width: double.infinity,
          decoration: ShapeDecoration(
            color: const Color(0xFFF5F7FA),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),

          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Total\nTest Taken",
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF252525),
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                          height: 1.10,
                          letterSpacing: -0.30,
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            "$used",
                            style: GoogleFonts.poppins(
                              color: const Color(0xFF252525),
                              fontSize: 30,
                              fontWeight: FontWeight.w400,
                              letterSpacing: -0.60,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            "/$total",
                            style: GoogleFonts.poppins(
                              color: const Color(0xFF252525),
                              fontSize: 15,
                              fontWeight: FontWeight.w400,
                              letterSpacing: -0.30,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  Visibility(
                    visible: isTestAllowed!="false",
                    child: LinearProgressIndicator(
                      value: progress.clamp(0.0, 1.0),
                      minHeight: 10,
                      borderRadius: BorderRadius.circular(5),
                      color: progress.clamp(0.0, 1.0) <= 0.9 ? Color(0xFF3EAF58) : Color(0xFFEA5455),
                      backgroundColor: const Color(0xFFFFFFFF),
                    ),
                  ),

                  Visibility(
                    visible: progress >=0.9,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 10,),
                        Text(progress==1.0 ? "You're out of tests. To continue testing without interruption, contact our team for support." :
                        "Only ${total - used} tests are remaining. To continue testing without interruption, contact our team for support. ",
                          style: GoogleFonts.poppins(
                            color: const Color(0xFF5A5A5A),
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            height: 1.10,
                            letterSpacing: -0.24,
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ),

            ],
          ),
        ),
      ),
    );
  }
}
