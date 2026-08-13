import 'package:flutter/widgets.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

/// Home header: the selected day and how many tests were taken on it,
/// as a row of equal stats.
///
/// Three columns of the same shape, each a value over a small caption. A
/// bordered box holding two loose facts always looked half empty however the
/// contents were arranged; giving them a consistent grid fills the width
/// honestly and leaves room for a fourth stat later.
Widget dashboardHeader({
  required DateTime formattedDate,
  required int totalTestCount,
}) {
  final String dayMonth = DateFormat('d MMM').format(formattedDate);
  final String year = DateFormat('y').format(formattedDate);
  final String dayLabel = DateFormat('EEEE').format(formattedDate);

  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
      ),
      child: Row(
        children: [
          _stat(value: dayMonth, caption: year),
          _divider(),
          _stat(value: dayLabel, caption: "DAY"),
          _divider(),
          _stat(
            // A bare "0" reads as a glitch; a dash reads as "none".
            value: totalTestCount == 0 ? "—" : totalTestCount.toString(),
            caption: "TESTS",
            isMuted: totalTestCount == 0,
            emphasise: totalTestCount > 0,
          ),
        ],
      ),
    ),
  );
}

Widget _stat({
  required String value,
  required String caption,
  bool isMuted = false,
  bool emphasise = false,
}) {
  return Expanded(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.poppins(
            color: isMuted
                ? const Color(0xFFA1A1A1)
                : emphasise
                ? const Color(0xFF308BF9)
                : const Color(0xFF252525),
            // The count is the figure people are actually checking, so it
            // carries a little more weight than the two date columns.
            fontSize: emphasise ? 20 : 16,
            fontWeight: FontWeight.w600,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          caption,
          style: GoogleFonts.poppins(
            color: const Color(0xFF535359),
            fontSize: 10,
            fontWeight: FontWeight.w500,
            letterSpacing: 1.1,
          ),
        ),
      ],
    ),
  );
}

Widget _divider() {
  return Container(
    width: 1,
    height: 34,
    color: const Color(0xFFE5E7EB),
  );
}
