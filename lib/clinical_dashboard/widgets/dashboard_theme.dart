import 'package:flutter/material.dart';

/// The dashboard's palette and card shape, in one place.
///
/// These values were already the app's de-facto theme, but every widget
/// retyped them as raw hex literals — the same grey appeared as 0xFF535359 in
/// one file and 0xFF5A5A5A two files over, and weekends were once styled with
/// the error red simply because it was the nearest constant to hand. Naming
/// them makes a wrong colour visible at the call site.
class DashTheme {
  const DashTheme._();

  /// Primary. Actions, selected states, and the figure the reader is after.
  static const Color blue = Color(0xFF308BF9);

  /// Body text and headings.
  static const Color ink = Color(0xFF252525);

  /// Secondary text: captions, labels, timestamps.
  static const Color muted = Color(0xFF535359);

  /// Tertiary text and inactive icons.
  static const Color faint = Color(0xFFA1A1A1);

  /// Hairlines, borders and empty track backgrounds.
  static const Color line = Color(0xFFE5E7EB);

  /// The page behind the cards.
  static const Color surface = Color(0xFFF5F7FA);

  static const Color white = Color(0xFFFFFFFF);

  /// Result bands. Shared by the donut, the score dots and the credit meter,
  /// so a "good" reading is the same green everywhere it appears.
  static const Color good = Color(0xFF3EAF58);
  static const Color fair = Color(0xFFFFC412);
  static const Color poor = Color(0xFFEA5455);

  /// Page margin. Every dashboard section aligns to this.
  static const double gutter = 16;

  static const double radius = 14;

  static BoxDecoration get card => BoxDecoration(
        color: white,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: line, width: 1),
      );

  /// Band for a 0-100 score. Below 70 is poor, 70-80 fair, above is good —
  /// the thresholds the test log has always used.
  static Color scoreColor(double score) {
    if (score < 70) return poor;
    if (score < 80) return fair;
    return good;
  }
}
