import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:respyr_clinical/clinical_dashboard/widgets/pie_chart_analytics.dart';
import 'package:respyr_clinical/clinical_dashboard/widgets/test_log_widget.dart';
import 'package:respyr_clinical/shared/colors.dart';

import '../model/OverallDataByDateModel.dart';

class ScoreBreakdown {
  final int good;
  final int fair;
  final int poor;

  ScoreBreakdown({required this.good, required this.fair, required this.poor});

  ScoreBreakdown operator +(ScoreBreakdown other) {
    return ScoreBreakdown(
      good: good + other.good,
      fair: fair + other.fair,
      poor: poor + other.poor,
    );
  }
}

class ScoreTypesForGender {
  final ScoreBreakdown dbScore;
  final ScoreBreakdown liverScore;
  final ScoreBreakdown gutScorePer;
  final ScoreBreakdown blowScore;

  ScoreTypesForGender({
    required this.dbScore,
    required this.liverScore,
    required this.gutScorePer,
    required this.blowScore,
  });
}

class OverallAnalyticsWidget extends StatefulWidget {
  final Map<String, ScoreTypesForGender> genderDistribution;
  final String date;
  final List<ScoreData> scoreData;
  final String loginId;

  const OverallAnalyticsWidget({
    super.key,
    required this.genderDistribution,
    required this.date,
    required this.scoreData,
    required this.loginId,
  });

  @override
  State<OverallAnalyticsWidget> createState() => _OverallAnalyticsWidgetState();
}

class _OverallAnalyticsWidgetState extends State<OverallAnalyticsWidget> {
  String selectedScoreType = 'Sugar score';

  final Map<String, String> scoreTypeMap = {
    'Sugar score': 'dbScore',
    'Liver stress score': 'liverScore',
    'Gut fermentation score': 'gutScorePer',
    'Respiratory score': 'blowScore',
  };

  ScoreBreakdown _getCombinedBreakdown() {
    ScoreBreakdown total = ScoreBreakdown(good: 0, fair: 0, poor: 0);

    final selectedKey = scoreTypeMap[selectedScoreType];

    widget.genderDistribution.forEach((gender, data) {
      if (gender == 'Male' || gender == 'Female') {
        switch (selectedKey) {
          case 'liverScore':
            total += data.liverScore;
            break;
          case 'gutScorePer':
            total += data.gutScorePer;
            break;
          case 'blowScore':
            total += data.blowScore;
            break;
          case 'dbScore':
          default:
            total += data.dbScore;
            break;
        }
      }
    });

    return total;
  }

  @override
  Widget build(BuildContext context) {
    final breakdown = _getCombinedBreakdown();
    final totalTest = breakdown.good + breakdown.fair + breakdown.poor;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Container(
        decoration: ShapeDecoration(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            side: BorderSide(width: 1, color: const Color(0xFFD9D9D9)),
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  Text(
                    "Overall Test Analytics",
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF252525),
                      fontSize: 20,
                      fontWeight: FontWeight.w400,
                      letterSpacing: -0.80,
                    ),
                  ),
                  SizedBox(height: 20),
                  Align(
                    alignment: Alignment.center,
                    child: Column(
                      children: [
                        Text(
                          "Select score to view analytics",
                          style: GoogleFonts.poppins(
                            color: const Color(0xFF535359),
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            letterSpacing: -0.48,
                          ),
                        ),
                        SizedBox(height: 15),
                        Container(
                          decoration: ShapeDecoration(
                            color: Colors.white,
                            shape: RoundedRectangleBorder(
                              side: BorderSide(
                                width: 1,
                                color: const Color(0xFFC7C6CE),
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          padding: EdgeInsets.symmetric(horizontal: 20),
                          child: DropdownButton<String>(
                            value: selectedScoreType,
                            underline: SizedBox(),
                            icon: Icon(
                              Icons.keyboard_arrow_down_rounded,
                            ), // or any icon you like
                            borderRadius: BorderRadius.circular(15),
                            dropdownColor: AppColor.whiteColor,
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => selectedScoreType = value);
                              }
                            },
                            items:
                                scoreTypeMap.keys.map((type) {
                                  return DropdownMenuItem(
                                    value: type,

                                    child: Text(
                                      type,
                                      style: GoogleFonts.poppins(
                                        color: const Color(0xFF535359),
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                        letterSpacing: -0.30,
                                      ),
                                    ),
                                  );
                                }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 30),
                  PieChartTestAnalyticsWidget(
                    poor: breakdown.poor,
                    fair: breakdown.fair,
                    good: breakdown.good,
                    totalTest: totalTest,
                    date: widget.date, // ✅ This uses the passed formattedDate
                  ),
                ],
              ),
            ),
            SizedBox(height: 50),
            TestLogWidget(
              loginId: widget.loginId,
              scoreType: selectedScoreType,
              scoreData: widget.scoreData,
            ),
          ],
        ),
      ),
    );
  }
}
