import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';

class PieChartTestAnalyticsWidget extends StatelessWidget {
  final int poor;
  final int fair;
  final int good;
  final int totalTest;
  final String date; // Make date dynamic

  const PieChartTestAnalyticsWidget({
    super.key,
    required this.poor,
    required this.fair,
    required this.good,
    required this.totalTest,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 300,
          width: double.infinity,
          child: Stack(
            children: [
              // Center content
              Positioned.fill(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      date,
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF5A5A5A),
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        letterSpacing: -0.24,
                      ),
                    ),
                    const SizedBox(height: 15),
                    Text(
                      totalTest.toString(),
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF5A5A5A),
                        fontSize: 30,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.60,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const SizedBox(
                      width: 79,
                      child: Text(
                        "patients taken test",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF5A5A5A),
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          height: 1.10,
                          letterSpacing: -0.24,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Pie Chart
              Positioned.fill(
                child: PieChart(
                  PieChartData(
                    centerSpaceRadius: 90,
                    sectionsSpace: 0,
                    startDegreeOffset: -90,
                    sections: [
                      PieChartSectionData(
                        value: poor.toDouble(),
                        color: const Color(0xFFEA5455),
                        title: '',
                        radius: 40,
                        badgeWidget: _buildBadge(poor),
                        badgePositionPercentageOffset: 0.5,
                      ),
                      PieChartSectionData(
                        value: fair.toDouble(),
                        color: const Color(0xFFFFC412),
                        title: '',
                        radius: 40,
                        badgeWidget: _buildBadge(fair),
                        badgePositionPercentageOffset: 0.5,
                      ),
                      PieChartSectionData(
                        value: good.toDouble(),
                        color: const Color(0xFF3EAF58),
                        title: '',
                        radius: 40,
                        badgeWidget: _buildBadge(good),
                        badgePositionPercentageOffset: 0.5,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildLegend("Good", const Color(0xFF3EAF58)),
            _buildLegend("Fair", const Color(0xFFFFC412)),
            _buildLegend("Poor", const Color(0xFFEA5455)),
          ],
        )
      ],
    );
  }

  Widget _buildBadge(int value) {
    return Container(
      height: 30,
      width: 30,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          "$value",
          style: GoogleFonts.poppins(
            color: const Color(0xFF535359),
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.30,
          ),
        ),
      ),
    );
  }

  Widget _buildLegend(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 15,
          height: 15,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.poppins(
            color: const Color(0xFF535359),
            fontSize: 12,
            fontWeight: FontWeight.w500,
            letterSpacing: -0.24,
          ),
        ),
      ],
    );
  }
}
