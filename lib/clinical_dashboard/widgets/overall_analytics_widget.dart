import 'package:flutter/material.dart';
import 'package:respyr_clinical/clinical_dashboard/widgets/pie_chart_analytics.dart';

import 'dashboard_theme.dart';

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

/// Result distribution for the selected score type.
///
/// This used to be the whole lower half of the dashboard in a single box: a
/// heading, the score dropdown, the chart, and the full test log all inside
/// one border. The card now does one thing. The score choice is owned by the
/// dashboard — the log needs it too, and having each panel hold its own copy
/// meant the two could disagree about what was being shown.
class OverallAnalyticsWidget extends StatelessWidget {
  final Map<String, ScoreTypesForGender> genderDistribution;
  final String scoreType;

  const OverallAnalyticsWidget({
    super.key,
    required this.genderDistribution,
    required this.scoreType,
  });

  static const Map<String, String> scoreTypeMap = {
    'Sugar score': 'dbScore',
    'Liver stress score': 'liverScore',
    'Gut fermentation score': 'gutScorePer',
    'Respiratory score': 'blowScore',
  };

  ScoreBreakdown _combinedBreakdown() {
    ScoreBreakdown total = ScoreBreakdown(good: 0, fair: 0, poor: 0);

    final selectedKey = scoreTypeMap[scoreType];

    genderDistribution.forEach((gender, data) {
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
    final breakdown = _combinedBreakdown();
    final totalTest = breakdown.good + breakdown.fair + breakdown.poor;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DashTheme.gutter),
      child: Container(
        decoration: DashTheme.card,
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 18),
        child: PieChartTestAnalyticsWidget(
          poor: breakdown.poor,
          fair: breakdown.fair,
          good: breakdown.good,
          totalTest: totalTest,
          scoreType: scoreType,
        ),
      ),
    );
  }
}
