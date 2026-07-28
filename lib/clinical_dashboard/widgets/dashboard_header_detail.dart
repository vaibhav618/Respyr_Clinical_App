import 'package:flutter/widgets.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

/// Home header card: calendar tile with the selected date + total tests
/// taken that day. White card style shared with the rest of the dashboard.
Widget dashboardHeader({
  required DateTime formattedDate,
  required int totalTestCount,
}) {
  final String day = DateFormat('dd').format(formattedDate);
  final String monthName = DateFormat('MMM').format(formattedDate);

  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
      ),
      child: Row(
        children: [
          // Calendar tile
          Container(
            width: 56,
            decoration: BoxDecoration(
              color: const Color(0xFF308BF9).withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    day,
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF308BF9),
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      height: 1.1,
                    ),
                  ),
                ),
                Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Color(0xFF308BF9),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Center(
                    child: Text(
                      monthName.toUpperCase(),
                      style: GoogleFonts.poppins(
                        color: const Color(0xFFFFFFFF),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(width: 1, height: 56, color: const Color(0xFFE5E7EB)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  totalTestCount.toString(),
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF252525),
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  totalTestCount == 1 ? "test taken" : "tests taken",
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF535359),
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
