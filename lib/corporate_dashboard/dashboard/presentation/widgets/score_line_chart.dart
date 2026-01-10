import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/model/score_trend_model.dart';

class ScoreTrendLineChart extends StatelessWidget {
  final List<ScoreTrendModel> data;

  const ScoreTrendLineChart({
    super.key,
    required this.data,
  });

  static const int _window = 7;

  @override
  Widget build(BuildContext context) {
    const lineColor = Colors.blue;

    final List<ScoreTrendModel> recent =
    data.length <= _window ? data : data.sublist(0, _window);

    final labelStyle = GoogleFonts.poppins(
      color: const Color(0xFFA1A1A1),
      fontSize: 10,
      fontWeight: FontWeight.w400,
      height: 1.0,
      letterSpacing: -0.20,
    );

    return SizedBox(
      height: 180,
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: 100,
          minX: 0.0,
          maxX: (_window - 1).toDouble(),

          clipData: const FlClipData.all(),
          borderData: FlBorderData(show: false),

          gridData: FlGridData(
            show: true,
            drawHorizontalLine: false,
            verticalInterval: 1,
            getDrawingVerticalLine: (value) => FlLine(
              color: Colors.grey.shade300,
              strokeWidth: 1,
              dashArray: [6, 4],
            ),
          ),

          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),

            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 20,
                reservedSize: 34,
                getTitlesWidget: (value, _) {
                  if (value % 20 != 0) return const SizedBox.shrink();
                  return Text(value.toInt().toString(), style: labelStyle);
                },
              ),
            ),

            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                reservedSize: 40, // ✅ spacing for X labels
                getTitlesWidget: (x, _) {
                  final index = x.toInt();
                  if (index < 0 || index >= recent.length) {
                    return const SizedBox.shrink();
                  }

                  final d = recent[index].date;
                  final day = d.day.toString().padLeft(2, '0');
                  final month = _monthShort(d.month);

                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(day, style: labelStyle),
                        Text(month, style: labelStyle),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),

          lineBarsData: [
            LineChartBarData(
              spots: _buildSpots(recent),
              isCurved: false,
              color: lineColor,
              barWidth: 2,
              dotData: FlDotData(show: recent.length <= 1),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    lineColor.withOpacity(0.22),
                    lineColor.withOpacity(0.00),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<FlSpot> _buildSpots(List<ScoreTrendModel> recent) {
    return recent.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.score);
    }).toList();
  }

  String _monthShort(int m) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[m - 1];
  }
}
