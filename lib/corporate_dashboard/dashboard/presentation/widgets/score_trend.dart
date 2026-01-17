import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../common/get_score_title.dart';
import '../../data/model/corporate_profile_tests_response.dart';
import '../../data/model/score_trend_model.dart';
import 'score_line_chart.dart';

class ScoreTrend extends StatefulWidget {
  final List<CorporateProfileTestItem> latestPerDay;

  const ScoreTrend({super.key, required this.latestPerDay});

  @override
  State<ScoreTrend> createState() => _ScoreTrendState();
}

class _ScoreTrendState extends State<ScoreTrend> {
  // store selection as enum (not string)
  final ValueNotifier<ScoreType> selectedScore =
  ValueNotifier<ScoreType>(ScoreType.sugar);

  final List<ScoreType> items = const [
    ScoreType.sugar,
    ScoreType.respiratory,
    ScoreType.liver,
    ScoreType.gut,
  ];

  @override
  void dispose() {
    selectedScore.dispose();
    super.dispose();
  }

  // dttm format: MM/DD/YYYY HH:mm:ss
  DateTime? _dateFromDttm(String raw) {
    final v = raw.trim();
    if (v.isEmpty) return null;

    try {
      final parts = v.split(' ');
      final d = parts[0].split('/');
      final t = parts[1].split(':');

      return DateTime(
        int.parse(d[2]),
        int.parse(d[0]),
        int.parse(d[1]),
        int.parse(t[0]),
        int.parse(t[1]),
        int.parse(t[2]),
      );
    } catch (_) {
      return null;
    }
  }

  double _parseScore(String s) {
    final v = s.trim();
    if (v.isEmpty || v == '-' || v.toLowerCase() == 'null') return 0;
    return double.tryParse(v) ?? 0;
  }

  // ✅ switch on enum
  double _scoreFromItem(CorporateProfileTestItem item, ScoreType score) {
    switch (score) {
      case ScoreType.sugar:
        return _parseScore(item.dbScore);
      case ScoreType.respiratory:
        return _parseScore(item.blowScore);
      case ScoreType.liver:
        return _parseScore(item.liverScore);
      case ScoreType.gut:
        return _parseScore(item.gutScorePer);
    }
  }

  List<ScoreTrendModel> _buildChartData(ScoreType score) {
    final temp = <({CorporateProfileTestItem item, DateTime dt, double score})>[];

    for (final item in widget.latestPerDay) {
      final dt = _dateFromDttm(item.dttm);
      if (dt == null) continue;

      temp.add((
      item: item,
      dt: dt,
      score: _scoreFromItem(item, score),
      ));
    }

    temp.sort((a, b) => a.dt.compareTo(b.dt));

    final used = temp.take(7).toList();

    debugPrint(
      '[ScoreTrend] Showing first ${used.length} points for "${getScoreTitle(isCorporate: true, score: score)}"',
    );
    for (int i = 0; i < used.length; i++) {
      final u = used[i];
      debugPrint(
        '[$i] dttm=${u.item.dttm} | parsed=${u.dt.toIso8601String()} | score=${u.score}',
      );
    }

    return used
        .map((e) => ScoreTrendModel(date: e.dt, score: e.score))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F7FA),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          children: [
            Text(
              "Score Trend",
              style: GoogleFonts.poppins(
                color: const Color(0xFF252525),
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 24),
            ValueListenableBuilder<ScoreType>(
              valueListenable: selectedScore,
              builder: (context, value, _) {
                return Theme(
                  data: Theme.of(context).copyWith(canvasColor: Colors.white),
                  child: Container(
                    height: 36,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFD9D9D9)),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<ScoreType>(
                        value: value,
                        isDense: true,
                        items: items.map((type) {
                          final title =
                          getScoreTitle(isCorporate: true, score: type);
                          return DropdownMenuItem<ScoreType>(
                            value: type,
                            child: Text(
                              title,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: type == value
                                    ? const Color(0xFF308BF9)
                                    : const Color(0xFF252525),
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (v) {
                          if (v != null) selectedScore.value = v;
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 50),
            ValueListenableBuilder<ScoreType>(
              valueListenable: selectedScore,
              builder: (context, value, _) {
                final chartData = _buildChartData(value);
                if (chartData.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    child: Text(
                      "No trend data available",
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: const Color(0xFF252525),
                      ),
                    ),
                  );
                }
                return ScoreTrendLineChart(data: chartData);
              },
            ),
          ],
        ),
      ),
    );
  }
}
