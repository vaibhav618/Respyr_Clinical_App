import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../utils/score_color_helper.dart';
import '../../../utils/score_status_helper.dart';
import '../../data/model/result_model.dart';
import 'card_settings.dart';
import 'lung_performance_chart.dart';

class CustomResultScorecard extends StatelessWidget {
  final String scoreTitle;
  final double scoreVal;
  final String category;
  final String timeStamp;
  final NewResultModel userResultData;

  const CustomResultScorecard({
    super.key,
    required this.scoreTitle,
    required this.scoreVal,
    required this.category,
    required this.timeStamp,
    required this.userResultData,
  });

  @override
  Widget build(BuildContext context) {
    final interpretation = _getScoreInterpretation(category, scoreVal);
    final titles = interpretation['titles'] as List<String>;
    final subtitles = interpretation['subtitles'] as List<String>;
    final insight = interpretation['insight'];
    final correlation = interpretation['correlation'];
    final mainMarker = interpretation['mainMarker'];
    final dateTime = DateTime.fromMillisecondsSinceEpoch(
      int.parse(timeStamp) * 1000,
    );

    final formattedDate = DateFormat('dd MMMM yyyy').format(dateTime);
    final formattedTime = DateFormat('hh:mm a').format(dateTime);

    String peakPressureStr = userResultData.blowRawValues;
    List<double> values =
        peakPressureStr.split(',').map((e) => double.parse(e)).toList();
    double peakPressure = values.reduce((a, b) => a > b ? a : b);

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
                    padding: EdgeInsets.symmetric(horizontal: 13, vertical: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(scoreTitle, style: CardSettings().scoreTitle()),
                        const SizedBox(height: 19.5),
                        CardSettings().scoreRow(score: scoreVal),
                        const SizedBox(height: 13),
                        CardSettings().cardContent(
                          title: titles[1],
                          content: subtitles[1],
                        ),
                        const SizedBox(height: 15),
                        CardSettings().cardContent(
                          title: titles[0],
                          content: subtitles[0],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    decoration: ShapeDecoration(
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        side: BorderSide(
                          width: 0.50,
                          color: const Color(0xFFC7C6CE),
                        ),
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 24, horizontal: 13),
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
                  SizedBox(height: 15),
                  Container(
                    decoration: ShapeDecoration(
                      color: const Color(0xFFF0F0F0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 24, horizontal: 13),
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
                            SizedBox(
                              height: 4,
                            ), // spacing between label and value
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
                    padding: EdgeInsets.symmetric(horizontal: 13, vertical: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(scoreTitle, style: CardSettings().scoreTitle()),
                        const SizedBox(height: 19.5),
                        CardSettings().scoreRow(score: scoreVal),
                        const SizedBox(height: 13),
                        CardSettings().cardContent(
                          title: titles[1],
                          content: subtitles[1],
                        ),
                        const SizedBox(height: 15),
                        CardSettings().cardContent(
                          title: titles[0],
                          content: subtitles[0],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20.5),
                  Container(
                    decoration: ShapeDecoration(
                      color: const Color(0xFFF0F0F0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 24, horizontal: 13),
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
                ],
              ),
            ),

            const SizedBox(height: 17),
            CardSettings().cardContent(title: titles[2], content: subtitles[2]),
            const SizedBox(height: 17),
            CardSettings().cardContent(
              title: "Correlation",
              content: correlation,
            ),
            const SizedBox(height: 17),
            CardSettings().cardContent(
              title: "Clinical Insight",
              content: insight,
            ),
            const SizedBox(height: 17),
          ],
        ),
      ),
    );
  }

  TableRow _tableRow(List<String> values, {bool isHeader = false}) {
    return TableRow(
      children:
          values
              .map(
                (val) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  child: Text(
                    val,
                    style:
                        isHeader
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
    String fev1ComparisonPercent =
        userResultData
            .blowArraysFevFvcValues!
            .comparisonWithPredicted['FEV1_vs_Predicted']!
            .toString();
    String fvcComparisonPercent =
        userResultData
            .blowArraysFevFvcValues!
            .comparisonWithPredicted['FVC_vs_Predicted']!
            .toString();
    String fev1FvcRatioComparisonPercent =
        userResultData
            .blowArraysFevFvcValues!
            .comparisonWithPredicted['Ratio_vs_Predicted']!
            .toString();

    // Predicted Values
    String predictedFev1Liters =
        userResultData.blowArraysFevFvcValues!.predicted['FEV1(L)']!.toString();
    String predictedFev1FvcRatioPercent =
        userResultData.blowArraysFevFvcValues!.predicted['FEV1/FVC_Ratio(%)']!
            .toString();
    String predictedFvcLiters =
        userResultData.blowArraysFevFvcValues!.predicted['FVC(L)']!.toString();

    // Respyr Measured Values
    String measuredFev1Liters =
        userResultData.blowArraysFevFvcValues!.respyrMeasured['FEV1(L)']!
            .toString();
    String measuredFev1FvcRatioPercent =
        userResultData
            .blowArraysFevFvcValues!
            .respyrMeasured['FEV1/FVC Ratio(%)']!
            .toString();
    String measuredFvcLiters =
        userResultData.blowArraysFevFvcValues!.respyrMeasured['FVC(L)']!
            .toString();
    String measuredPefLitersPerMin =
        userResultData.blowArraysFevFvcValues!.respyrMeasured['PEF(L/min)']!
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
            SizedBox(height: 4), // spacing between label and value
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
            SizedBox(height: 4), // spacing between label and value
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
            SizedBox(height: 4), // spacing between label and value
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
        return SizedBox.shrink();
    }
  }

  Map<String, dynamic> _getScoreInterpretation(
    String category,
    double scoreVal,
  ) {
    String level = ScoreStatusHelper.getScoreTitle(scoreVal);

    Map<String, Map<String, List<String>>> scoreData = {
      'sugar': {
        'Good': [
          "Indicates Efficient glucose metabolism",
          "Correlates with normal fasting glucose and HbA1c levels. No abnormal trends in glucoseutilization or metabolic flexibilityare observed.",
          "No further evaluation typically required unless clinically indicated.",
        ],
        'Fair': [
          "Indicates Mild impairment in glucose efficiency.",
          "Correlating with slight elevations in fasting glucose and/or HbA1c.This may reflect early-stage reduction in insulin sensitivity or changes in metabolic substrateuse.",
          "Periodic monitoring of metabolic markers may be considered.",
        ],
        'Poor': [
          "Indicates Significant reduction in glucose utilization efficiency.",
          "Correlating with marked elevations in fasting glucose and/or HbA1c trends. Suggests increasing reliance on alternative energy pathways (lipolysis/ketone production).",
          "Further metabolic evaluation may be suggested to explore potential contributors to impaired glucose handling.",
        ],
      },
      'gut': {
        'Good': [
          "Indicates Balanced gut fermentation activity.",
          "Hydrogen levels fall within expected physiological ranges, correlating with efficient carbohydrate absorption and stable microbial fermentation. No significant gastrointestinal concerns observed.",
          "No further evaluation typically required unless clinically indicated.",
        ],
        'Fair': [
          "Indicates Moderate elevation in fermentation activity.",
          "Correlating with slight increases in hydrogen production. This may be associated with early dysbiosis or mild inefficiencies in carbohydrate absorption. Occasional bloating or digestive discomfort may be reported.",
          "Further assessment of gut fermentation trends may be considered if symptoms persist.",
        ],
        'Poor': [
          "Indicates Significant fermentation imbalance.",
          "Correlating with markedly elevated hydrogen levels. May reflect considerable dysbiosis, potential carbohydrate absorption inefficiency, or excessive microbial fermentation. Bloating and digestive discomfort are likely.",
          "As a screening result, further gastrointestinal evaluation may be warranted.",
        ],
      },
      'respiratory': {
        'Good': [
          "Normal expiratory flow and lung capacity. Pressure-derived FEV1 ≥ 80% of predicted value. FVC, PEF, and FEV1/FVC ratio are also within expected ranges.",
          "Indicates efficient ventilatory function. Respyr Score reflects normal respiratory performance.",
          "No further evaluation typically required unless clinically indicated.",
        ],
        'Fair': [
          "Mild reduction in expiratory efficiency. FEV1 between 70-79% of predicted. Subtle variations may be seen in supporting metrics.",
          "Indicates early changes in respiratory performance. Respyr Score flags minor reduction in airflow capacity.",
          "Periodic monitoring may be considered. Clinical spirometry may be suggested if symptoms such as breathlessness or chronic cough are present.",
        ],
        'Poor': [
          "Significant reduction in expiratory capacity. FEV1 < 70% of predicted. FVC, PEF, and FEV1/FVC ratio may also be reduced.",
          "Indicates notable decline in ventilatory function. May reflect increasing resistance or reduced flow capacity.",
          "Further clinical evaluation with spirometry may be considered based on the individual's clinical scenario. Suitable for early screening or referral in occupational or preventive health contexts.",
        ],
      },
      'liver': {
        'Good': [
          "Indicates Minimal hepatic stress.",
          "Metabolic liver function appears consistent with healthy patterns, with no significant evidence of gut-liver axis disturbance.",
          "No further evaluation typically required unless clinically indicated.",
        ],
        'Fair': [
          "Indicates mild hepatic stress",
          "May indicate early metabolic strain, minor inefficiencies in hepatic processing, or subtle gut-liver axis interactions",
          "Further evaluation may be considered depending on individual clinical context, lifestyle, or dietary history.",
        ],
        'Poor': [
          "Indicates Significant hepatic stress.",
          "May indicate early metabolic strain, minor inefficiencies in hepatic processing, or subtle gut-liver axis interactions",
          "Comprehensive liver function evaluation is recommended, including nutritional and metabolic assessment as appropriate.",
        ],
      },
    };

    Map<String, String> clinicalInsights = {
      'sugar':
          "This score provides clinical insights on overall glucose metabolism efficiency, including insulin sensitivity and metabolic flexibility. It offers an early, non-invasive indicator of carbohydrate utilization trends without directly measuring blood glucose levels.",

      'gut':
          "This score provides clinical insights on degree of intestinal fermentation activity, microbial balance, and carbohydrate absorption efficiency. It offers a non-invasive, real-time indicator of potential gut dysbiosis or malabsorption trends. While not diagnostic, it helps monitor functional gut health and supports early identification of fermentation-related imbalances without pinpointing specific gastrointestinal disorders.",

      'respiratory':
          "This score provides clinical insights on the following key components of respiratory function:\n\n"
          "• Expiratory flow capacity, through FEV1 estimation\n"
          "• Airway resistance, derived from pressure-to-flow dynamics\n"
          "• Ventilatory efficiency, using additional indicators such as FVC, PEF, and FEV1/FVC ratio\n\n"
          "These combined outputs offer a comprehensive, non-invasive view of respiratory performance trends. While FEV1 is the sole input used to calculate the Respyr Score, additional parameters such as FVC, PEF, and the FEV1/FVC ratio are provided for clinical context. The score functions as a non-invasive pre-screening feature designed to support the early identification of respiratory decline, longitudinal trend monitoring, and preventive assessment in health contexts.",

      'liver':
          "This score provides clinical insights on patterns of hepatic metabolic stress and gut-liver axis interaction. It serves as a non-invasive functional screening tool to detect potential liver strain, without diagnosing specific hepatic disorders.",
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
          "The Respyr Sugar Score correlates with fasting blood glucose and HbA1c trends, based on internal validation studies benchmarking exhaled breath VoC levels against standard clinical markers of glucose metabolism.",

      'gut':
          "The Respyr Gut Fermentation Score is based on rapid, single-point exhaled hydrogen (H₂) measurement and correlates with globally recognized breath test benchmarks. While traditional clinical standards are based on multi-step glucose or lactulose challenge tests, Respyr adapts validated baseline H₂ concentration ranges observed in gut fermentation studies. Sensor calibration is aligned with literature reported thresholds reflecting physiological and dysbiotic fermentation patterns. This makes the score a reliable, non-invasive functional screening tool for assessing real-time gut fermentation activity.",

      'respiratory':
          "The Respyr Respiratory Score correlates with pulmonary function trends derived from expiratory pressure converted into flow, and subsequently into FEV1 (Forced Expiratory Volume in 1 second) values. Calibration was conducted using the AveloAir Digital Spirometer,a globally certified spirometry device. For validation, individuals with doctor-confirmed respiratory issues and valid Pulmonary Function Test (PFT) reports were included. Respyr's pressure-derived FEV1 trends were compared with the respiratory status of each individual. Lower FEV1 values consistently corresponded with lower Respyr Scores, aligning with expected patterns of airflow changes.",

      'liver':
          "The Respyr Liver Stress Score demonstrates correlation with liver enzyme and imaging findings in individuals with confirmed liver conditions, based on internal validation studies. The score aligns with emerging scientific evidence linking elevated exhaled ethanol levels to increased hepatic metabolic burden and gut-liver axis dysfunction.",
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
      'subtitles': scoreData[category]?[level] ?? [],
      'insight': clinicalInsights[category] ?? '',
      'correlation': correlations[category] ?? '',
      'mainMarker': mainMarker[category] ?? '',
    };
  }
}
