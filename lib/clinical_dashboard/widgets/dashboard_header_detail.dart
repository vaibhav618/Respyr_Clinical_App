import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'dashboard_theme.dart';

/// Top-of-dashboard summary: how many tests were recorded on the selected day,
/// and how much of the clinic's test allowance is left.
///
/// Replaces two separate blocks — a three-column date/day/count strip at the
/// top and a quota meter buried at the very bottom of the page. The strip
/// spent two of its three columns restating the date already shown in the app
/// bar, and the quota is something you want to see before working through a
/// list of patients, not after scrolling past one.
Widget dashboardHeader({
  required DateTime formattedDate,
  required int totalTestCount,
  required int creditsUsed,
  required int creditsTotal,
  required bool creditsVisible,
}) {
  final DateTime now = DateTime.now();
  final bool isToday = formattedDate.year == now.year &&
      formattedDate.month == now.month &&
      formattedDate.day == now.day;

  final String dateLine = DateFormat('EEEE, d MMMM').format(formattedDate);

  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: DashTheme.gutter),
    child: Container(
      width: double.infinity,
      decoration: DashTheme.card,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                isToday ? "TODAY" : "SELECTED DAY",
                style: GoogleFonts.poppins(
                  color: DashTheme.blue,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  dateLine,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    color: DashTheme.faint,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _testCountLine(totalTestCount),
          if (creditsVisible) ...[
            const SizedBox(height: 16),
            Divider(height: 1, thickness: 1, color: DashTheme.line),
            const SizedBox(height: 14),
            _credits(creditsUsed, creditsTotal),
          ],
        ],
      ),
    ),
  );
}

/// The count leads at display size, with the word beside it — a bare number
/// over a "TESTS" caption made the reader assemble the sentence themselves.
Widget _testCountLine(int count) {
  if (count == 0) {
    return Text(
      "No tests recorded",
      style: GoogleFonts.poppins(
        color: DashTheme.muted,
        fontSize: 19,
        fontWeight: FontWeight.w600,
        height: 1.15,
        letterSpacing: -0.4,
      ),
    );
  }

  return Row(
    crossAxisAlignment: CrossAxisAlignment.baseline,
    textBaseline: TextBaseline.alphabetic,
    children: [
      Text(
        count.toString(),
        style: GoogleFonts.poppins(
          color: DashTheme.blue,
          fontSize: 30,
          fontWeight: FontWeight.w600,
          height: 1,
          letterSpacing: -0.8,
        ),
      ),
      const SizedBox(width: 8),
      Text(
        count == 1 ? "test recorded" : "tests recorded",
        style: GoogleFonts.poppins(
          color: DashTheme.ink,
          fontSize: 15,
          fontWeight: FontWeight.w500,
          letterSpacing: -0.2,
        ),
      ),
    ],
  );
}

Widget _credits(int used, int total) {
  // Guard the divide: the quota endpoint can report 0, and x/0 renders as NaN
  // width, which throws inside the progress indicator.
  final double progress = total > 0 ? (used / total).clamp(0.0, 1.0) : 0.0;
  final bool low = progress >= 0.9;

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Expanded(
            child: Text(
              "Test credits used",
              style: GoogleFonts.poppins(
                color: DashTheme.muted,
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            "$used",
            style: GoogleFonts.poppins(
              color: DashTheme.ink,
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            " / $total",
            style: GoogleFonts.poppins(
              color: DashTheme.faint,
              fontSize: 13.5,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),
      LinearProgressIndicator(
        value: progress,
        minHeight: 6,
        borderRadius: BorderRadius.circular(3),
        color: low ? DashTheme.poor : DashTheme.good,
        backgroundColor: DashTheme.line,
      ),
      if (low) ...[
        const SizedBox(height: 8),
        Text(
          total - used <= 0
              ? "You're out of test credits. Contact support to continue testing."
              : "${total - used} credits left. Contact support to top up.",
          style: GoogleFonts.poppins(
            color: DashTheme.poor,
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
            height: 1.3,
          ),
        ),
      ],
    ],
  );
}
