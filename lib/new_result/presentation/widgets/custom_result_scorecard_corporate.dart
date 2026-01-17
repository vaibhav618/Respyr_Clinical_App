import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../utils/score_color_helper.dart';
import '../../../utils/score_status_helper.dart';
import '../../data/model/result_model.dart';
import 'card_settings.dart';
import 'lung_performance_chart.dart';

class CustomResultScorecardCorporate extends StatelessWidget {
  final String scoreTitle; // e.g. "Sugar Score" (display text)
  final double scoreVal;
  final String category; // ✅ sugar / gut / respiratory / liver (use this for logic)
  final String timeStamp;
  final NewResultModel userResultData;

  const CustomResultScorecardCorporate({
    super.key,
    required this.scoreTitle,
    required this.scoreVal,
    required this.category,
    required this.timeStamp,
    required this.userResultData,
  });

  // ✅ Single source of truth for meaning/interpretation/action
  static final Map<String, Map<String, List<String>>> _scoreData = {
    'sugar': {
      'Good': [
        "Balanced sugar metabolism",
        "Energy use appears stable and well regulated",
        "Continue current habits",
      ],
      'Fair': [
        "Mild variation",
        "Energy use shows mild inconsistency",
        "Improve meal timing, hydration",
      ],
      'Poor': [
        "Needs metabolic attention",
        "Consistent imbalance in energy handling",
        "Take this seriously: regular meals, daily movement, recheck over time",
      ],
    },
    'gut': {
      'Good': [
        "Balanced digestion",
        "Digestive activity appears stable",
        "Continue current eating habits",
      ],
      'Fair': [
        "Mild digestive variation",
        "Early signs of digestive imbalance linked to daily habits",
        "Improve hydration, meal regularity",
      ],
      'Poor': [
        "Digestive balance needs care",
        "Persistent digestive strain pattern",
        "Pay attention to food choices, routine, hydration",
      ],
    },
    'respiratory': {
      'Good': [
        "Smooth breathing pattern",
        "Breathing flow appears strong and comfortable",
        "Continue supporting healthy breathing habits",
      ],
      'Fair': [
        "Mild airflow variation",
        "Breathing flow shows mild variation",
        "Light activity, breathing exercises",
      ],
      'Poor': [
        "Reduced breathing efficiency",
        "Consistent restriction in airflow",
        "Act on this: posture, walking, breathing practice",
      ],
    },
    'liver': {
      'Good': [
        "Balanced metabolic handling",
        "Stable liver-related metabolic activity",
        "Continue supporting healthy daily habits",
      ],
      'Fair': [
        "Mild workload increase",
        "The body may be experiencing a mildly increased metabolic load",
        "Improve hydration, meals, sleep",
      ],
      'Poor': [
        "Higher metabolic burden",
        "Sustained metabolic load over time",
        "Prioritise routine, hydration, balanced meals",
      ],
    },
  };

  /// ✅ You pass category + score, it returns {0,1,2}
  static Map<String, String> getScoreInsight({
    required String category,
    required double score,
  }) {
    final level = ScoreStatusHelper.getScoreTitle(score);
    final key = category.trim().toLowerCase();

    final data = _scoreData[key]?[level];

    if (data == null || data.length < 3) {
      return {'0': '', '1': '', '2': ''};
    }

    return {
      '0': data[0], // meaning
      '1': data[1], // interpretation
      '2': data[2], // suggested action
    };
  }

  @override
  Widget build(BuildContext context) {
    final interpretation = _getScoreInterpretation(category, scoreVal);

    final titles = interpretation['titles'] as List<String>;
    final wellnessInsights = interpretation['insight'] ?? '';
    final correlation = interpretation['correlation'] ?? '';
    final mainMarker = interpretation['mainMarker'] ?? '';

    final dateTime = DateTime.fromMillisecondsSinceEpoch(
      int.parse(timeStamp) * 1000,
    );

    final formattedDate = DateFormat('dd MMMM yyyy').format(dateTime);
    final formattedTime = DateFormat('hh:mm a').format(dateTime);

    // Peak pressure
    String peakPressureStr = userResultData.blowRawValues;
    List<double> values =
    peakPressureStr.split(',').map((e) => double.parse(e)).toList();
    double peakPressure = values.reduce((a, b) => a > b ? a : b);

    // ✅ Use category+score (this is the fix)
    final insight = getScoreInsight(category: category, score: scoreVal);

    // (Optional debug)
    // print(category);
    // print("Meaning : ${insight['0']}");
    // print("Interpretation : ${insight['1']}");
    // print("Suggested : ${insight['2']}");

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

            Visibility(
              visible: category != "respiratory",
              replacement: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                    padding:
                    const EdgeInsets.symmetric(horizontal: 13, vertical: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(scoreTitle, style: CardSettings().scoreTitle()),
                        const SizedBox(height: 19.5),
                        CardSettings().scoreRow(score: scoreVal),
                        const SizedBox(height: 13),

                        // ✅ Meaning from insight
                        CardSettings().cardContent(
                          title: "Meaning",
                          content: insight['0'] ?? '',
                        ),
                        const SizedBox(height: 15),

                        // ✅ Interpretation from insight
                        CardSettings().cardContent(
                          title: "Interpretation",
                          content: insight['1'] ?? '',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  Visibility(
                    visible: false,
                    child: Container(
                      width: double.infinity,
                      decoration: ShapeDecoration(
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          side: const BorderSide(
                            width: 0.50,
                            color: Color(0xFFC7C6CE),
                          ),
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      padding:
                      const EdgeInsets.symmetric(vertical: 24, horizontal: 13),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Lung Performance',
                            style: GoogleFonts.poppins(
                              color: const Color(0xFF252525),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 28),
                          LungChartScreen(userResultData: userResultData),
                          const SizedBox(height: 14),
                          Text(
                            'Values (Exhale)',
                            style: GoogleFonts.poppins(
                              color: const Color(0xFF252525),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              height: 1.30,
                              letterSpacing: -0.24,
                            ),
                          ),
                          const SizedBox(height: 20),
                          _buildClinicalTable(category),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 15),

                  Visibility(
                    visible: false,
                    child: Container(
                      decoration: ShapeDecoration(
                        color: const Color(0xFFF0F0F0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      padding:
                      const EdgeInsets.symmetric(vertical: 24, horizontal: 13),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Main Marker: Peak Pressure',
                                style: GoogleFonts.poppins(
                                  color: const Color(0xFF252525),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  height: 1.30,
                                  letterSpacing: -0.24,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${peakPressure.toStringAsFixed(3)} hPa',
                                style: GoogleFonts.poppins(
                                  color: const Color(0xFF252525),
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  height: 1.10,
                                  letterSpacing: -0.40,
                                ),
                              ),
                            ],
                          ),
                          CardSettings().cardContent(
                            title: '',
                            content: mainMarker,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              child: Column(
                children: [
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
                    padding:
                    const EdgeInsets.symmetric(horizontal: 13, vertical: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(scoreTitle, style: CardSettings().scoreTitle()),
                        const SizedBox(height: 19.5),
                        CardSettings().scoreRow(score: scoreVal),
                        const SizedBox(height: 13),

                        // ✅ Meaning from insight
                        CardSettings().cardContent(
                          title: "Score Meaning",
                          content: insight['0'] ?? '',
                        ),
                        const SizedBox(height: 15),

                        // ✅ Interpretation from insight
                        CardSettings().cardContent(
                          title: "Interpretation",
                          content: insight['1'] ?? '',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20.5),

                  Visibility(
                    visible: false,
                    child: Container(
                      decoration: ShapeDecoration(
                        color: const Color(0xFFF0F0F0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      padding:
                      const EdgeInsets.symmetric(vertical: 24, horizontal: 13),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildClinicalTable(category),
                          CardSettings().cardContent(
                            title: '',
                            content: mainMarker,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 17),

            // ✅ Suggested Action from insight
            CardSettings().cardContent(
              title: "Suggested Action",
              content: insight['2'] ?? '',
            ),

            const SizedBox(height: 17),

            CardSettings().cardContent(
              title: "Correlation",
              content: correlation,
            ),

            const SizedBox(height: 17),

            CardSettings().cardContent(
              title: "Wellness Insight",
              content: wellnessInsights,
            ),

            const SizedBox(height: 17),
          ],
        ),
      ),
    );
  }

  TableRow _tableRow(List<String> values, {bool isHeader = false}) {
    return TableRow(
      children: values
          .map(
            (val) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 15),
          child: Text(
            val,
            style: isHeader
                ? CardSettings().tableHeaderTextStyle()
                : CardSettings().tableDataTextStyle(),
          ),
        ),
      )
          .toList(),
    );
  }

  Widget _buildClinicalTable(String category) {
    // Comparison with Predicted (%)
    String fev1ComparisonPercent = userResultData
        .blowArraysFevFvcValues!
        .comparisonWithPredicted['FEV1_vs_Predicted']!
        .toString();
    String fvcComparisonPercent = userResultData
        .blowArraysFevFvcValues!
        .comparisonWithPredicted['FVC_vs_Predicted']!
        .toString();
    String fev1FvcRatioComparisonPercent = userResultData
        .blowArraysFevFvcValues!
        .comparisonWithPredicted['Ratio_vs_Predicted']!
        .toString();

    // Predicted Values
    String predictedFev1Liters =
    userResultData.blowArraysFevFvcValues!.predicted['FEV1(L)']!.toString();
    String predictedFev1FvcRatioPercent = userResultData
        .blowArraysFevFvcValues!
        .predicted['FEV1/FVC_Ratio(%)']!
        .toString();
    String predictedFvcLiters =
    userResultData.blowArraysFevFvcValues!.predicted['FVC(L)']!.toString();

    // Respyr Measured Values
    String measuredFev1Liters = userResultData
        .blowArraysFevFvcValues!
        .respyrMeasured['FEV1(L)']!
        .toString();
    String measuredFev1FvcRatioPercent = userResultData
        .blowArraysFevFvcValues!
        .respyrMeasured['FEV1/FVC Ratio(%)']!
        .toString();
    String measuredFvcLiters =
    userResultData.blowArraysFevFvcValues!.respyrMeasured['FVC(L)']!.toString();
    String measuredPefLitersPerMin = userResultData
        .blowArraysFevFvcValues!
        .respyrMeasured['PEF(L/min)']!
        .toString();

    switch (category) {
      case 'respiratory':
        return Table(
          border: const TableBorder(
            horizontalInside: BorderSide(width: 0.4, color: Color(0xFFC7C6CE)),
          ),
          columnWidths: const {
            0: FlexColumnWidth(2),
            1: FlexColumnWidth(1.5),
            2: FlexColumnWidth(1),
            3: FlexColumnWidth(1),
          },
          children: [
            _tableRow(['Parameter', 'Actual', 'Pre', 'Pre%'], isHeader: true),
            _tableRow([
              'FEV1(L)',
              measuredFev1Liters,
              predictedFev1Liters,
              fev1ComparisonPercent,
            ]),
            _tableRow([
              'FVC(L)',
              measuredFvcLiters,
              predictedFvcLiters,
              fvcComparisonPercent,
            ]),
            _tableRow([
              'RATIO(%)',
              measuredFev1FvcRatioPercent,
              predictedFev1FvcRatioPercent,
              fev1FvcRatioComparisonPercent,
            ]),
            _tableRow(['PEF (Lt/min)', measuredPefLitersPerMin, '-', '-']),
          ],
        );

      case 'liver':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Main Marker: Ethanol',
              style: GoogleFonts.poppins(
                color: const Color(0xFF252525),
                fontSize: 12,
                fontWeight: FontWeight.w600,
                height: 1.30,
                letterSpacing: -0.24,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${userResultData.ethanolPpm.toStringAsFixed(2)} ppm',
              style: GoogleFonts.poppins(
                color: const Color(0xFF252525),
                fontSize: 20,
                fontWeight: FontWeight.w600,
                height: 1.10,
                letterSpacing: -0.40,
              ),
            ),
          ],
        );

      case 'sugar':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Main Marker: Acetone',
              style: GoogleFonts.poppins(
                color: const Color(0xFF252525),
                fontSize: 12,
                fontWeight: FontWeight.w600,
                height: 1.30,
                letterSpacing: -0.24,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${userResultData.acetonePpm.toStringAsFixed(2)} ppm',
              style: GoogleFonts.poppins(
                color: const Color(0xFF252525),
                fontSize: 20,
                fontWeight: FontWeight.w600,
                height: 1.10,
                letterSpacing: -0.40,
              ),
            ),
          ],
        );

      case 'gut':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Main Marker: Hydrogen',
              style: GoogleFonts.poppins(
                color: const Color(0xFF252525),
                fontSize: 12,
                fontWeight: FontWeight.w600,
                height: 1.30,
                letterSpacing: -0.24,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${userResultData.h2Ppm.toStringAsFixed(2)} ppm',
              style: GoogleFonts.poppins(
                color: const Color(0xFF252525),
                fontSize: 20,
                fontWeight: FontWeight.w600,
                height: 1.10,
                letterSpacing: -0.40,
              ),
            ),
          ],
        );

      default:
        return const SizedBox.shrink();
    }
  }

  Map<String, dynamic> _getScoreInterpretation(String category, double scoreVal) {
    String level = ScoreStatusHelper.getScoreTitle(scoreVal);

    // ✅ Use same _scoreData so no mismatch
    Map<String, String> wellnessInsights = {
      'sugar':
      "This score helps you understand how efficiently your body is using sugar and energy in everyday life. It is influenced by factors such as meal timing, physical activity, sleep quality, and  routine consistency.",
      'gut':
      "This score provides awareness of how your digestion is responding to food choices, meal timing, hydration levels, and your daily routine.",
      'respiratory':
      "This score helps you understand how comfortably and smoothly you are breathing during daily activities. influenced by posture, movement, stress levels, and physical activity .",
      'liver':
      "This score provides awareness of how your body is handling metabolic load from digestion, hydration, sleep quality, and daily lifestyle habits.",
    };

    Map<String, String> mainMarker = {
      'sugar':
      'Acetone (ppm), measured in exhaled breath. Acetone reflects fat metabolism and is indirectly associated with glucose utilization efficiency.',
      'gut':
      'Hydrogen (H₂) in ppm, measured in exhaled breath. Elevated levels suggest fermentation activity due to unabsorbed carbohydrates.',
      'respiratory':
      'Peak Expiratory Pressure, converted to FEV1. Additional indicators such as FVC, PEF, and FEV1/FVC ratio are also provided, though Respyr Score is solely based on FEV1.',
      'liver':
      'Ethanol concentration in exhaled breath (ppm), reflecting microbial fermentation and hepatic metabolic processing via the gut-liver axis.',
    };

    Map<String, String> correlations = {
      'sugar':
      "Breath acetone patterns have been studied in relation to fasting sugar and HbA1c trends, as they reflect how the body manages sugar and energy over time.Respyr does not measure blood glucose or HbA1c; it provides a non-invasive screening view of sugar metabolism patterns.",
      'gut':
      "Breath hydrogen is widely used in hydrogen breath testing to understand digestion and fermentation. Respyr adapts this into a screening indicator of gut activity. ",
      'respiratory':
      "Respyr evaluates breath-out flow patterns that follow principles similar to FEV1-based airflow behavior. This is not spirometry, but a screening view of breathing comfort and airflow smoothness. ",
      'liver':
      "Breath ethanol patterns have been explored in studies related to the gut–liver metabolic pathway. Respyr provides a screening-level insight into metabolic load. ",
    };

    Map<String, List<String>> categoryTitles = {
      'sugar': [
        'Glucose Metabolism',
        'Score Meaning',
        'Clinical Considerations / Suggested Next Steps',
        'Correlation',
        'Clinical Insight',
      ],
      'gut': [
        'Glucose Metabolism',
        'Score Meaning',
        'Clinical Considerations / Suggested Next Steps',
        'Correlation',
        'Clinical Insight',
      ],
      'respiratory': [
        'Airflow / Ventilation',
        'Score Meaning',
        'Clinical Considerations / Suggested Next Steps',
        'Correlation',
        'Clinical Insight',
      ],
      'liver': [
        'Hepatic Stress',
        'Score Meaning',
        'Clinical Considerations / Suggested Next Steps',
        'Correlation',
        'Clinical Insight',
      ],
    };

    return {
      'status': level,
      'titles': categoryTitles[category] ?? [],
      'subtitles': _scoreData[category]?[level] ?? [],
      'insight': wellnessInsights[category] ?? '',
      'correlation': correlations[category] ?? '',
      'mainMarker': mainMarker[category] ?? '',
    };
  }
}
