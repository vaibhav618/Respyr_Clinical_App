import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
  final ValueNotifier<String> selectedValue =
  ValueNotifier<String>('Sugar score');

  final List<String> items = const [
    'Sugar score',
    'Respiratory score',
    'Liver score',
    'Gut score',
  ];

  @override
  void dispose() {
    selectedValue.dispose();
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

  double _scoreFromItem(CorporateProfileTestItem item, String selected) {
    switch (selected) {
      case 'Sugar score':
        return _parseScore(item.dbScore);
      case 'Respiratory score':
        return _parseScore(item.blowScore);
      case 'Liver score':
        return _parseScore(item.liverScore);
      case 'Gut score':
        return _parseScore(item.gutScorePer);
      default:
        return _parseScore(item.dbScore);
    }
  }

  /// ✅ Builds chart data AND prints first 7 used points
  List<ScoreTrendModel> _buildChartData(String selected) {
    final temp = <({CorporateProfileTestItem item, DateTime dt, double score})>[];

    for (final item in widget.latestPerDay) {
      final dt = _dateFromDttm(item.dttm);
      if (dt == null) continue;

      temp.add((
      item: item,
      dt: dt,
      score: _scoreFromItem(item, selected),
      ));
    }

    // sort by datetime
    temp.sort((a, b) => a.dt.compareTo(b.dt));

    // take first 7
    final used = temp.take(7).toList();

    // 🔎 DEBUG PRINT (exactly what chart uses)
    debugPrint('📊 [ScoreTrend] Showing first ${used.length} points for "$selected"');
    for (int i = 0; i < used.length; i++) {
      final u = used[i];
      debugPrint(
        '[$i] dttm=${u.item.dttm} | parsed=${u.dt.toIso8601String()} | score=${u.score}',
      );
    }

    // map to chart model
    return used
        .map(
          (e) => ScoreTrendModel(
        date: e.dt,
        score: e.score,
      ),
    )
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
            Row(
              children: [
                Expanded(
                  child: Text(
                    "Score Trend",
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF252525),
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                ValueListenableBuilder<String>(
                  valueListenable: selectedValue,
                  builder: (context, value, _) {
                    return Theme(
                      data: Theme.of(context)
                          .copyWith(canvasColor: Colors.white),
                      child: Container(
                        height: 36,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          border:
                          Border.all(color: const Color(0xFFD9D9D9)),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: value,
                                isDense: true,
                                items: items
                                    .map(
                                      (item) => DropdownMenuItem<String>(
                                    value: item,
                                    child: Text(
                                      item,
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: item == value
                                            ? const Color(0xFF308BF9)
                                            : const Color(0xFF252525),
                                      ),
                                    ),
                                  ),
                                )
                                    .toList(),
                                onChanged: (v) {
                                  if (v != null) selectedValue.value = v;
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),

            ValueListenableBuilder<String>(
              valueListenable: selectedValue,
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
