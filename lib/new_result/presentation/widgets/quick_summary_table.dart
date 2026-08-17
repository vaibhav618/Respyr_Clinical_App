import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../utils/score_color_helper.dart';
import '../../../utils/score_status_helper.dart';
import '../../data/model/result_model.dart';

/// The quick summary: each score with its marker reading and one-line
/// interpretation, then the measured lung values.
///
/// This was a 510px-wide grid — sticky score column, then marker / value /
/// unit / interpretation columns behind a horizontal scrollbar, with four
/// empty left cells padding out the lung rows. Half a metre of table for
/// what is, per score, a sentence and one number. Stacked vertically it all
/// fits the screen with nothing to scroll sideways, and the fake half-second
/// "fetch" of data the model already held is gone with the scroll machinery.
class QuickSummaryTable extends StatelessWidget {
  final NewResultModel userResultData;

  const QuickSummaryTable({super.key, required this.userResultData});

  static const Map<String, Map<String, String>> scoreInterpretations = {
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

  double get _peakPressure {
    final List<double> values = userResultData.blowRawValues
        .split(',')
        .map((e) => double.tryParse(e.trim()))
        .whereType<double>()
        .toList();
    if (values.isEmpty) return 0;
    return values.reduce((a, b) => a > b ? a : b);
  }

  @override
  Widget build(BuildContext context) {
    final measured = userResultData.blowArraysFevFvcValues?.respyrMeasured;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _scoreRow(
            title: "Sugar Score",
            score: userResultData.sugarScore,
            category: 'sugar',
            marker: "Acetone",
            value: userResultData.acetonePpm,
            unit: "ppm",
          ),
          _divider(),
          _scoreRow(
            title: "Liver Stress Score",
            score: userResultData.liverScore,
            category: 'liver',
            marker: "Ethanol",
            value: userResultData.ethanolPpm,
            unit: "ppm",
          ),
          _divider(),
          _scoreRow(
            title: "Gut Fermentation Score",
            score: userResultData.gutScore,
            category: 'gut',
            marker: "Hydrogen (H₂)",
            value: userResultData.h2Ppm,
            unit: "ppm",
          ),
          _divider(),
          _scoreRow(
            title: "Respiratory Score",
            score: userResultData.respiratoryScore,
            category: 'respiratory',
            marker: "Peak Pressure",
            value: _peakPressure,
            unit: "hPa",
          ),
          if (measured != null) ...[
            _divider(),
            const SizedBox(height: 2),
            Text(
              "MEASURED LUNG VALUES (EXHALE)",
              style: GoogleFonts.poppins(
                color: const Color(0xFF535359),
                fontSize: 9.5,
                fontWeight: FontWeight.w500,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _lungStat("FEV1", measured['FEV1(L)'], "L"),
                _lungDivider(),
                _lungStat("FVC", measured['FVC(L)'], "L"),
                _lungDivider(),
                _lungStat("FEV1/FVC", measured['FEV1/FVC Ratio(%)'], "%"),
                _lungDivider(),
                _lungStat("PEF", measured['PEF(L/min)'], "L/min"),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _scoreRow({
    required String title,
    required double score,
    required String category,
    required String marker,
    required dynamic value,
    required String unit,
  }) {
    final String status = ScoreStatusHelper.getScoreTitle(score);
    final Color band = ScoreColorHelper.getScoreColor(score);
    final String interpretation = scoreInterpretations[category]?[status] ?? '';

    final String valueText =
        value is num ? value.toStringAsFixed(3) : value?.toString() ?? '—';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.poppins(
                  color: const Color(0xFF252525),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  height: 1.25,
                  letterSpacing: -0.2,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              '${score.toStringAsFixed(0)}%',
              style: GoogleFonts.poppins(
                color: band,
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 5),
            Text(
              status,
              style: GoogleFonts.poppins(
                color: band,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          "$marker  ·  $valueText $unit",
          style: GoogleFonts.poppins(
            color: const Color(0xFF535359),
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          interpretation,
          style: GoogleFonts.poppins(
            color: const Color(0xFFA1A1A1),
            fontSize: 11.5,
            fontWeight: FontWeight.w400,
            height: 1.35,
          ),
        ),
      ],
    );
  }

  Widget _divider() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 11),
      child: Divider(height: 1, thickness: 1, color: Color(0xFFE5E7EB)),
    );
  }

  /// Rounds a measured value to at most two decimals and drops trailing
  /// zeros — the raw figures arrive with full float precision ("28.147392"),
  /// which no column needs.
  String _fmtLungValue(dynamic value) {
    final double? parsed = double.tryParse(value?.toString() ?? '');
    if (parsed == null) return value?.toString() ?? '—';
    return parsed
        .toStringAsFixed(2)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }

  Widget _lungStat(String label, dynamic value, String unit) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // scaleDown, never ellipsis: a reading must be shown whole. If the
          // rounded figure still outgrows its quarter of the row, the value
          // and unit shrink together to fit.
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  _fmtLungValue(value),
                  maxLines: 1,
                  softWrap: false,
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF252525),
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    height: 1.15,
                  ),
                ),
                const SizedBox(width: 2),
                Text(
                  unit,
                  style: GoogleFonts.poppins(
                    color: const Color(0xFFA1A1A1),
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 3),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              maxLines: 1,
              softWrap: false,
              style: GoogleFonts.poppins(
                color: const Color(0xFF535359),
                fontSize: 9.5,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _lungDivider() {
    return Container(
      width: 1,
      height: 26,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      color: const Color(0xFFE5E7EB),
    );
  }
}
