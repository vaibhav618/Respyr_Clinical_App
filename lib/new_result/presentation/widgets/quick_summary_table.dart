import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../shared/colors.dart';
import '../../../utils/score_color_helper.dart';
import '../../../utils/score_status_helper.dart';
import '../../data/model/result_model.dart';

class QuickSummaryTable extends StatefulWidget {
  final NewResultModel userResultData;
  final ScrollController scrollController;

  const QuickSummaryTable({
    super.key,
    required this.userResultData,
    required this.scrollController,
  });

  @override
  State<QuickSummaryTable> createState() => _QuickSummaryTableState();
}

class _QuickSummaryTableState extends State<QuickSummaryTable> {
  // 👇 INCREASED TO 75 TO ACCOMMODATE SYSTEM TEXT SCALING AND WRAPPING
  static const double cellHeight = 75;

  // Mock data, replace this with backend API call
  List<Map<String, dynamic>> rightTableData = [];

  @override
  void initState() {
    super.initState();
    fetchData(); // Simulate fetching data
  }

  List<List<dynamic>> get leftScoreData {
    return [
      ["Sugar Score", widget.userResultData.sugarScore],
      ["Liver Stress Score", widget.userResultData.liverScore],
      ["Gut Fermentation Score", widget.userResultData.gutScore],
      ["Respiratory Score", widget.userResultData.respiratoryScore],
    ];
  }

  // Score-based interpretations
  final Map<String, Map<String, String>> scoreInterpretations = {
    'sugar': {
      'Good': 'Efficient glucose metabolism.',
      'Fair': 'May suggest early changes in insulin sensitivity.',
      'Poor':
          'Reduced glucose utilization; metabolic follow-up may be helpful.',
    },
    'gut': {
      'Good': 'Balanced gut fermentation.',
      'Fair': 'Mild dysbiosis or early malabsorption possible.',
      'Poor': 'Elevated fermentation; gut imbalance may be present.',
    },
    'respiratory': {
      'Good': 'Normal respiratory performance.',
      'Fair': 'Mild airflow reduction; monitor symptoms.',
      'Poor': 'Reduced lung capacity; clinical review may be considered.',
    },
    'liver': {
      'Good': 'Minimal hepatic stress.',
      'Fair': 'Early metabolic strain may be present.',
      'Poor': 'Increased liver stress; dietary or medical review may help.',
    },
  };

  void fetchData() async {
    await Future.delayed(Duration(milliseconds: 500));

    String sugarStatus = ScoreStatusHelper.getScoreTitle(
      widget.userResultData.sugarScore,
    );
    String liverStatus = ScoreStatusHelper.getScoreTitle(
      widget.userResultData.liverScore,
    );
    String gutStatus = ScoreStatusHelper.getScoreTitle(
      widget.userResultData.gutScore,
    );
    String respiratoryStatus = ScoreStatusHelper.getScoreTitle(
      widget.userResultData.respiratoryScore,
    );

    // Score-based interpretations
    final Map<String, Map<String, String>> scoreInterpretations = {
      'sugar': {
        'Good': 'Efficient glucose metabolism.',
        'Fair': 'May suggest early changes in insulin sensitivity.',
        'Poor':
            'Reduced glucose utilization; metabolic follow-up may be helpful.',
      },
      'gut': {
        'Good': 'Balanced gut fermentation.',
        'Fair': 'Mild dysbiosis or early malabsorption possible.',
        'Poor': 'Elevated fermentation; gut imbalance may be present.',
      },
      'respiratory': {
        'Good': 'Normal respiratory performance.',
        'Fair': 'Mild airflow reduction; monitor symptoms.',
        'Poor': 'Reduced lung capacity; clinical review may be considered.',
      },
      'liver': {
        'Good': 'Minimal hepatic stress.',
        'Fair': 'Early metabolic strain may be present.',
        'Poor': 'Increased liver stress; dietary or medical review may help.',
      },
    };

    // Respyr Measured Values
    String measuredFev1Liters =
        widget.userResultData.blowArraysFevFvcValues!.respyrMeasured['FEV1(L)']!
            .toString();
    String measuredFev1FvcRatioPercent =
        widget
            .userResultData
            .blowArraysFevFvcValues!
            .respyrMeasured['FEV1/FVC Ratio(%)']!
            .toString();
    String measuredFvcLiters =
        widget.userResultData.blowArraysFevFvcValues!.respyrMeasured['FVC(L)']!
            .toString();
    String measuredPefLitersPerMin =
        widget
            .userResultData
            .blowArraysFevFvcValues!
            .respyrMeasured['PEF(L/min)']!
            .toString();

    String peakPressureStr = widget.userResultData.blowRawValues;
    List<double> values =
        peakPressureStr.split(',').map((e) => double.parse(e)).toList();
    double peakPressure = values.reduce((a, b) => a > b ? a : b);

    setState(() {
      rightTableData = [
        // SUGAR
        {
          "marker": "Acetone",
          "value": widget.userResultData.acetonePpm,
          "unit": "ppm",
          "interpretation": scoreInterpretations['sugar']![sugarStatus],
        },

        // LIVER
        {
          "marker": "Ethanol",
          "value": widget.userResultData.ethanolPpm,
          "unit": "ppm",
          "interpretation": scoreInterpretations['liver']![liverStatus],
        },

        // GUT
        {
          "marker": "Hydrogen (H₂)",
          "value": widget.userResultData.h2Ppm,
          "unit": "ppm",
          "interpretation": scoreInterpretations['gut']![gutStatus],
        },
        {
          "marker": "Peak Pressure",
          "value": peakPressure,
          "unit": "hPa",
          "interpretation":
              scoreInterpretations['respiratory']![respiratoryStatus],
        },
        {"marker": "FEV1", "value": measuredFev1Liters, "unit": "litre"},
        {"marker": "FVC", "value": measuredFvcLiters, "unit": "litre"},
        {"marker": "Ratio", "value": measuredFev1FvcRatioPercent, "unit": "%"},
        {"marker": "PEF", "value": measuredPefLitersPerMin, "unit": "litre"},
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    // 👇 WRAPPED THE ROW IN A VERTICAL SINGLECHILDSCROLLVIEW TO FIX OVERFLOW
    return SingleChildScrollView(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sticky Left Column
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _leftCell("Score & Percentage", false),

              ...leftScoreData.map((data) {
                final String title = data[0] as String;
                final double value = data[1] as double;
                return _leftCell(title, true, value);
              }),
              _leftSubCell(""),
              _leftSubCell(""),
              _leftSubCell(""),
              _leftSubCell(""),
            ],
          ),

          // Scrollable Right Section
          Expanded(
            child:
                rightTableData.isNotEmpty
                    ? Scrollbar(
                      controller: widget.scrollController,
                      thumbVisibility: true,
                      trackVisibility: true,
                      radius: Radius.circular(15),
                      child: SingleChildScrollView(
                        controller: widget.scrollController,
                        scrollDirection: Axis.horizontal,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header Row
                            Row(
                              children: [
                                _headerCell("Main Marker", 100),
                                _headerCell("Value", 70),
                                _headerCell("Unit", 70),
                                _headerCell("Quick interpretation", 150),
                              ],
                            ),
                            // Data Rows
                            ...rightTableData.map((item) {
                              return Row(
                                children: [
                                  _mainMarkerCell(item["marker"] ?? ""),
                                  _dataCell(
                                    item["value"] is num
                                        ? (item["value"] as num)
                                            .toStringAsFixed(3)
                                        : item["value"]?.toString() ?? "0.0",
                                  ),

                                  _dataCell(item["unit"] ?? ""),
                                  _interpretationCell(
                                    item["interpretation"] ?? "",
                                  ),
                                ],
                              );
                            }),
                            SizedBox(height: 10),
                          ],
                        ),
                      ),
                    )
                    : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _leftCell(String text, bool heading, [double score = 0]) {
    String scoreStatus = ScoreStatusHelper.getScoreTitle(score);

    Color clinicalStatusScoreColor = ScoreColorHelper.getScoreColor(score);

    return Container(
      width: 120,
      height: cellHeight,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFC7C6CE), width: 0.5),
          right: BorderSide(color: Color(0xFFC7C6CE), width: 0.5),
        ),
      ),
      // 👇 WRAPPED IN NEVER-SCROLLABLE SCROLL VIEW TO SWALLOW RENDERFLEX OVERFLOWS
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              text,
              style: GoogleFonts.poppins(
                color: const Color(0xFF252525),
                fontSize: 12,
                fontWeight: heading ? FontWeight.w400 : FontWeight.w600,
                height: 1.10,
                letterSpacing: -0.24,
              ),
            ),
            SizedBox(height: 5),
            if (heading == true)
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                spacing: 5,
                children: [
                  Text(
                    '${score.toStringAsFixed(0)}%',
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF252525),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      height: 1.10,
                      letterSpacing: -0.24,
                    ),
                  ),
                  Container(
                    height: 10,
                    width: 1,
                    color: AppColor.primaryBlackColor,
                  ),
                  Text(
                    scoreStatus,
                    style: GoogleFonts.poppins(
                      color: clinicalStatusScoreColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      height: 1.10,
                      letterSpacing: -0.24,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _leftSubCell(String text) {
    return Container(
      width: 120,
      height: cellHeight,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        border: Border(right: BorderSide(color: Color(0xFFC7C6CE), width: 0.5)),
      ),
    );
  }

  Widget _headerCell(String text, double width) {
    return Container(
      width: width,
      height: cellHeight,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFC7C6CE), width: 0.25),
        ),
      ),
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Text(
          text,
          style: GoogleFonts.poppins(
            color: const Color(0xFF252525),
            fontSize: 12,
            fontWeight: FontWeight.w600,
            height: 1.10,
          ),
        ),
      ),
    );
  }

  Widget _mainMarkerCell(String text) {
    return Container(
      width: 100,
      height: cellHeight,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFC7C6CE), width: 0.5),
        ),
        color: Colors.white,
      ),
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Text(
          text,
          style: GoogleFonts.poppins(
            color: const Color(0xFF252525),
            fontSize: 10,
            fontWeight: FontWeight.w400,
            height: 1.10,
            letterSpacing: -0.20,
          ),
        ),
      ),
    );
  }

  Widget _dataCell(String text) {
    return Container(
      width: 70,
      height: cellHeight,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFC7C6CE), width: 0.25),
        ),
      ),
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Text(
          text,
          style: GoogleFonts.poppins(
            color: const Color(0xFF252525),
            fontSize: 10,
            fontWeight: FontWeight.w400,
            height: 1.10,
            letterSpacing: -0.20,
          ),
        ),
      ),
    );
  }

  Widget _interpretationCell(String text) {
    return Container(
      width: 150,
      height: cellHeight,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFC7C6CE), width: 0.25),
        ),
      ),
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Text(
          text,
          style: GoogleFonts.poppins(
            color: const Color(0xFF252525),
            fontSize: 10,
            fontWeight: FontWeight.w400,
            height: 1.10,
            letterSpacing: -0.20,
          ),
        ),
      ),
    );
  }
}
